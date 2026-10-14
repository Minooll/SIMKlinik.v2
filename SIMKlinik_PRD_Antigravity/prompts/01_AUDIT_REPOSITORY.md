# Prompt 1 — Audit Repository & Supabase
Bertindak sebagai Senior Engineer. Audit repository SIMKlinik sebelum mengubah apa pun.
1. Periksa git status, struktur folder, package, versi Flutter/Dart/Node, konfigurasi environment tanpa menampilkan nilai secret.
2. Identifikasi fitur yang sudah ada, TODO, mock data, duplikasi, error handling, test suite, dan build scripts.
3. Jika Supabase CLI/project access sudah terkonfigurasi secara aman, inspeksi schema, migrations, RLS policies, triggers, functions, Auth settings, Realtime, dan buckets. Jangan pernah mencetak service role key atau token.
4. Jangan mengubah schema atau menimpa file pada fase audit.
5. Hasilkan `docs/audit-report.md`, tabel existing/gap/risk, blocker, dan rekomendasi urutan implementasi.
6. Jalankan hanya pemeriksaan read-only yang aman; tulis command dan output ringkas. Jangan mengklaim akses Supabase bila tidak benar-benar berhasil.
