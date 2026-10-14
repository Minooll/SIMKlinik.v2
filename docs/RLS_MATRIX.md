# Matriks Kebijakan Akses & Row-Level Security (RLS) — SIMKlinik

**Dokumen:** Spesifikasi Matriks Otorisasi Database PostgreSQL & Supabase  
**Prinsip Keamanan:** *Deny-by-Default*, *Least-Privilege*, *Anti-Privilege-Escalation*, *Atomic Server Operations*

---

## 1. Definisi Peran (Roles)

| Peran (`user_role`) | Deskripsi & Hak Operasional |
|---|---|
| **`anon`** | Pengunjung belum login. Hanya dapat membaca data publik (klinik aktif, daftar spesialisasi, daftar dokter aktif, jadwal mendatang). |
| **`patient`** | Pasien terautentikasi. Membaca dan mengelola profil sendiri, melihat riwayat booking & tiket antrean sendiri, melakukan reservasi atomik. Tidak memiliki akses ke data pasien lain. |
| **`doctor`** | Dokter terdaftar. Membaca jadwal sendiri, melihat daftar pasien yang terdaftar pada jadwalnya, memanggil dan menyelesaikan antrean pelayanan. |
| **`staff`** | Petugas registrasi / front desk klinik. Mengelola operasional pendaftaran, verifikasi QR check-in pasien, memantau antrean, mengelola jadwal dokter. |
| **`admin`** | Manajer klinik. Mengelola data master klinik, dokter, spesialisasi, jadwal, operasional penuh, dan membaca audit log. |
| **`superadmin`** | Administrator sistem teknis. Memiliki kontrol penuh terhadap konfigurasi sistem dan manajemen penetapan peran. |

---

## 2. Matriks RLS per Tabel & Operasi

### A. Tabel `profiles`
*Tabel relasional identitas dasar pengguna yang terhubung langsung ke `auth.users`.*
- **SELECT:** `auth.uid() = id OR public.is_staff_or_admin()`
  - *Pasien:* Hanya melihat profil diri sendiri.
  - *Petugas/Admin:* Melihat profil untuk kebutuhan operasional pendaftaran.
- **INSERT:** `auth.uid() = id` (Otomatis dibuat oleh trigger database `on_auth_user_created`).
- **UPDATE:** `auth.uid() = id` (Hanya mengubah nama, no telepon, avatar).
- **DELETE:** Ditolak di client (hanya via cascading `auth.users`).

### B. Tabel `user_roles`
*Tabel terisolasi untuk hak akses. Pasien DILARANG KERAS mengubah atau menaikkan rolenya sendiri.*
- **SELECT:** `auth.uid() = user_id OR public.is_staff_or_admin()`
- **INSERT / UPDATE / DELETE:** `public.is_admin()`
  - *Payload client tidak dipercaya:* Pasien biasa tidak dapat melakukan INSERT atau UPDATE ke tabel ini.

### C. Tabel `patient_profiles`
*Profil data medis/kunjungan pasien (NIK, tanggal lahir, jenis kelamin, golongan darah).*
- **SELECT:** `auth.uid() = user_id OR public.is_staff_or_admin() OR public.is_doctor()`
  - *Pasien lain:* **DENIED** (tidak dapat membaca profil pasien lain).
- **INSERT:** `auth.uid() = user_id` (Pasien mendaftarkan data keluarganya/dirinya).
- **UPDATE:** `auth.uid() = user_id OR public.is_staff_or_admin()`
- **DELETE:** `auth.uid() = user_id OR public.is_admin()`

### D. Tabel `clinics`
- **SELECT:** `is_active = TRUE OR public.is_staff_or_admin()` (Anon & Pasien dapat membaca klinik aktif).
- **INSERT / UPDATE / DELETE:** `public.is_admin()`

### E. Tabel `specialties`
- **SELECT:** `TRUE` (Publik dapat membaca daftar poli).
- **INSERT / UPDATE / DELETE:** `public.is_admin()`

### F. Tabel `doctors`
- **SELECT:** `is_active = TRUE OR public.is_staff_or_admin()` (Publik dapat melihat dokter yang aktif).
- **INSERT / UPDATE / DELETE:** `public.is_staff_or_admin()`

### G. Tabel `doctor_schedules`
- **SELECT:** `schedule_date >= CURRENT_DATE OR public.is_staff_or_admin() OR (auth.uid() IN (SELECT user_id FROM doctors WHERE id = doctor_id))`
- **INSERT / UPDATE / DELETE:** `public.is_staff_or_admin()`

