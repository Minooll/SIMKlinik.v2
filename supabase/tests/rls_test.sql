-- ==============================================================================
-- SIMKlinik RLS & Authorization Test Suite (Positif & Negatif Scenarios)
-- Execute in PostgreSQL transaction block for automated verification
-- ==============================================================================

DO $$
DECLARE
    v_user_a UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_user_b UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    v_staff_id UUID := 'cccccccc-cccc-cccc-cccc-cccccccccccc';
    v_patient_a_id UUID := '11111111-aaaa-aaaa-aaaa-111111111111';
    v_patient_b_id UUID := '22222222-bbbb-bbbb-bbbb-222222222222';
    v_test_count INT := 0;
    v_success_count INT := 0;
    v_row_count INT;
    v_err_caught BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'STARTING SIMKLINIK RLS POSITIVE & NEGATIVE TEST SUITE';
    RAISE NOTICE '=====================================================';

    -- Setup mock users in auth.users if testing in local test database
    -- Note: When running against active Supabase, users are created via Auth API.
    
    -- TEST 1: Public Read for Clinics & Specialties
    v_test_count := v_test_count + 1;
    SELECT COUNT(*) INTO v_row_count FROM public.clinics WHERE is_active = TRUE;
    IF v_row_count >= 1 THEN
        v_success_count := v_success_count + 1;
        RAISE NOTICE '[PASS] Test 1: Public read on active clinics successful (Found: %)', v_row_count;
    ELSE
        RAISE WARNING '[FAIL] Test 1: Public read on active clinics failed';
    END IF;

    -- TEST 2: Public Read for Specialties
    v_test_count := v_test_count + 1;
    SELECT COUNT(*) INTO v_row_count FROM public.specialties;
    IF v_row_count >= 1 THEN
        v_success_count := v_success_count + 1;
        RAISE NOTICE '[PASS] Test 2: Public read on specialties successful (Found: %)', v_row_count;
    ELSE
        RAISE WARNING '[FAIL] Test 2: Public read on specialties failed';
    END IF;

    -- TEST 3: Doctor Schedule Time Constraint Check
    v_test_count := v_test_count + 1;
    v_err_caught := FALSE;
    BEGIN
        INSERT INTO public.doctor_schedules (
            clinic_id, doctor_id, schedule_date, start_time, end_time, capacity
        ) VALUES (
            'c1111111-1111-1111-1111-111111111111',
            'd1111111-1111-1111-1111-111111111111',
            CURRENT_DATE + INTERVAL '10 days',
            '14:00:00',
            '12:00:00', -- Invalid: end_time before start_time
            10
        );
    EXCEPTION WHEN check_violation THEN
        v_err_caught := TRUE;
    END;

    IF v_err_caught THEN
        v_success_count := v_success_count + 1;
        RAISE NOTICE '[PASS] Test 3: Constraint check_schedule_time properly rejects invalid start/end time';
    ELSE
        RAISE WARNING '[FAIL] Test 3: Invalid schedule time was not rejected by constraint';
    END IF;

    -- TEST 4: Schedule Overbooking Constraint (booked_count <= capacity)
    v_test_count := v_test_count + 1;
    v_err_caught := FALSE;
    BEGIN
        INSERT INTO public.doctor_schedules (
            clinic_id, doctor_id, schedule_date, start_time, end_time, capacity, booked_count
        ) VALUES (
            'c1111111-1111-1111-1111-111111111111',
            'd1111111-1111-1111-1111-111111111111',
            CURRENT_DATE + INTERVAL '11 days',
            '10:00:00',
            '12:00:00',
            5,
            6 -- Invalid: booked_count > capacity
        );
    EXCEPTION WHEN check_violation THEN
        v_err_caught := TRUE;
    END;

    IF v_err_caught THEN
        v_success_count := v_success_count + 1;
        RAISE NOTICE '[PASS] Test 4: Constraint capacity limit properly rejects overbooked counts';
    ELSE
        RAISE WARNING '[FAIL] Test 4: Overbooking count was not rejected by constraint';
    END IF;

    -- TEST 5: Negative Test: Atomic Booking Requires Authenticated User
    v_test_count := v_test_count + 1;
    v_err_caught := FALSE;
    BEGIN
        -- Calling book_appointment_atomic with no active auth.uid() context
        PERFORM public.book_appointment_atomic(
            'e1111111-1111-1111-1111-111111111111',
            v_patient_a_id,
            'Catatan tes'
        );
    EXCEPTION WHEN OTHERS THEN
        v_err_caught := TRUE;
    END;

    IF v_err_caught THEN
        v_success_count := v_success_count + 1;
        RAISE NOTICE '[PASS] Test 5: Unauthenticated call to book_appointment_atomic correctly rejected';
    ELSE
        RAISE WARNING '[FAIL] Test 5: Unauthenticated booking call was unexpectedly allowed';
    END IF;

    -- TEST 6: Negative Test: Invalid QR Token Check-In
    v_test_count := v_test_count + 1;
    v_err_caught := FALSE;
    BEGIN
        PERFORM public.check_in_with_qr('TOKEN-PALSU-12345');
    EXCEPTION WHEN OTHERS THEN
        v_err_caught := TRUE;
    END;

    IF v_err_caught THEN
        v_success_count := v_success_count + 1;
        RAISE NOTICE '[PASS] Test 6: Invalid QR token properly rejected during check-in';
    ELSE
        RAISE WARNING '[FAIL] Test 6: Invalid QR token was not rejected';
    END IF;

    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'TEST SUITE SUMMARY: %/% tests passed successfully.', v_success_count, v_test_count;
    RAISE NOTICE '=====================================================';
END $$;
