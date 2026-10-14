# PRD — SIMKlinik (Sistem Informasi Manajemen Klinik)

**Versi:** 1.0 draft  **Target:** tugas kuliah/skripsi/capstone  **Stack utama:** Flutter + Supabase + Next.js admin

## 1. Ringkasan Produk

**Nama produk:** SIMKlinik — Sistem Informasi Manajemen Klinik.

**Tujuan:** Mengembangkan sistem digital yang menghubungkan registrasi pasien, pencarian dan penjadwalan dokter, booking kunjungan, check-in, serta manajemen antrean, dengan dashboard operasional klinik.

**Konteks:** Proyek tugas kuliah/skripsi/capstone. Prioritas adalah MVP yang berfungsi, dapat didemonstrasikan, mudah diuji, dan memiliki dokumentasi teknis.

**Platform:** Flutter untuk Android/iOS dan Next.js untuk dashboard admin web. Supabase sebagai platform backend dan PostgreSQL.

**Batasan penting:** Jangan mengklaim integrasi, pengujian, atau deployment telah berhasil sebelum dilakukan dan bukti hasilnya tersedia.

## 2. Masalah dan Peluang

**Masalah:** Pasien sulit melihat jadwal dokter yang akurat, belum mengetahui status antrean, dan harus menghubungi klinik untuk informasi. Petugas membutuhkan alat konsisten untuk mengelola jadwal, pendaftaran, dan pemanggilan pasien.

**Peluang:** Menyediakan perjalanan pasien yang transparan sejak memilih jadwal hingga selesai dilayani, serta mengurangi pekerjaan administrasi manual.

## 3. Tujuan dan Metrik Keberhasilan

**Tujuan produk:** Memudahkan registrasi, membuat booking lebih andal, memberi informasi antrean yang aktual, dan menyediakan kontrol operasional bagi petugas.

**Metrik:** Booking berhasil; tingkat duplikasi booking; waktu respons API; kesesuaian status antrean; crash-free sessions; waktu tunggu median/p90; no-show rate; feedback pengguna.

**Catatan:** Target numerik ditetapkan setelah lingkungan dan baseline diketahui. Metrik awal bukan klaim hasil yang telah dicapai.

## 4. Persona dan Hak Akses

**Pasien:** Registrasi/login, kelola profil, cari dokter dan jadwal, booking, reschedule/cancel sesuai aturan, check-in, lihat status antrean, menerima notifikasi.

**Petugas/admin klinik:** Kelola data operasional, jadwal, booking, check-in, antrean, pembatalan dan laporan sesuai izin.

**Dokter:** Lihat jadwal dan pasien yang relevan; perbarui status pelayanan sesuai kewenangan.

**Superadmin:** Kelola konfigurasi dan role dengan audit trail; akses istimewa dibatasi.

**Aturan:** Hak akses ditegakkan di backend/database. Menyembunyikan tombol di UI bukan kontrol keamanan.

## 5. Ruang Lingkup MVP

**Termasuk:** Autentikasi; profil pasien; daftar dokter/spesialisasi/klinik; jadwal dan ketersediaan; booking; pembatalan/reschedule; tiket antrean; check-in; panggil/mulai/selesai; dashboard admin; notifikasi dasar jika layanan tersedia; audit perubahan penting.

**Tidak termasuk secara default:** Diagnosis AI, rekam medis elektronik lengkap, pembayaran online, integrasi BPJS/SATUSEHAT, telemedicine, multi-cabang kompleks. Tambahkan hanya setelah persetujuan scope dan verifikasi persyaratan.

## 6. User Stories dan Acceptance Criteria

**US-01 Registrasi:** Sebagai pasien, saya dapat membuat akun dan melengkapi profil dengan validasi yang jelas. AC: field wajib divalidasi; error dapat dipahami; sesi aman; tidak terjadi pembuatan data ganda karena retry.

**US-02 Cari dokter:** Sebagai pasien, saya dapat mencari dokter berdasarkan spesialisasi, klinik, tanggal, dan slot. AC: hasil berasal dari database; loading, empty, error, dan retry tersedia.

