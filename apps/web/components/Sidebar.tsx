'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  LayoutDashboard,
  Users2,
  CalendarDays,
  FileCheck2,
  Radio,
  ShieldCheck,
  Building2,
} from 'lucide-react';

export default function Sidebar() {
  const pathname = usePathname();

  const navItems = [
    { label: 'Dashboard Ringkasan', href: '/', icon: LayoutDashboard },
    { label: 'Queue Monitor (Terminal)', href: '/queue', icon: Radio },
    { label: 'Manajemen Booking', href: '/appointments', icon: FileCheck2 },
    { label: 'Jadwal Dokter', href: '/schedules', icon: CalendarDays },
    { label: 'Direktori Dokter & Poli', href: '/doctors', icon: Users2 },
    { label: 'Audit Trail & Log', href: '/audit', icon: ShieldCheck },
  ];

  return (
    <aside className="admin-sidebar">
      <div className="sidebar-brand">
        <div className="brand-icon">
          <Building2 size={22} />
        </div>
        <div>
          <div className="brand-title">SIMKlinik</div>
          <div className="brand-subtitle">Admin & Queue Terminal</div>
        </div>
      </div>

      <nav className="sidebar-nav">
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = pathname === item.href;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`nav-link ${isActive ? 'active' : ''}`}
            >
              <Icon size={18} />
              <span>{item.label}</span>
            </Link>
          );
        })}
      </nav>

      <div style={{ padding: '16px 20px', borderTop: '1px solid var(--border)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div
            style={{
              width: '34px',
              height: '34px',
              borderRadius: '50%',
              background: 'var(--primary-light)',
              color: 'var(--primary)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontWeight: 700,
              fontSize: '13px',
            }}
          >
            AD
          </div>
          <div>
            <div style={{ fontSize: '13px', fontWeight: 600 }}>Administrator</div>
            <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>Admin Klinik Utama</div>
          </div>
        </div>
      </div>
    </aside>
  );
}
