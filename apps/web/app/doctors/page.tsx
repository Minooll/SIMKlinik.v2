'use client';

import React, { useEffect, useState } from 'react';
import {
  UserCheck,
  Search,
  RefreshCw,
  Award,
  Phone,
  FileText,
  CheckCircle,
  Building2,
  Stethoscope,
} from 'lucide-react';
import { getDoctors, Doctor } from '@/lib/supabase';

export default function DoctorsPage() {
  const [doctors, setDoctors] = useState<Doctor[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedSpecialty, setSelectedSpecialty] = useState<string>('all');

  const loadData = async () => {
    try {
      setLoading(true);
      const data = await getDoctors();
      setDoctors(data);
    } catch (err: unknown) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const specialties = ['all', ...Array.from(new Set(doctors.map((d) => d.specialty_name)))];

  const filtered = doctors.filter((doc) => {
    const matchesQuery =
      doc.full_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      doc.specialty_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      doc.sip_number.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesSpecialty = selectedSpecialty === 'all' ? true : doc.specialty_name === selectedSpecialty;
    return matchesQuery && matchesSpecialty;
  });

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '22px' }}>
        <div>
          <h1 style={{ fontSize: '24px', fontWeight: 700, color: 'var(--text-primary)', letterSpacing: '-0.5px' }}>
            Direktori Tenaga Medis & Dokter
          </h1>
          <p style={{ fontSize: '13.5px', color: 'var(--text-muted)' }}>
            Daftar dokter spesialis dan umum dengan izin praktik (SIP) aktif di SIMKlinik.
          </p>
        </div>
        <button
          onClick={loadData}
          disabled={loading}
          className="btn btn-secondary"
          title="Segarkan daftar dokter"
        >
          <RefreshCw size={15} className={loading ? 'animate-spin' : ''} />
          <span>Refresh</span>
        </button>
      </div>

      {/* Filter and Search */}
      <div className="filter-bar">
        <div className="search-input-wrapper">
          <Search size={16} />
          <input
            type="text"
            className="input-search"
            placeholder="Cari nama dokter, no. SIP, atau keahlian..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        <div className="filter-pills">
          {specialties.map((spec) => (
            <button
              key={spec}
              onClick={() => setSelectedSpecialty(spec)}
              className={`filter-pill ${selectedSpecialty === spec ? 'active' : ''}`}
            >
              {spec === 'all' ? 'Semua Poli' : spec}
            </button>
          ))}
        </div>
      </div>

      {/* Doctors Grid Cards */}
      {loading ? (
        <div className="card" style={{ textAlign: 'center', padding: '48px' }}>
          <div style={{ color: 'var(--text-muted)', fontSize: '13.5px' }}>Memuat daftar dokter...</div>
        </div>
      ) : filtered.length === 0 ? (
        <div className="card">
          <div className="empty-state">
            <div className="empty-state-icon">
              <Stethoscope size={24} />
            </div>
            <div className="empty-state-title">Tidak ada dokter ditemukan</div>
            <div className="empty-state-text">
              Tidak ada data dokter yang sesuai dengan kriteria pencarian Anda.
            </div>
          </div>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '20px' }}>
          {filtered.map((doc) => (
            <div key={doc.id} className="card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
              <div>
                <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '12px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <div
                      style={{
                        width: '46px',
                        height: '46px',
                        borderRadius: '50%',
                        background: 'var(--primary-subtle)',
                        color: 'var(--primary)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontWeight: 700,
                        fontSize: '16px',
                      }}
                    >
                      {doc.full_name.replace('dr. ', '').replace('drg. ', '').slice(0, 2).toUpperCase()}
                    </div>
                    <div>
                      <h3 style={{ fontSize: '15px', fontWeight: 700, color: 'var(--text-primary)' }}>
                        {doc.full_name}
                      </h3>
                      <div style={{ fontSize: '12px', color: 'var(--primary)', fontWeight: 600 }}>
                        {doc.specialty_name}
                      </div>
                    </div>
                  </div>
                  <span className="badge badge-success">
                    <CheckCircle size={11} /> Aktif
                  </span>
                </div>

                <p style={{ fontSize: '12.5px', color: 'var(--text-secondary)', lineHeight: 1.5, marginBottom: '16px' }}>
                  {doc.bio}
                </p>
              </div>

              <div style={{ borderTop: '1px solid var(--border)', paddingTop: '14px', display: 'flex', flexDirection: 'column', gap: '6px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '12px', color: 'var(--text-muted)' }}>
                  <Award size={14} style={{ color: 'var(--primary)' }} />
                  <span>No. SIP: <strong style={{ color: 'var(--text-primary)' }}>{doc.sip_number}</strong></span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '12px', color: 'var(--text-muted)' }}>
                  <Phone size={14} style={{ color: 'var(--secondary)' }} />
                  <span>Kontak: <strong style={{ color: 'var(--text-primary)' }}>{doc.phone}</strong></span>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