### H. Tabel `appointments`
- **SELECT:** `auth.uid() = user_id OR public.is_staff_or_admin() OR (auth.uid() IN (SELECT d.user_id FROM doctors d JOIN doctor_schedules ds ON ds.doctor_id = d.id WHERE ds.id = schedule_id))`
- **INSERT:** Diizinkan via RLS dengan `auth.uid() = user_id`, namun direkomendasikan melalui RPC atomik `book_appointment_atomic`.
- **UPDATE:** `(auth.uid() = user_id AND status IN ('pending', 'confirmed')) OR public.is_staff_or_admin()`
  - Pasien hanya diizinkan mengubah status menjadi `cancelled`.
- **DELETE:** Ditolak (Soft cancellation).

### I. Tabel `queue_sessions`
- **SELECT:** `session_date = CURRENT_DATE OR public.is_staff_or_admin()`
- **INSERT / UPDATE / DELETE:** `public.is_staff_or_admin()`

### J. Tabel `queue_tickets`
- **SELECT:** `auth.uid() = user_id OR public.is_staff_or_admin() OR (auth.uid() IN (SELECT d.user_id FROM doctors d JOIN queue_sessions qs ON qs.doctor_id = d.id WHERE qs.id = queue_session_id))`
- **UPDATE:** `public.is_staff_or_admin() OR public.is_doctor()` (Check-in, call, in-service, complete).
- **INSERT / DELETE:** Dikelola secara otomatis oleh server/RPC atomik.

### K. Tabel `queue_events`
- **SELECT:** Pemilik tiket (`user_id = auth.uid()`), Staff, Dokter, dan Admin.
- **INSERT:** Staff dan Dokter saat melakukan perubahan alur antrean.
- **UPDATE / DELETE:** Ditolak (Audit immutability).

### L. Tabel `notifications`
- **SELECT:** `auth.uid() = user_id`
- **UPDATE:** `auth.uid() = user_id` (Menandai `is_read = TRUE`).
- **INSERT / DELETE:** Server / Trigger backend saja.

### M. Tabel `audit_logs`
- **SELECT:** `public.is_staff_or_admin()`
- **INSERT / UPDATE / DELETE:** Ditolak dari client secara langsung. Ditulis oleh fungsi sistem `SECURITY DEFINER` dengan parameter aman.

---

## 3. Matriks Hak Akses Ringkas

| Resource | Anon | Pasien Pemilik | Pasien Lain | Dokter Terkait | Petugas / Staff | Admin Klinik |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| `clinics` | Read Active | Read | Read | Read | Read / Manage | Full Manage |
| `specialties` | Read | Read | Read | Read | Read | Full Manage |
| `doctors` | Read Active | Read | Read | Read | Manage | Full Manage |
| `doctor_schedules` | Read | Read | Read | Read Own | Manage | Full Manage |
| `patient_profiles` | Deny | Full Own | **Deny** | Read Patient | Read / Update | Full Manage |
| `appointments` | Deny | Read/Cancel Own | **Deny** | Read Assigned | Manage Scope | Full Manage |
| `queue_tickets` | Deny | Read Own Ticket | **Deny** | Read/Update Session | Read/Advance | Full Manage |
| `queue_events` | Deny | Read Own Ticket Events | **Deny** | Read/Insert | Read/Insert | Read All |
| `notifications` | Deny | Read/Update Own | **Deny** | Read/Update Own | Manage Scope | Full Manage |
| `user_roles` | Deny | Read Own Role | **Deny** | Read Own | Read Scope | Full Manage |
| `audit_logs` | Deny | **Deny** | **Deny** | Minimal Scope | Read Scope | Read All |

---

## 4. Keamanan RPC & Operasi Atomik

1. **Anti-Race-Condition Booking:**
   - RPC `book_appointment_atomic` menggunakan `SELECT ... FOR UPDATE` pada baris `doctor_schedules`.
   - Mengunci slot kapasitas secara atomik sehingga dua pasien yang mengklik booking di milidetik yang sama tidak akan melampaui kapasitas dokter.
2. **Idempotency Guarantee:**
   - Parameter `p_idempotency_key` pada `book_appointment_atomic` menjamin jika terjadi retry jaringan di Flutter/Web, server akan mengembalikan hasil booking yang sudah ada tanpa menduplikasi slot.
3. **QR Token Security:**
   - Kolom `qr_token` pada `queue_tickets` di-generate menggunakan `encode(gen_random_bytes(16), 'hex')`.
   - Tidak mencantumkan NIK atau data identitas sensitif di payload QR fisik.
4. **Fungsi Security Definer:**
   - Semua fungsi `SECURITY DEFINER` menyetel secara eksplisit `SET search_path = public, auth, pg_temp` untuk mencegah eksploitasi search path hijacking.
