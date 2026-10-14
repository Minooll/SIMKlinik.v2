import type { Metadata } from 'next';
import './globals.css';
import Sidebar from '../components/Sidebar';
import Topbar from '../components/Topbar';

export const metadata: Metadata = {
  title: 'SIMKlinik — Dashboard Operasional & Antrean Klinik',
  description: 'Sistem Informasi Manajemen Klinik untuk operasional pendaftaran, jadwal dokter, booking, antrean, dan audit trail.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="id">
      <body>
        <div className="admin-layout">
          <Sidebar />
          <div className="admin-content-wrapper">
            <Topbar />
            <main className="admin-main">{children}</main>
          </div>
        </div>
      </body>
    </html>
  );
}
