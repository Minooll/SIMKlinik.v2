# Prompt 6 — QA, Security Review, dan Release Readiness
Lakukan review menyeluruh terhadap SIMKlinik.
- Jalankan formatter, analyzer/lint, typecheck, unit/widget tests, web tests, build, migration validation, dan integration tests yang dapat dijalankan.
- Audit RLS setiap tabel dan akses anon/pasien sendiri/pasien lain/dokter/petugas/admin.
- Cari service_role/secret dalam source, history/diff, bundle client, logs, dan dokumentasi; jangan menampilkan nilai secret.
- Uji double booking, over-capacity, idempotency, invalid state transitions, expired sessions, rate limits, input validation, dan realtime reconnect.
- Uji responsif mobile/web, text scaling, keyboard navigation, empty/error/offline states.
- Jangan gunakan data pasien nyata. Pastikan logging redacted.
- Buat `docs/qa-report.md` dengan command, hasil aktual, failure, bug yang diperbaiki, test yang belum bisa dilakukan, residual risk, dan langkah staging.
- Jangan deploy production tanpa persetujuan eksplisit. Jangan klaim production-ready bila masih ada blocker keamanan atau test penting yang gagal.
