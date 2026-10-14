# Prompt 3 — Implementasi Flutter Mobile
Implementasikan aplikasi Flutter SIMKlinik untuk Android/iOS dengan modular feature-first architecture.
- Audit pubspec dan arsitektur existing sebelum memilih/menambah dependency.
- Gunakan Supabase Flutter SDK sesuai versi yang kompatibel dan dokumentasi resmi; konfigurasi melalui dart-define/env yang sesuai, jangan commit secrets.
- Buat theme modern clinical minimalism, deep teal kandidat #106369, komponen reusable, text scaling, semantic labels.
- Modul: auth, patient profile, doctor search, specialty/clinic filters, schedule slots, booking, ticket antrean, notifications, profile/history.
- Pisahkan presentation/state/domain/data/repository. Model typed dan error mapping.
- Tiap async screen punya loading, empty, error, timeout/offline, permission-denied, dan success states.
- Jangan gunakan mock data sebagai fallback diam-diam saat production. Tandai mock/demo mode eksplisit.
- Booking baru dinyatakan sukses setelah respons server. Handle retry dan double tap.
- Implementasikan navigation dan role-based UI, tetapi tetap andalkan RLS/server authorization.
- Tambahkan unit/widget tests untuk critical flows dan accessibility semantics.
- Jalankan `dart format`, `flutter analyze`, `flutter test` jika Flutter tersedia. Laporkan hasil aktual.
