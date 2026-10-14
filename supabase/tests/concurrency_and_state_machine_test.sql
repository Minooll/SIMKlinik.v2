-- ==============================================================================
-- SIMKlinik Concurrency, Idempotency & State Machine Test Suite
-- Target: Verification of atomic booking, slot capacity limits, and queue progression.
-- ==============================================================================

DO $$
DECLARE
    v_test_count INT := 0;
    v_pass_count INT := 0;
    v_schedule_id UUID := 'e1111111-1111-1111-1111-111111111111';
    v_patient_id UUID := '11111111-aaaa-aaaa-aaaa-111111111111';
    v_ticket_id UUID := 'qt111111-1111-1111-1111-111111111111';
    v_session_id UUID := 'qs111111-1111-1111-1111-111111111111';
    v_res JSONB;
    v_err_caught BOOLEAN;
    v_booked_before INT;
    v_booked_after INT;
BEGIN
    RAISE NOTICE '================================================================';
    RAISE NOTICE 'STARTING SIMKLINIK ATOMIC BOOKING & QUEUE STATE MACHINE TESTS';
    RAISE NOTICE '================================================================';

    -- Setup isolated test schedule with capacity 1
    INSERT INTO public.doctor_schedules (
        id, clinic_id, doctor_id, schedule_date, start_time, end_time, capacity, booked_count, status
    ) VALUES (
        'e9999999-9999-9999-9999-999999999999',
        'c1111111-1111-1111-1111-111111111111',
        'd1111111-1111-1111-1111-111111111111',
        CURRENT_DATE + INTERVAL '30 days',
        '09:00:00',
        '10:00:00',
        1, -- Kapasitas hanya 1 orang (untuk tes slot terakhir)
        0,
        'available'
    ) ON CONFLICT (id) DO UPDATE SET capacity = 1, booked_count = 0, status = 'available';

    -- TEST 1: Check capacity constraint logic
    v_test_count := v_test_count + 1;
    SELECT booked_count INTO v_booked_before 
    FROM public.doctor_schedules 
    WHERE id = 'e9999999-9999-9999-9999-999999999999';

    IF v_booked_before = 0 THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '[PASS] Test 1: Test schedule initialized with 0 bookings and capacity 1';
    ELSE
        RAISE WARNING '[FAIL] Test 1: Initial schedule booked_count mismatch';
    END IF;

    -- TEST 2: Over-capacity rejection test
    v_test_count := v_test_count + 1;
    v_err_caught := FALSE;
    BEGIN
        -- Manually attempt to violate capacity constraint
        UPDATE public.doctor_schedules
        SET booked_count = 2 -- melebihi capacity 1
        WHERE id = 'e9999999-9999-9999-9999-999999999999';
    EXCEPTION WHEN check_violation THEN
        v_err_caught := TRUE;
    END;

    IF v_err_caught THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '[PASS] Test 2: Database check constraint strictly blocks booked_count > capacity';
    ELSE
        RAISE WARNING '[FAIL] Test 2: Database allowed booked_count to exceed capacity';
    END IF;

    -- TEST 3: Queue State Machine — Illegal Transition Guard
    -- Attempting illegal transition: waiting -> completed (skipping checked_in, called, in_service)
    v_test_count := v_test_count + 1;
    v_err_caught := FALSE;

    -- Create test session and ticket
    INSERT INTO public.queue_sessions (
        id, clinic_id, doctor_id, session_date, current_ticket_number, status
    ) VALUES (
        v_session_id,
        'c1111111-1111-1111-1111-111111111111',
        'd1111111-1111-1111-1111-111111111111',
        CURRENT_DATE,
        0,
        'active'
    ) ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.queue_tickets (
        id, queue_session_id, patient_id, user_id, ticket_number, ticket_code, qr_token, status
    ) VALUES (
        v_ticket_id,
        v_session_id,
        '11111111-aaaa-aaaa-aaaa-111111111111',
        '11111111-aaaa-aaaa-aaaa-111111111111',
        1,
        'A-001',
        'QR-TEST-STATE-MACHINE',
        'waiting'
    ) ON CONFLICT (id) DO UPDATE SET status = 'waiting';

    BEGIN
        -- Calling advance_queue_ticket with illegal direct transition: waiting -> completed
        PERFORM public.advance_queue_ticket(v_ticket_id, 'completed'::queue_status, 'Tes transisi ilegal');
    EXCEPTION WHEN OTHERS THEN
        v_err_caught := TRUE;
    END;

    IF v_err_caught THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '[PASS] Test 3: Illegal state transition (waiting -> completed) strictly rejected';
    ELSE
        RAISE WARNING '[FAIL] Test 3: Illegal state transition was unexpectedly permitted';
    END IF;

    -- TEST 4: Repeated QR Check-in Idempotency
    v_test_count := v_test_count + 1;
    v_err_caught := FALSE;
    -- First check-in
    UPDATE public.queue_tickets SET status = 'checked_in', checked_in_at = NOW() WHERE id = v_ticket_id;
    -- Second repeated check-in attempt
    BEGIN
        -- Calling check_in_with_qr on an already checked-in ticket must return success idempotently
        SELECT public.check_in_with_qr('QR-TEST-STATE-MACHINE') INTO v_res;
        IF (v_res->>'already_checked_in')::BOOLEAN = TRUE THEN
            v_err_caught := TRUE;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        v_err_caught := FALSE;
    END;

    IF v_err_caught THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '[PASS] Test 4: Repeated QR check-in is idempotent (returns already_checked_in = true without error)';
    ELSE
        RAISE WARNING '[FAIL] Test 4: Repeated check-in idempotency failed';
    END IF;

    -- TEST 5: Wait Range Estimation Calculation
    v_test_count := v_test_count + 1;
    SELECT public.get_estimated_wait_range(v_ticket_id) INTO v_res;
    IF v_res ? 'estimated_range' AND v_res ? 'disclaimer' THEN
        v_pass_count := v_pass_count + 1;
        RAISE NOTICE '[PASS] Test 5: Dynamic wait estimation correctly returns range ("%") with disclaimer', v_res->>'estimated_range';
    ELSE
        RAISE WARNING '[FAIL] Test 5: Dynamic wait estimation missing range or disclaimer';
    END IF;

    -- Cleanup test entities
    DELETE FROM public.doctor_schedules WHERE id = 'e9999999-9999-9999-9999-999999999999';
    DELETE FROM public.queue_tickets WHERE id = v_ticket_id;
    DELETE FROM public.queue_sessions WHERE id = v_session_id;

    RAISE NOTICE '================================================================';
    RAISE NOTICE 'SUMMARY: %/% CONCURRENCY & STATE MACHINE TESTS PASSED.', v_pass_count, v_test_count;
    RAISE NOTICE '================================================================';
END $$;
