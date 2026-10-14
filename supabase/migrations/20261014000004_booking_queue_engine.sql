-- ==============================================================================
-- SIMKlinik Booking & Queue Engine Migration
-- Version: 20261014000004
-- Description: Slot rollback cancellation, dynamic wait time estimation, and realtime publication.
-- ==============================================================================

-- 1. Atomic Cancellation & Capacity Rollback Function
CREATE OR REPLACE FUNCTION public.cancel_appointment_atomic(
    p_appointment_id UUID,
    p_reason TEXT DEFAULT 'Dibatalkan oleh pasien'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_apt RECORD;
    v_schedule RECORD;
    v_new_booked INT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Pengguna belum terautentikasi (Authentication required).';
    END IF;

    -- Fetch and lock appointment
    SELECT * INTO v_apt
    FROM public.appointments
    WHERE id = p_appointment_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Data reservasi (appointment) tidak ditemukan.';
    END IF;

    -- Validate ownership or staff/admin permission
    IF v_apt.user_id <> v_user_id AND NOT public.is_staff_or_admin() THEN
        RAISE EXCEPTION 'Akses ditolak: Anda tidak memiliki wewenang untuk membatalkan booking ini.';
    END IF;

    -- Only confirmed or pending appointments can be cancelled
    IF v_apt.status NOT IN ('pending', 'confirmed') THEN
        RAISE EXCEPTION 'Reservasi tidak dapat dibatalkan karena status saat ini: %', v_apt.status;
    END IF;

    -- Lock schedule to rollback capacity
    SELECT * INTO v_schedule
    FROM public.doctor_schedules
    WHERE id = v_apt.schedule_id
    FOR UPDATE;

    IF FOUND THEN
        v_new_booked := GREATEST(0, v_schedule.booked_count - 1);
        UPDATE public.doctor_schedules
        SET booked_count = v_new_booked,
            status = 'available'::schedule_status
        WHERE id = v_schedule.id;
    END IF;

    -- Update appointment status
    UPDATE public.appointments
    SET status = 'cancelled',
        cancelled_at = TIMEZONE('utc', NOW()),
        cancellation_reason = p_reason,
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = p_appointment_id;

    -- Cancel associated queue ticket if exists
    UPDATE public.queue_tickets
    SET status = 'cancelled'
    WHERE appointment_id = p_appointment_id AND status IN ('waiting', 'checked_in');

    -- Log queue event
    INSERT INTO public.queue_events (
        queue_ticket_id,
        actor_id,
        previous_status,
        new_status,
        reason
    )
    SELECT id, v_user_id, status, 'cancelled', p_reason
    FROM public.queue_tickets
    WHERE appointment_id = p_appointment_id;

    -- Log audit trail
    INSERT INTO public.audit_logs (
        actor_id,
        action,
        resource_type,
        resource_id,
        payload
    ) VALUES (
        v_user_id,
        'CANCEL_APPOINTMENT_ATOMIC',
        'appointment',
        p_appointment_id::TEXT,
        jsonb_build_object(
            'reason', p_reason,
            'rolled_back_schedule_id', v_apt.schedule_id,
            'new_booked_count', v_new_booked
        )
    );

    RETURN jsonb_build_object(
        'success', TRUE,
        'appointment_id', p_appointment_id,
        'status', 'cancelled',
        'message', 'Reservasi berhasil dibatalkan dan kuota jadwal telah dipulihkan.'
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 2. Dynamic Wait Estimation Function (Range Estimation & Disclaimer)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_estimated_wait_range(
    p_ticket_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_ticket RECORD;
    v_session RECORD;
    v_people_ahead INT;
    v_avg_duration_minutes INT := 15; -- Rata-rata durasi konsultasi per pasien
    v_min_estimate INT;
    v_max_estimate INT;
BEGIN
    SELECT * INTO v_ticket
    FROM public.queue_tickets
    WHERE id = p_ticket_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tiket antrean tidak ditemukan.';
    END IF;

    SELECT * INTO v_session
    FROM public.queue_sessions
    WHERE id = v_ticket.queue_session_id;

    -- Hitung jumlah antrean aktif yang berada di depan pasien ini
    SELECT COUNT(*) INTO v_people_ahead
    FROM public.queue_tickets
    WHERE queue_session_id = v_ticket.queue_session_id
      AND ticket_number < v_ticket.ticket_number
      AND status IN ('waiting', 'checked_in', 'called');

    IF v_ticket.status = 'completed' THEN
        RETURN jsonb_build_object(
            'status', 'completed',
            'people_ahead', 0,
            'estimated_range', 'Pelayanan telah selesai',
            'disclaimer', 'Pelayanan kunjungan dokter telah selesai.'
        );
    END IF;

    IF v_ticket.status = 'in_service' THEN
        RETURN jsonb_build_object(
            'status', 'in_service',
            'people_ahead', 0,
            'estimated_range', 'Sedang dalam ruang periksa',
            'disclaimer', 'Pasien sedang mendapatkan pelayanan dokter.'
        );
    END IF;

    -- Hitung estimasi rentang dinamis
    v_min_estimate := GREATEST(5, v_people_ahead * (v_avg_duration_minutes - 5));
    v_max_estimate := GREATEST(15, (v_people_ahead + 1) * (v_avg_duration_minutes + 5));

    RETURN jsonb_build_object(
        'status', v_ticket.status,
        'people_ahead', v_people_ahead,
        'min_minutes', v_min_estimate,
        'max_minutes', v_max_estimate,
        'estimated_range', v_min_estimate || ' - ' || v_max_estimate || ' menit',
        'updated_at', TIMEZONE('utc', NOW()),
        'disclaimer', 'Waktu merupakan perkiraan dinamis berdasarkan riwayat pelayanan, bukan kepastian waktu panggilan.'
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 3. Supabase Realtime Publication Setup (Safe Configuration)
-- ------------------------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.queue_tickets;
        ALTER PUBLICATION supabase_realtime ADD TABLE public.queue_sessions;
    END IF;
EXCEPTION WHEN OTHERS THEN
    -- Ignore if already added or publication does not exist in local standalone
    NULL;
END $$;