**US-03 Booking:** Sebagai pasien, saya dapat memesan slot yang tersedia. AC: booking hanya sukses setelah konfirmasi server; kapasitas tidak terlampaui pada request bersamaan; operasi sensitif divalidasi server.

**US-04 Antrean:** Sebagai pasien, saya dapat melihat nomor dan status antrean. AC: status bersumber dari server; reconnect menyinkronkan ulang; waktu estimasi ditandai sebagai perkiraan.

**US-05 Check-in:** Sebagai petugas, saya dapat memvalidasi kedatangan. AC: hanya role berwenang; perubahan tercatat; check-in berulang ditangani secara idempotent.

**US-06 Pemanggilan:** Sebagai petugas/dokter berwenang, saya dapat memanggil, memulai, dan menyelesaikan pelayanan. AC: state transition valid; aktor dan waktu tercatat.

**US-07 Perubahan jadwal:** Sebagai admin, saya dapat mengubah jadwal dan melihat booking terdampak. AC: konflik jadwal dicegah; pasien terdampak dapat diberi notifikasi jika layanan aktif.

**US-08 Privasi:** Sebagai pasien, saya hanya dapat mengakses data sendiri atau profil yang secara eksplisit diizinkan. AC: uji akses lintas pasien ditolak oleh database/API.

## 7. Fitur Pembeda

**Estimasi antrean dinamis:** Perkiraan berbasis jumlah pasien di depan dan durasi historis/konfigurasi. Tampilkan rentang dan waktu pembaruan; jangan menjanjikan waktu pasti.

**Resilient booking:** Idempotency, konfirmasi server, pencegahan double booking, dan pemulihan status setelah timeout.

**QR check-in:** QR berisi token/reference yang tidak membocorkan data pasien; validasi di server dan memiliki aturan masa berlaku.

**Transparansi perubahan:** Informasi keterlambatan atau perubahan jadwal dan tindakan yang perlu dilakukan pasien.

**Mode aksesibilitas:** Teks dapat diperbesar, kontras memadai, bahasa sederhana, dan informasi tidak mengandalkan warna saja.

**Catatan diferensiasi:** Jangan mengklaim fitur tidak dimiliki kompetitor tanpa riset kompetitor aktual dan dokumentasi pembanding.

## 8. Nonfunctional Requirements

**Keamanan:** Supabase RLS untuk semua tabel yang terekspos ke client; deny-by-default; role/ownership checks; validasi input; rate limiting untuk operasi sensitif; secret hanya di environment server.

**Privasi:** Minimisasi data; data pasien dummy untuk pengembangan; kebijakan retensi; audit akses sensitif; tidak menaruh data medis atau token dalam log.

**Konsistensi:** PostgreSQL/backend menjadi sumber kebenaran jadwal, kapasitas, booking, nomor, dan status antrean.

**Reliabilitas:** Timeout, retry aman, state error, sinkronisasi ulang, dan transaksi untuk booking.

**Aksesibilitas:** Target WCAG 2.2 AA untuk web sebagai sasaran; label semantik; ukuran teks fleksibel; kontras; fokus keyboard.

**Maintainability:** Feature-first modular architecture, lint/format, migrations, dokumentasi, dan automated tests.

**Observability:** Error monitoring dan log terstruktur dengan redaksi data pribadi.

## 9. Rekomendasi Teknologi

**Mobile:** Flutter stable + Dart; Riverpod atau solusi state management yang sudah ada di repository; go_router jika belum ada router.

**Supabase:** supabase_flutter; PostgreSQL; Auth; RLS; Realtime sesuai kebutuhan; Edge Functions hanya untuk operasi yang memerlukan trusted server execution.

**Admin web:** Next.js + TypeScript; Supabase client dengan auth yang aman dan RLS. Untuk SSR, ikuti pola resmi Supabase untuk session/cookie dan jangan menyimpan secret service role di client.

