# Prompt 2 — Database, Migration, dan RLS
Setelah audit disetujui, desain schema SIMKlinik sesuai model repository yang nyata. Gunakan migrations versioned; jangan mengubah production manual.
- Model minimal: profiles/roles, patient_profiles, clinics, specialties, doctors, doctor_schedules, appointments, queue_sessions, queue_tickets, queue_events, notifications, audit_logs sesuai kebutuhan scope.
- Tentukan PK/FK, check constraints, indexes, timezone policy, status enum/checks, unique rules, dan strategi multi-clinic bila dibutuhkan.
- Aktifkan RLS pada semua tabel yang dapat diakses client dan tulis policy least-privilege untuk pasien, dokter, petugas, admin.
- Jangan izinkan user mengubah role sendiri. Jangan percaya role dari payload client.
- Tambahkan seed data dummy saja.
- Untuk setiap policy, dokumentasikan siapa boleh SELECT/INSERT/UPDATE/DELETE dan kondisi ownership/role.
- Tambahkan tes akses positif dan negatif: anon, pasien sendiri, pasien lain, dokter, petugas, admin.
- Booking harus atomik dengan transaksi/RPC/locking/constraints yang benar; jangan hanya cek slot lalu insert di client.
- Periksa migration dari database existing sebelum menambahkan perubahan. Laporkan SQL yang dibuat dan tes yang benar-benar dijalankan.
