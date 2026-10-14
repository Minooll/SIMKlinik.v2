# Prompt 4 — Booking Atomik & Antrean
Implementasikan booking dan antrean berdasarkan schema serta policy yang telah diverifikasi.
1. Definisikan state machine appointment dan queue bersama transisi valid.
2. Booking harus mencegah over-capacity dan double booking di database/server dengan transaction/RPC atau mekanisme locking/constraint yang benar.
3. Terapkan idempotency untuk retry jika sesuai; jangan menciptakan nomor antrean baru saat retry request yang sama.
4. Buat operasi check-in, call, start service, complete, skip/cancel sesuai role dan aturan klinik.
5. Simpan queue_events/audit untuk perubahan sensitif, actor dan timestamp; alasan diperlukan untuk override.
6. Realtime hanya mekanisme notifikasi perubahan; setelah reconnect, ambil snapshot terbaru dari server.
7. Estimasi tunggu harus dilabeli sebagai perkiraan, menampilkan rentang dan last-updated; jangan memberi janji pasti.
8. Uji concurrent requests pada slot terakhir, duplicate requests, illegal state transitions, repeated check-in, disconnect/reconnect, dan akses lintas pasien.
9. Dokumentasikan SQL/function, client flow, edge cases, serta hasil test nyata.
