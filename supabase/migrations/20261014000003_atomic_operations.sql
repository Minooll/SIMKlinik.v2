-- ==============================================================================
-- SIMKlinik Atomic Operations & Triggers Migration
-- Version: 20261014000003
-- Description: Atomic booking RPC, QR check-in, queue status machine, and signup trigger.
-- ==============================================================================

-- 1. Trigger for New User Signup (Automatic Profile and Patient Role Creation)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
BEGIN
    -- Create profile
    INSERT INTO public.profiles (id, full_name, phone)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Pengguna Baru'),
        NEW.raw_user_meta_data->>'phone'
    )
    ON CONFLICT (id) DO NOTHING;

    -- Assign default patient role
    INSERT INTO public.user_roles (user_id, role)
    VALUES (NEW.id, 'patient')
    ON CONFLICT (user_id, role) DO NOTHING;

    RETURN NEW;
END;
$$;

-- Bind trigger to auth.users if trigger does not already exist
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ------------------------------------------------------------------------------
-- 2. Atomic Appointment Booking RPC (with Row-Level Locking and Idempotency)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.book_appointment_atomic(
    p_schedule_id UUID,
    p_patient_id UUID,
    p_notes TEXT DEFAULT NULL,
    p_idempotency_key TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_schedule RECORD;
    v_existing_apt RECORD;
    v_new_apt_id UUID;
    v_booking_ref TEXT;
    v_new_booked INT;
    v_session_id UUID;
    v_ticket_num INT;
    v_ticket_code TEXT;
    v_qr_token TEXT;
    v_new_ticket_id UUID;
BEGIN
    -- Verify authentication
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Pengguna belum terautentikasi (Authentication required).';
    END IF;

    -- Verify patient ownership or staff privilege
    IF NOT EXISTS (
        SELECT 1 FROM public.patient_profiles 
        WHERE id = p_patient_id 
          AND (user_id = v_user_id OR public.is_staff_or_admin())
    ) THEN
        RAISE EXCEPTION 'Profil pasien tidak valid atau bukan milik pengguna ini.';
    END IF;

    -- Idempotency check: if request was already processed with same key, return it
    IF p_idempotency_key IS NOT NULL AND p_idempotency_key <> '' THEN
        SELECT a.id, a.booking_reference, a.status, qt.ticket_code, qt.qr_token
        INTO v_existing_apt
        FROM public.appointments a
        LEFT JOIN public.queue_tickets qt ON qt.appointment_id = a.id
        WHERE a.idempotency_key = p_idempotency_key;

        IF FOUND THEN
            RETURN jsonb_build_object(
                'success', TRUE,
                'is_idempotent_replay', TRUE,
                'appointment_id', v_existing_apt.id,
                'booking_reference', v_existing_apt.booking_reference,
                'status', v_existing_apt.status,
                'ticket_code', v_existing_apt.ticket_code,
                'qr_token', v_existing_apt.qr_token,
                'message', 'Permintaan booking sudah pernah diproses (Idempotent replay).'
            );
        END IF;
    END IF;

    -- Lock schedule row FOR UPDATE to prevent race conditions & overbooking
    SELECT * INTO v_schedule
    FROM public.doctor_schedules
    WHERE id = p_schedule_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Jadwal dokter tidak ditemukan.';
    END IF;

    IF v_schedule.status <> 'available' THEN
        RAISE EXCEPTION 'Jadwal dokter saat ini tidak tersedia untuk booking.';
    END IF;

    IF v_schedule.booked_count >= v_schedule.capacity THEN
        -- Mark as full to maintain status integrity
        UPDATE public.doctor_schedules 
        SET status = 'full' 
        WHERE id = p_schedule_id;
        
        RAISE EXCEPTION 'Kapasitas slot untuk jadwal dokter ini sudah penuh.';
    END IF;

    -- Check if patient already has an active appointment for this schedule
    IF EXISTS (
        SELECT 1 FROM public.appointments
        WHERE patient_id = p_patient_id
          AND schedule_id = p_schedule_id
          AND status IN ('pending', 'confirmed')
    ) THEN
        RAISE EXCEPTION 'Pasien ini sudah memiliki reservasi aktif pada jadwal tersebut.';
    END IF;

    -- Increment capacity counter
    v_new_booked := v_schedule.booked_count + 1;
    UPDATE public.doctor_schedules
    SET booked_count = v_new_booked,
        status = CASE WHEN v_new_booked >= capacity THEN 'full'::schedule_status ELSE 'available'::schedule_status END
    WHERE id = p_schedule_id;

    -- Generate unique booking reference (e.g. APT-YYYYMMDD-XXXX)
    v_booking_ref := 'APT-' || TO_CHAR(v_schedule.schedule_date, 'YYYYMMDD') || '-' || UPPER(SUBSTRING(gen_random_uuid()::TEXT, 1, 4));

    -- Insert appointment
    INSERT INTO public.appointments (
        booking_reference,
        patient_id,
        user_id,
        schedule_id,
        status,
        notes,
        idempotency_key
    ) VALUES (
        v_booking_ref,
        p_patient_id,
        v_user_id,
        p_schedule_id,
        'confirmed',
        p_notes,
        p_idempotency_key
    )
    RETURNING id INTO v_new_apt_id;

    -- Ensure queue session exists for this doctor & date
    SELECT id INTO v_session_id
    FROM public.queue_sessions
    WHERE schedule_id = p_schedule_id;

    IF NOT FOUND THEN
        INSERT INTO public.queue_sessions (
            clinic_id,
            doctor_id,
            schedule_id,
            session_date,
            current_ticket_number,
            status
        ) VALUES (
            v_schedule.clinic_id,
            v_schedule.doctor_id,
            p_schedule_id,
            v_schedule.schedule_date,
            0,
            'active'
        )
        RETURNING id INTO v_session_id;
    END IF;

    -- Allocate next ticket number atomically
    UPDATE public.queue_sessions
    SET current_ticket_number = current_ticket_number + 1
    WHERE id = v_session_id
    RETURNING current_ticket_number INTO v_ticket_num;

    v_ticket_code := 'A-' || LPAD(v_ticket_num::TEXT, 3, '0');
    v_qr_token := 'QR-' || encode(gen_random_bytes(16), 'hex');

    -- Insert queue ticket
    INSERT INTO public.queue_tickets (
        queue_session_id,
        appointment_id,
        patient_id,
        user_id,
        ticket_number,
        ticket_code,
        qr_token,
        status,
        estimated_wait_minutes
    ) VALUES (
        v_session_id,
        v_new_apt_id,
        p_patient_id,
        v_user_id,
        v_ticket_num,
        v_ticket_code,
        v_qr_token,
        'waiting',
        (v_ticket_num - 1) * 15 -- Estimasi dasar 15 menit per antrean
    )
    RETURNING id INTO v_new_ticket_id;

    -- Initial queue event
    INSERT INTO public.queue_events (
        queue_ticket_id,
        actor_id,
        previous_status,
        new_status,
        reason
    ) VALUES (
        v_new_ticket_id,
        v_user_id,
        NULL,
        'waiting',
        'Tiket antrean dibuat bersamaan dengan booking'
    );

    -- Log to audit trail
    INSERT INTO public.audit_logs (
        actor_id,
        action,
        resource_type,
        resource_id,
        payload
    ) VALUES (
        v_user_id,
        'BOOK_APPOINTMENT_ATOMIC',
        'appointment',
        v_new_apt_id::TEXT,
        jsonb_build_object(
            'booking_reference', v_booking_ref,
            'schedule_id', p_schedule_id,
            'patient_id', p_patient_id,
            'ticket_code', v_ticket_code
        )
    );

    RETURN jsonb_build_object(
        'success', TRUE,
        'appointment_id', v_new_apt_id,
        'booking_reference', v_booking_ref,
        'schedule_id', p_schedule_id,
        'ticket_code', v_ticket_code,
        'ticket_number', v_ticket_num,
        'qr_token', v_qr_token,
        'status', 'confirmed',
        'message', 'Booking berhasil dikonfirmasi dan nomor antrean telah diterbitkan.'
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 3. Atomic QR Check-In Function
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.check_in_with_qr(
    p_qr_token TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_actor_id UUID;
    v_ticket RECORD;
BEGIN
    v_actor_id := auth.uid();
    IF v_actor_id IS NULL THEN
        RAISE EXCEPTION 'Autentikasi diperlukan untuk check-in.';
    END IF;

    -- Fetch and lock ticket
    SELECT qt.*, qs.clinic_id
    INTO v_ticket
    FROM public.queue_tickets qt
    JOIN public.queue_sessions qs ON qs.id = qt.queue_session_id
    WHERE qt.qr_token = p_qr_token
    FOR UPDATE OF qt;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'QR token tidak valid atau tiket tidak ditemukan.';
    END IF;

    -- Idempotent check-in
    IF v_ticket.status = 'checked_in' THEN
        RETURN jsonb_build_object(
            'success', TRUE,
            'already_checked_in', TRUE,
            'ticket_id', v_ticket.id,
            'ticket_code', v_ticket.ticket_code,
            'status', v_ticket.status,
            'message', 'Pasien sudah melakukan check-in sebelumnya.'
        );
    END IF;

    IF v_ticket.status <> 'waiting' THEN
        RAISE EXCEPTION 'Tiket tidak dapat di-check-in karena status saat ini: %', v_ticket.status;
    END IF;

    -- Update ticket status
    UPDATE public.queue_tickets
    SET status = 'checked_in',
        checked_in_at = TIMEZONE('utc', NOW())
    WHERE id = v_ticket.id;

    -- Record event
    INSERT INTO public.queue_events (
        queue_ticket_id,
        actor_id,
        previous_status,
        new_status,
        reason
    ) VALUES (
        v_ticket.id,
        v_actor_id,
        'waiting',
        'checked_in',
        'Check-in berhasil tervalidasi via QR'
    );

    -- Audit log
    INSERT INTO public.audit_logs (
        actor_id,
        action,
        resource_type,
        resource_id,
        payload
    ) VALUES (
        v_actor_id,
        'CHECK_IN_QR',
        'queue_ticket',
        v_ticket.id::TEXT,
        jsonb_build_object('ticket_code', v_ticket.ticket_code, 'qr_token', p_qr_token)
    );

    RETURN jsonb_build_object(
        'success', TRUE,
        'ticket_id', v_ticket.id,
        'ticket_code', v_ticket.ticket_code,
        'status', 'checked_in',
        'checked_in_at', TIMEZONE('utc', NOW()),
        'message', 'Check-in berhasil. Pasien terdaftar dalam antrean aktif.'
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 4. State Machine for Queue Progress (Call, In-Service, Complete, Skip)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.advance_queue_ticket(
    p_ticket_id UUID,
    p_new_status queue_status,
    p_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_actor_id UUID;
    v_ticket RECORD;
BEGIN
    v_actor_id := auth.uid();
    IF v_actor_id IS NULL THEN
        RAISE EXCEPTION 'Autentikasi diperlukan.';
    END IF;

    -- Must be doctor, staff, or admin
    IF NOT (public.is_doctor() OR public.is_staff_or_admin()) THEN
        RAISE EXCEPTION 'Akses ditolak: hanya petugas klinik atau dokter yang dapat memproses antrean.';
    END IF;

    SELECT * INTO v_ticket
    FROM public.queue_tickets
    WHERE id = p_ticket_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tiket antrean tidak ditemukan.';
    END IF;

    -- Validate state transitions
    IF v_ticket.status = p_new_status THEN
        RETURN jsonb_build_object(
            'success', TRUE,
            'ticket_id', v_ticket.id,
            'status', v_ticket.status,
            'message', 'Status tiket sudah sesuai.'
        );
    END IF;

    -- Validate transition rules
    IF p_new_status = 'called' AND v_ticket.status NOT IN ('checked_in', 'waiting') THEN
        RAISE EXCEPTION 'Tiket hanya dapat dipanggil jika sudah checked_in atau waiting.';
    ELSIF p_new_status = 'in_service' AND v_ticket.status <> 'called' THEN
        RAISE EXCEPTION 'Pelayanan hanya dapat dimulai setelah tiket dipanggil (called).';
    ELSIF p_new_status = 'completed' AND v_ticket.status <> 'in_service' THEN
        RAISE EXCEPTION 'Hanya tiket dalam pelayanan (in_service) yang dapat diselesaikan.';
    END IF;

    -- Update ticket timestamp accordingly
    UPDATE public.queue_tickets
    SET status = p_new_status,
        called_at = CASE WHEN p_new_status = 'called' THEN TIMEZONE('utc', NOW()) ELSE called_at END,
        started_at = CASE WHEN p_new_status = 'in_service' THEN TIMEZONE('utc', NOW()) ELSE started_at END,
        completed_at = CASE WHEN p_new_status = 'completed' THEN TIMEZONE('utc', NOW()) ELSE completed_at END
    WHERE id = p_ticket_id;

    -- If completed, mark corresponding appointment completed as well
    IF p_new_status = 'completed' AND v_ticket.appointment_id IS NOT NULL THEN
        UPDATE public.appointments
        SET status = 'completed',
            updated_at = TIMEZONE('utc', NOW())
        WHERE id = v_ticket.appointment_id;
    END IF;

    -- Record event
    INSERT INTO public.queue_events (
        queue_ticket_id,
        actor_id,
        previous_status,
        new_status,
        reason
    ) VALUES (
        p_ticket_id,
        v_actor_id,
        v_ticket.status,
        p_new_status,
        p_reason
    );

    -- Audit log
    INSERT INTO public.audit_logs (
        actor_id,
        action,
        resource_type,
        resource_id,
        payload
    ) VALUES (
        v_actor_id,
        'ADVANCE_QUEUE_TICKET',
        'queue_ticket',
        p_ticket_id::TEXT,
        jsonb_build_object(
            'previous_status', v_ticket.status,
            'new_status', p_new_status,
            'reason', p_reason
        )
    );

    RETURN jsonb_build_object(
        'success', TRUE,
        'ticket_id', p_ticket_id,
        'ticket_code', v_ticket.ticket_code,
        'previous_status', v_ticket.status,
        'new_status', p_new_status,
        'message', 'Status antrean berhasil diperbarui.'
    );
END;
$$;
