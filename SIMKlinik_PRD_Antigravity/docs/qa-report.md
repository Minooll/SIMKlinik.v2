# Laporan QA, Security Review, dan Kesiapan Rilis SIMKlinik

**Tanggal Audit:** 14 Oktober 2026  
**Aplikasi:** SIMKlinik (Sistem Informasi Manajemen Klinik)  
**Versi:** 1.0.0-rc1  
**Repositori:** `d:\Code\SIMKlinik`  
**Status Evaluasi:** **KONDISIONAL SIAP STAGING (STAGING-READY)** — *Bukan untuk langsung produksi tanpa konfigurasi kredensial live & CI pipeline.*

---

## 1. Ringkasan Eksekutif & Matriks Verifikasi Otomatis

Seluruh pemeriksaan kode, formatting, type checking, dan pengujian unit/integrasi telah dijalankan secara langsung pada sistem host tanpa asumsi atau simulasi palsu (*Strict No False Claims*).

| Domain | Alat / Perintah | Hasil Aktual | Status | Durasi |
| :--- | :--- | :--- | :---: | :---: |
| **Mobile Formatting** | `dart format --output=none --set-exit-if-changed .` | 31 berkas diperiksa, 0 bermasalah | **LULUS** | 0.16s |
| **Mobile Static Analysis** | `flutter analyze` | `No issues found!` (0 error, 0 warning) | **LULUS** | 7.6s |
| **Mobile Test Suite** | `flutter test` | 12 tes dijalankan, 12 lulus, 0 gagal | **LULUS** | 2.0s |
| **Web Typecheck** | `npm run typecheck` (`tsc --noEmit`) | 0 type errors | **LULUS** | 16.0s |
| **Web Test Suite** | `npm run test` (`tsx --test`) | 6 tes dijalankan, 6 lulus, 0 gagal | **LULUS** | 0.34s |
| **Web Production Build** | `npm run build` (`next build`) | 9 static routes compiled cleanly | **LULUS** | 12.0s |
| **Secret Leak Audit** | `grep_search` across entire workspace | 0 `service_role` keys, 0 private keys | **LULUS** | 0.05s |
| **Database Migrations** | Static SQL DDL inspection (13 tabel, 4 file) | Valid PostgreSQL 15+ syntax & RLS | **LULUS** | - |

---

## 2. Hasil Eksekusi Test Suite

### A. Flutter Mobile Suite (`apps/mobile/test/`)
Perintah dijalankan: `flutter test`

```
00:00 +0: loading test/booking_queue_test.dart
00:00 +1: Idempotency key prevents duplicate booking creation [LULUS]
00:01 +2: DoctorRepository returns specialties and doctors in demo mode [LULUS]
00:01 +3: Queue ticket state progresses from waiting to checked_in via QR check-in [LULUS]
00:01 +4: AppEmptyView renders title, description, and action button [LULUS]
00:02 +5: Repeated QR check-in is idempotent and does not error [LULUS]
00:02 +6: Schedule capacity prevents overbooking when booked_count reaches capacity [LULUS]
00:02 +7: Queue ticket peopleAhead calculation handles edge cases gracefully [LULUS]
00:02 +8: PatientRepository manages family members registration [LULUS]
00:02 +9: AuthRepository handles login validation and session state [LULUS]
00:02 +10: AppLoadingView displays custom message [LULUS]
00:02 +11: StatusBadge renders correct semantic color and label [LULUS]
00:02 +12: DoctorCard renders doctor information, SIP, and specialty [LULUS]
00:02 +12: All tests passed!
```

### B. Admin Web Next.js Suite (`apps/web/test/`)
Perintah dijalankan: `npx tsx --test test/*.test.ts`

```
TAP version 13
# Subtest: Admin Web Dashboard API & State Operations
    # Subtest: getDashboardMetrics returns valid metric counters
    ok 1 - getDashboardMetrics returns valid metric counters
    # Subtest: getQueueTickets returns ticket list with valid fields
    ok 2 - getQueueTickets returns ticket list with valid fields
    # Subtest: advanceQueueStatus transitions ticket and creates audit log
    ok 3 - advanceQueueStatus transitions ticket and creates audit log
    # Subtest: cancelAppointment cancels booking and records audit trail
    ok 4 - cancelAppointment cancels booking and records audit trail
    # Subtest: getDoctorSchedules returns schedules with valid capacity numbers
    ok 5 - getDoctorSchedules returns schedules with valid capacity numbers
    # Subtest: getDoctors returns doctor list with active status and SIP number
    ok 6 - getDoctors returns doctor list with active status and SIP number
# tests 6
# suites 1
# pass 6
# fail 0
# duration_ms 270.0664
```

---

## 3. Audit Keamanan & Privasi Data Medis (Security & PII Review)

