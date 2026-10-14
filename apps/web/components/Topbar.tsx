'use client';

import { Building, Sparkles, Bell } from 'lucide-react';
import { isDemoMode } from '../lib/supabase';

export default function Topbar() {
  const today = new Date().toLocaleDateString('id-ID', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });

  return (
    <header className="admin-topbar">
      <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Building size={18} color="var(--primary)" />
          <span style={{ fontSize: '14px', fontWeight: 600, color: 'var(--text-primary)' }}>
            Klinik Pratama Sehat Harmoni
          </span>
        </div>
        <span style={{ color: 'var(--border)' }}>|</span>
        <span style={{ fontSize: '12.5px', color: 'var(--text-secondary)' }}>{today}</span>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
        {isDemoMode ? (
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '4px 10px',
              background: '#fef3c7',
              color: '#92400e',
              borderRadius: '9999px',
              fontSize: '11.5px',
              fontWeight: 600,
            }}
          >
            <Sparkles size={13} />
            <span>Mode Demo (Simulasi Aktif)</span>
          </div>
        ) : (
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '4px 10px',
              background: 'var(--success-bg)',
              color: 'var(--success)',
              borderRadius: '9999px',
              fontSize: '11.5px',
              fontWeight: 600,
            }}
          >
            <span
              style={{
                width: '7px',
                height: '7px',
                borderRadius: '50%',
                background: 'var(--success)',
              }}
            />
            <span>Supabase Terhubung</span>
          </div>
        )}

        <button
          style={{
            padding: '8px',
            borderRadius: 'var(--radius-md)',
            background: 'var(--bg)',
            color: 'var(--text-secondary)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
          title="Notifikasi"
        >
          <Bell size={18} />
        </button>
      </div>
    </header>
  );
}