**Quality:** flutter analyze, flutter test, lint/typecheck/test untuk web, SQL migration validation, RLS tests, integration/UAT.

**Aturan:** Periksa versi dan package yang sudah ada sebelum upgrade. Hindari menambahkan dependency tanpa alasan.

## 10. Arsitektur Logis

**Alur:** Flutter Mobile / Next.js Admin → Supabase Auth + API/Data Access → PostgreSQL + RLS. Realtime dan notification merupakan kanal pendukung; data database tetap sumber kebenaran.

**Operasi atomik:** Untuk booking, jangan mengandalkan pola client: cek slot lalu insert secara terpisah. Gunakan transaksi/RPC atau Edge Function tepercaya dengan locking/constraint yang tepat.

**Realtime:** Subscribe hanya ke channel/data yang diizinkan; RLS dan konfigurasi Realtime wajib diuji. Reconnect harus memuat ulang snapshot data.

**Migrasi:** Semua perubahan schema melalui migration versioned; jangan hanya mengubah database production secara manual.

## 11. Model Data Konseptual

**profiles:** id UUID yang terkait auth.users; display_name; phone; role/status bila model otorisasi membutuhkannya. Pertimbangkan tabel role terpisah dan jangan izinkan user memilih role privileged sendiri.

**patient_profiles:** id; owner_user_id; full_name; date_of_birth bila diperlukan; contact; created_at. Batasi field yang dikumpulkan.

**clinics:** id; name; address; timezone; status.

**specialties:** id; name; description.

**doctors:** id; profile_id opsional; specialty_id; display_name; license reference bila diperlukan; status.

**doctor_schedules:** id; clinic_id; doctor_id; starts_at; ends_at; capacity; status.

**appointments:** id; patient_id; schedule_id/slot_id; booking_reference; status; idempotency_key; created_at; cancelled_at.

**queue_sessions:** id; clinic_id; doctor_id; service_date; status.

**queue_tickets:** id; appointment_id; queue_session_id; ticket_number; status; checked_in_at; called_at; started_at; completed_at.

**queue_events:** id; queue_ticket_id; actor_user_id; previous_status; new_status; reason; created_at.

**notifications:** id; user_id; channel; template_key; status; sent_at; created_at.

**audit_logs:** id; actor_user_id; action; resource_type; resource_id; reason; created_at.

**Peringatan:** Skema ini konseptual. Sesuaikan dengan model slot, klinik tunggal/multi-cabang, aturan dokter, serta tipe database yang benar. Jangan mengasumsikan kolom atau constraint telah diterapkan.

## 12. Status dan Transisi

**Appointment:** pending/confirmed/cancelled/expired/no_show/completed sesuai alur yang disepakati.

**Queue:** waiting/checked_in/called/in_service/completed/skipped/cancelled sesuai proses klinik.

**Aturan:** Terapkan transisi status di fungsi/RPC tepercaya atau mekanisme server yang sesuai. Perubahan status harus idempotent jika operasi dapat diulang.

**Prioritas klinis:** Jangan menentukan prioritas medis secara otomatis. Urutan khusus harus mengikuti kebijakan klinik, aktor berwenang, dan audit trail.

## 13. Security & Privacy

**Secrets:** Anon/publishable key dapat digunakan client sesuai dokumentasi Supabase; service_role/secret key hanya server/secret manager. Jangan commit .env berisi secret.

**RLS:** Aktifkan dan tulis policy eksplisit pada seluruh tabel yang dapat diakses melalui API. Uji akses owner, role, tenant/clinic scope, dan akses yang ditolak.

**Role:** Jangan percaya role yang dikirim client. Gunakan claim/pemetaan role tepercaya dan policy yang memverifikasinya.

**Data kesehatan:** Gunakan data dummy selama development. Tentukan legal basis, consent/notice, retensi, backup, incident response, dan prosedur penghapusan sesuai aturan yang berlaku.

**Audit:** Jangan log password, access token, QR token, atau detail medis berlebihan.

## 14. UI/UX Design System