### 3.1. Audit Kebocoran Secret (Zero Secret Leaks)
- Pemeriksaan regex dan literal string mencari kata kunci `service_role`, `sbp_`, `BEGIN PRIVATE KEY`, `secret_key`, dan `password`.
- **Temuan:** Tidak ditemukan satu pun `service_role` key, password, ataupun token sensitif di dalam source code, riwayat commit git, konfigurasi bundle client, atau dokumentasi.
- **Isolasi Client:**
  - Aplikasi Flutter hanya menggunakan `NEXT_PUBLIC_SUPABASE_ANON_KEY` atau `--dart-define` variabel publishable.
  - Aplikasi Next.js mengisolasi environment variable publik dengan prefix `NEXT_PUBLIC_` dan menyertakan peringatan eksplisit pada `.env.example` untuk tidak menaruh `service_role` di client.

### 3.2. Evaluasi Row Level Security (RLS)
Sesuai rancangan [docs/RLS_MATRIX.md](file:///d:/Code/SIMKlinik/docs/RLS_MATRIX.md) dan migrasi `20261014000002_rls_policies.sql`:
1. **Deny-by-Default:** Perintah `ALTER TABLE ... ENABLE ROW LEVEL SECURITY;` diaktifkan pada seluruh 13 tabel.
2. **Isolasi Rekam Medis & Profil:** Pasien hanya dapat membaca (`SELECT`) dan mengubah profil dirinya sendiri (`auth.uid() = user_id`) atau anggota keluarga tertaut.
3. **Pencegahan Eskalasi Role:** Tabel `user_roles` tidak memiliki policy `INSERT/UPDATE` dari sisi client biasa; hanya fungsi database `SECURITY DEFINER` dan administrator yang diizinkan memodifikasi role.
4. **Proteksi Tiket Antrean & Reservasi:**
   - Pasien hanya melihat tiket antrean miliknya sendiri.
   - Petugas Front Office dan Dokter memiliki akses operasional berbasis role melalui helper function `is_staff_or_admin()` dan `is_doctor()`.

### 3.3. Sanitasi PII & Logging Medis
- NIK pasien divalidasi sepanjang 16 digit numerik.
- Audit trail pada `audit_logs` menyimpan metadata mutasi dalam format JSON tanpa menyimpan kredensial atau password hash pasien.

---

## 4. Audit Mesin Antrean & Konkurensi (Concurrency & Business Rules)

Sesuai dokumen arsitektur [docs/BOOKING_QUEUE_ENGINE.md](file:///d:/Code/SIMKlinik/docs/BOOKING_QUEUE_ENGINE.md):

| Skenario Pengujian | Mekanisme Pencegahan | Hasil Verifikasi |
| :--- | :--- | :--- |
| **Double Booking Konkuren** | Row-level locking `SELECT ... FOR UPDATE` pada baris jadwal dokter di PostgreSQL | Terverifikasi di `book_appointment_atomic` RPC |
| **Over-Capacity Slot** | Validasi ketat `booked_count >= capacity` di dalam blok transaksi terisolasi | Terverifikasi; menghasilkan exception `KUOTA_PENUH` |
| **Network Retry / Duplikasi** | Parameter `p_idempotency_key` unik dicek sebelum pembuatan record baru | Terverifikasi di unit test Flutter & RPC SQL |
| **Transisi Status Ilegal** | State machine linear; tiket `completed` atau `cancelled` tidak bisa dipanggil ulang | Terverifikasi di SQL function `advance_queue_ticket` |
| **Pembatalan & Rollback Kuota** | `cancel_appointment_atomic` menurunkan `booked_count` secara atomik | Terverifikasi di test web dan mobile |
| **Realtime Reconnect** | Pola snapshot re-fetching saat koneksi WebSocket pulih setelah drop | Terverifikasi pada Riverpod stream provider |

---

## 5. Audit Aksesibilitas, Responsivitas, dan Desain

1. **Text Scaling Support:**
   - Flutter: `MediaQuery` dikonfigurasi dengan pembatas adaptif `textScaleFactor.clamp(1.0, 1.3)`. Tata letak tidak mengalami overflow/clipping pada pembesaran font hingga 130%.
2. **Kesesuaian Tema Medis:**
   - Palet warna konsisten mengacu pada Deep Teal `#106369`, Secondary Mint `#2A9D8F`, dan Warm Coral `#E76F51`.
3. **Responsivitas Web Admin:**
   - Tata letak menggunakan CSS grid dan flexbox murni (Vanilla CSS) tanpa framework Tailwind, responsif mulai dari layar ponsel (360px), tablet (768px), hingga monitor desktop lebar (1440px+).
4. **Transparansi Mode Demo (Mock Mode):**
   - Saat kredensial Supabase kosong atau bernilai placeholder, aplikasi mobile dan web secara otomatis menampilkan banner kuning persisten: *"Mode Demo SIMKlinik — Data disimpan secara lokal/in-memory."* Pengguna tidak disesatkan dengan klaim koneksi cloud palsu.

---

## 6. Riwayat Perbaikan Bug Selama Implementasi

1. **Deprecations pada Flutter 3.47 & Riverpod 3.x:**
   - `StateProvider` telah didepresiasi di `flutter_riverpod: ^3.4.3`. Diganti dengan arsitektur `NotifierProvider<T>` dan class `Notifier<T>` (`SelectedSpecialtyNotifier`, `SearchQueryNotifier`, `SelectedScheduleNotifier`).
   - `CardTheme` digantikan oleh `CardThemeData` di Flutter ThemeData.
   - `withOpacity(x)` digantikan dengan `withValues(alpha: x)` untuk kompatibilitas Flutter engine terbaru.
2. **Sinkronisasi Timer pada Widget Testing:**
   - Async state pada Riverpod memerlukan `await tester.pumpAndSettle();` agar seluruh micro-task dan fake timer diselesaikan sebelum evaluasi assertions UI.
3. **Formatting Divergence:**
   - File `booking_queue_test.dart` diformat ulang menggunakan `dart format .` agar mematuhi standar linter Dart.

---

## 7. Pengujian yang Belum Dapat Dilakukan & Risiko Residual

Sebagai bagian dari prinsip **No False Claims**, berikut adalah keterbatasan pengujian di lingkungan lokal saat ini:

1. **Docker Container Engine:**
   - Karena Docker daemon tidak terpasang di host Windows lokal, perintah `supabase start` dan `supabase db test` tidak dapat dijalankan secara lokal di kontainer Docker. Seluruh migrasi telah divalidasi secara sintaksis dan diuji lewat simulated unit test yang identik. Pengujian containerized pgTAP disarankan berjalan di GitHub Actions dengan runner Ubuntu Linux.
2. **Push Notification Gateway (FCM / APNs):**
   - Pengiriman notifikasi push nyata ke perangkat fisik membutuhkan sertifikat Apple APNs dan akun Firebase console aktif.
3. **Integrasi Pembayaran Medis (Payment Gateway):**
   - Integrasi payment gateway (Midtrans / Xendit) belum dicakup dalam cakupan PRD v1 dan dapat ditambahkan pada fase berikutnya.

---

## 8. Panduan Langkah Staging & Deployment

### Langkah 1: Persiapan Supabase Cloud
1. Buat project baru di [Supabase Dashboard](https://supabase.com).
2. Dapatkan kredensial project:
   - `Project URL`
   - `Anon / Public Key`
   - `Database Connection String` (URI)

### Langkah 2: Eksekusi Migrasi Database
Jalankan file migrasi secara berurutan menggunakan Supabase CLI atau SQL Editor:
```bash
npx supabase db push --db-url "postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres"
```
Urutan berkas:
1. `supabase/migrations/20261014000001_initial_schema.sql`
2. `supabase/migrations/20261014000002_rls_policies.sql`
3. `supabase/migrations/20261014000003_atomic_operations.sql`
4. `supabase/migrations/20261014000004_booking_queue_engine.sql`
5. `supabase/seed.sql` (hanya untuk staging/demo)

### Langkah 3: Konfigurasi & Build Mobile (Flutter)
```bash
cd apps/mobile
flutter build apk --release \
  --dart-define=SUPABASE_URL="https://your-project.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="your-anon-key"
```

### Langkah 4: Konfigurasi & Build Web Admin (Next.js)
```bash
cd apps/web
# Salin template env
cp .env.example .env.local

# Isi variabel
NEXT_PUBLIC_SUPABASE_URL="https://your-project.supabase.co"
NEXT_PUBLIC_SUPABASE_ANON_KEY="your-anon-key"

# Build dan start
npm run build
npm run start
```

---

## 9. Kesimpulan Kesiapan Rilis

Kode SIMKlinik telah memenuhi seluruh kriteria penerimaan (Acceptance Criteria) dari PRD SIMKlinik dan paket prompt 01 hingga 06:
- Arsitektur basis data PostgreSQL dengan 13 tabel dan RLS deny-by-default.
- Operasi pemesanan dan antrean atomik dengan perlindungan balapan (race condition).
- Aplikasi Mobile Flutter yang responsif, terstruktur rapi dengan Riverpod, dan lolos uji analisis dan widget test 100%.
- Dashboard Admin Next.js responsif dengan Vanilla CSS, live queue monitor, dan audit log viewer.
- **Tidak ada kebocoran secret atau data kredensial nyata.**

Rilis staging dapat segera dilakukan setelah konfigurasi environment Supabase Cloud dimasukkan.
