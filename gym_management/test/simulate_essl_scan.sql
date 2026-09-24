-- Simulation Script: eSSL Scan Mocking
-- Usage: Run this in Supabase SQL Editor to simulate a finger scan

DO $$
DECLARE
    v_test_user_id UUID;
    v_device_id UUID;
    v_device_user_id INT := 999; -- Mock Biometric ID
BEGIN
    -- 1. Get a test user (Member)
    SELECT id INTO v_test_user_id FROM public.users WHERE role = 'member' LIMIT 1;
    
    IF v_test_user_id IS NULL THEN
        RAISE NOTICE 'No member found in users table. Please create one first.';
        RETURN;
    END IF;

    -- 2. Ensure device exists
    INSERT INTO public.essl_devices (name, ip_address, is_active)
    VALUES ('Mock Entrance Device', '127.0.0.1', TRUE)
    ON CONFLICT DO NOTHING
    RETURNING id INTO v_device_id;
    
    IF v_device_id IS NULL THEN
        SELECT id INTO v_device_id FROM public.essl_devices WHERE ip_address = '127.0.0.1' LIMIT 1;
    END IF;

    -- 3. Map user to Biometric ID
    INSERT INTO public.essl_user_mapping (user_id, device_user_id)
    VALUES (v_test_user_id, v_device_user_id)
    ON CONFLICT (user_id, device_user_id) DO NOTHING;

    -- 4. SIMULATE SCAN
    -- This insert will trigger process_essl_log_entry()
    INSERT INTO public.essl_logs (device_id, device_user_id, timestamp, status)
    VALUES (v_device_id, v_device_user_id, NOW(), 'CheckIn');

    RAISE NOTICE 'Simulated scan for user % (Biometric ID: %)', v_test_user_id, v_device_user_id;
END $$;