**Arah visual:** Modern clinical minimalism: profesional, tenang, tepercaya, lapang, mobile-first.

**Warna:** Deep teal #106369 sebagai kandidat primer; warna semantic untuk success/warning/error harus tetap memiliki label teks.

**Tipografi:** Hierarki jelas, body mudah dibaca, dukung text scaling.

**Komponen mobile:** Doctor card, filter chips, calendar/slot picker, booking summary, queue ticket, status badge, notification item, empty/error/loading states.

**Komponen web:** Sidebar, top bar, metric cards, searchable/filterable tables, schedule calendar, queue monitor, confirmation dialog, audit log view.

**Kondisi layar:** Setiap fitur wajib memiliki loading, success, empty, error, offline/timeout, dan permission-denied states.

**Responsif:** Uji Android/iOS screen sizes dan desktop/tablet widths; keyboard navigation untuk admin web.

## 15. QA dan Definition of Done

**Unit:** Validasi, state transitions, repository mapping, helper functions.

**Widget/UI:** Form, navigation, loading/error/empty state, accessibility semantics.

**Integration:** Registrasi → cari dokter → booking → check-in → call → in service → completed.

**Security:** Cross-user read/write, privilege escalation, RLS bypass attempts, secret scanning.

**Concurrency:** Banyak request untuk slot terakhir tidak melampaui kapasitas.

**Network:** Timeout, retry, reconnect, duplicate submission, stale state.

**DoD:** Code review; lint/typecheck; tests lulus; migrations tercatat; RLS diuji; tidak ada secret; dokumentasi diperbarui; hasil test dan keterbatasan dilaporkan.

## 16. Roadmap Implementasi

**Fase 0 — Discovery:** Audit repository dan project Supabase; inventaris tabel, policy, Auth, environment, package, dan API yang sudah ada.

**Fase 1 — Fondasi:** Dokumentasikan arsitektur final, environment, migrations, design tokens, routing, error handling, dan CI.

**Fase 2 — Auth/profile:** Implementasikan login/logout, session handling, profil dan role dengan RLS.

**Fase 3 — Jadwal:** Implementasikan list dokter, filter, detail, jadwal, dan ketersediaan.

**Fase 4 — Booking:** Implementasikan operasi booking atomik, cancellation/reschedule, idempotency, dan uji concurrency.

**Fase 5 — Antrean:** Implementasikan check-in, queue state machine, realtime/sync, dan estimasi.

**Fase 6 — Admin web:** Implementasikan jadwal, booking, antrean, dan dashboard sesuai role.

**Fase 7 — QA:** Integration, security/RLS, concurrency, responsive, UAT, bug fixing.

**Fase 8 — Release:** Staging, backup/rollback plan, environment checklist, dokumentasi demo, dan rilis hanya setelah approval.

## 17. Deliverables

**Dokumen:** PRD, arsitektur, ERD/schema, data dictionary, API/operation contract, RLS matrix, test plan, setup guide, dan user guide.

**Source code:** Flutter mobile, admin web, migrations, seed data dummy, tests, dan konfigurasi contoh tanpa secret.

**Bukti:** Output lint/test/build, hasil uji RLS/concurrency, screenshot dari implementasi aktual, daftar known issues.

**Pelaporan:** Daftar fitur Done/In Progress/Blocked/Not Started. Dilarang menandai Done tanpa bukti.

## 18. Risiko

**RLS keliru:** Buat policy matrix dan tes akses yang diizinkan/ditolak sebelum memasukkan data nyata.

**Double booking:** Operasi atomik di database/server, constraint, idempotency, concurrency test.

**Scope creep:** Kunci MVP; integrasi eksternal/AI di backlog terpisah.

**Realtime tidak konsisten:** Realtime hanya sinyal pembaruan; setelah reconnect selalu fetch state terbaru.

**Konfigurasi salah:** Pisahkan local/staging/production; validasi environment saat startup; jangan fallback diam-diam ke data palsu.

**Kebocoran data:** Minimisasi, secure storage, RLS, audit, secret scanning, data dummy.
