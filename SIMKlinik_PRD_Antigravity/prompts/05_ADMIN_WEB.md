# Prompt 5 — Dashboard Admin Web
Implementasikan dashboard admin SIMKlinik menggunakan Next.js + TypeScript kecuali repository existing memberi alasan kuat untuk stack lain.
- Audit app existing, package, dan pola auth Supabase sebelum mengubah.
- Layout: sidebar, topbar, responsive content, metric cards, tables, filter/search, pagination, confirmation dialog, toast/error states.
- Halaman MVP: dashboard summary, dokter, jadwal, booking, queue monitor, audit view.
- Role dan hak akses divalidasi di server/database; jangan mengandalkan route guard UI saja.
- Hindari menaruh service_role/secret di browser. Gunakan pola resmi Supabase SSR/session bila memakai SSR.
- Tabel harus memiliki loading/empty/error state, keyboard navigation, semantic labels, dan responsive behavior.
- Semua perubahan status antrean harus memanggil operasi server yang tervalidasi dan mencatat aktor.
- Tambahkan lint/typecheck/unit/integration tests yang sesuai; laporkan hasil aktual.
