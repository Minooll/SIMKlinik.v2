-- ==============================================================================
-- SIMKlinik Seed Data (Dummy Data for Development & Testing Only)
-- Strict Rule: NO real patient data, NO secrets or live tokens.
-- ==============================================================================

-- 1. Seed Clinics
INSERT INTO public.clinics (id, name, code, address, phone, timezone, is_active)
VALUES 
    ('c1111111-1111-1111-1111-111111111111', 'Klinik Pratama Sehat Harmoni', 'KPSH-01', 'Jl. Kesehatan Medika No. 45, Jakarta Selatan', '021-78901234', 'Asia/Jakarta', TRUE),
    ('c2222222-2222-2222-2222-222222222222', 'Klinik Medika Pratama Bintaro', 'KMPB-02', 'Jl. Boulevard Bintaro Sektor 7 No. 12, Tangerang Selatan', '021-74567890', 'Asia/Jakarta', TRUE)
ON CONFLICT (id) DO NOTHING;

-- 2. Seed Specialties
INSERT INTO public.specialties (id, name, description, icon_name)
VALUES 
    ('s1111111-1111-1111-1111-111111111111', 'Poli Umum', 'Layanan pemeriksaan kesehatan umum, pencegahan penyakit, dan rujukan.', 'medical_services'),
    ('s2222222-2222-2222-2222-222222222222', 'Poli Gigi & Mulut', 'Pemeriksaan gigi, scaling, penambalan, dan perawatan kesehatan mulut.', 'dentistry'),
    ('s3333333-3333-3333-3333-333333333333', 'Poli Anak (Pediatri)', 'Pelayanan kesehatan anak, imunisasi, dan pemantauan tumbuh kembang balita.', 'child_care'),
    ('s4444444-4444-4444-4444-444444444444', 'Poli Penyakit Dalam', 'Diagnosis dan tatalaksana komprehensif penyakit organ dalam dewasa.', 'favorite')
ON CONFLICT (id) DO NOTHING;

-- 3. Seed Doctors
INSERT INTO public.doctors (id, specialty_id, clinic_id, full_name, sip_number, bio, is_active)
VALUES 
    (
        'd1111111-1111-1111-1111-111111111111',
        's1111111-1111-1111-1111-111111111111',
        'c1111111-1111-1111-1111-111111111111',
        'dr. Budi Santoso',
        'SIP: 503/4321/IDI-JAKSEL/2022',
        'Dokter umum dengan pengalaman lebih dari 8 tahun dalam pelayanan rawat jalan primer.',
        TRUE
    ),
    (
        'd2222222-2222-2222-2222-222222222222',
        's2222222-2222-2222-2222-222222222222',
        'c1111111-1111-1111-1111-111111111111',
        'drg. Siti Rahmawati',
        'SIP: 503/8765/PDGI-JAKSEL/2023',
        'Dokter gigi lulusan Universitas Indonesia dengan fokus restorasi estetis dan preventif.',
        TRUE
    ),
    (
        'd3333333-3333-3333-3333-333333333333',
        's3333333-3333-3333-3333-333333333333',
        'c1111111-1111-1111-1111-111111111111',
        'dr. Maya Kartika, Sp.A',
        'SIP: 503/1122/IDAI-JAKSEL/2021',
        'Dokter spesialis anak yang berdedikasi mendampingi kesehatan dan nutrisi tumbuh kembang si kecil.',
        TRUE
    ),
    (
        'd4444444-4444-4444-4444-444444444444',
        's4444444-4444-4444-4444-444444444444',
        'c1111111-1111-1111-1111-111111111111',
        'dr. Andi Wijaya, Sp.PD',
        'SIP: 503/9900/PAPDI-JAKSEL/2020',
        'Dokter spesialis penyakit dalam dengan keahlian dalam penanganan diabetes dan hipertensi.',
        TRUE
    )
ON CONFLICT (id) DO NOTHING;

-- 4. Seed Doctor Schedules (Upcoming dates for simulation)
INSERT INTO public.doctor_schedules (id, clinic_id, doctor_id, schedule_date, start_time, end_time, capacity, booked_count, status)
VALUES 
    -- Jadwal dr. Budi Santoso (Umum)
    ('e1111111-1111-1111-1111-111111111111', 'c1111111-1111-1111-1111-111111111111', 'd1111111-1111-1111-1111-111111111111', CURRENT_DATE, '08:00:00', '11:00:00', 10, 0, 'available'),
    ('e1111111-1111-1111-1111-111111111112', 'c1111111-1111-1111-1111-111111111111', 'd1111111-1111-1111-1111-111111111111', CURRENT_DATE + INTERVAL '1 day', '08:00:00', '11:00:00', 10, 0, 'available'),
    -- Jadwal drg. Siti Rahmawati (Gigi)
    ('e2222222-2222-2222-2222-222222222221', 'c1111111-1111-1111-1111-111111111111', 'd2222222-2222-2222-2222-222222222222', CURRENT_DATE, '13:00:00', '16:00:00', 8, 0, 'available'),
    ('e2222222-2222-2222-2222-222222222222', 'c1111111-1111-1111-1111-111111111111', 'd2222222-2222-2222-2222-222222222222', CURRENT_DATE + INTERVAL '1 day', '13:00:00', '16:00:00', 8, 0, 'available'),
    -- Jadwal dr. Maya Kartika, Sp.A (Anak)
    ('e3333333-3333-3333-3333-333333333331', 'c1111111-1111-1111-1111-111111111111', 'd3333333-3333-3333-3333-333333333333', CURRENT_DATE, '09:00:00', '12:00:00', 8, 0, 'available'),
    -- Jadwal dr. Andi Wijaya, Sp.PD (Penyakit Dalam)
    ('e4444444-4444-4444-4444-444444444441', 'c1111111-1111-1111-1111-111111111111', 'd4444444-4444-4444-4444-444444444444', CURRENT_DATE, '16:00:00', '19:00:00', 6, 0, 'available')
ON CONFLICT (id) DO NOTHING;
