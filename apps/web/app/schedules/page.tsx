'use client';

import React, { useEffect, useState } from 'react';
import {
  Calendar,
  Search,
  RefreshCw,
  Clock,
  UserCheck,
  Building,
  CheckCircle,
  AlertCircle,
  Check,
} from 'lucide-react';
import {
  getDoctorSchedules,
  DoctorSchedule,
} from '@/lib/supabase';

export default function SchedulesPage() {
  const [schedules, setSchedules] = useState<DoctorSchedule[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const loadData = async () => {
    try {
      setLoading(true);
      const data = await getDoctorSchedules();
      setSchedules(data);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Gagal memuat jadwal dokter';
      setToast({ message: msg, type: 'error' });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const filtered = schedules.filter((sch) => {
    const matchesQuery =
      sch.doctor_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      sch.specialty_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      sch.clinic_name.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesStatus = statusFilter === 'all' ? true : sch.status === statusFilter;
    return matchesQuery && matchesStatus;
  });

  const getCapacityColor = (booked: number, capacity: number) => {
    const ratio = booked / capacity;
    if (ratio >= 1) return 'var(--danger)';
    if (ratio >= 0.75) return 'var(--warning)';
    return 'var(--primary)';
  };

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '22px' }}>
        <div>
          <h1 style={{ fontSize: '24px', fontWeight: 700, color: 'var(--text-primary)', letterSpacing: '-0.5px' }}>
            Jadwal Praktik & Kuota Dokter
          </h1>
          <p style={{ fontSize: '13.5px', color: 'var(--text-muted)' }}>
            Pantau kapasitas slot antrean, jadwal dokter poli, dan keterisian kuota secara transparan.
          </p>
        </div>
        <button
          onClick={loadData}
          disabled={loading}
          className="btn btn-secondary"
          title="Segarkan data jadwal"
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
            placeholder="Cari dokter, poli spesialisasi, atau klinik..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        <div className="filter-pills">
          {[
            { id: 'all', label: 'Semua Status' },
            { id: 'available', label: 'Tersedia' },
            { id: 'full', label: 'Penuh' },
            { id: 'cancelled', label: 'Dibatalkan' },
          ].map((pill) => (
            <button
              key={pill.id}
              onClick={() => setStatusFilter(pill.id)}
              className={`filter-pill ${statusFilter === pill.id ? 'active' : ''}`}
            >
              {pill.label}
            </button>
          ))}
        </div>
      </div>

      {/* Schedules Table */}
      <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
        <div className="table-container" style={{ border: 'none' }}>
          <table className="data-table">
            <thead>
              <tr>
                <th>Dokter & Poli</th>
                <th>Klinik</th>
                <th>Tanggal Praktik</th>
                <th>Jam Praktik</th>
                <th>Kapasitas & Kuota Slot</th>
                <th>Status Slot</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: 'center', padding: '36px' }}>
                    <div style={{ color: 'var(--text-muted)', fontSize: '13.5px' }}>Memuat jadwal praktik...</div>
                  </td>
                </tr>
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan={6}>
                    <div className="empty-state">
                      <div className="empty-state-icon">
                        <Calendar size={24} />
                      </div>
                      <div className="empty-state-title">Tidak ada jadwal ditemukan</div>
                      <div className="empty-state-text">
                        Belum ada jadwal dokter yang cocok dengan filter atau kata kunci.
                      </div>
                    </div>
                  </td>
                </tr>
              ) : (
                filtered.map((sch) => {
                  const percentage = Math.min(100, Math.round((sch.booked_count / sch.capacity) * 100));
                  const fillColor = getCapacityColor(sch.booked_count, sch.capacity);

                  return (
                    <tr key={sch.id}>
                      <td>
                        <div style={{ fontWeight: 600 }}>{sch.doctor_name}</div>
                        <div style={{ fontSize: '12px', color: 'var(--primary)', fontWeight: 500 }}>
                          {sch.specialty_name}
                        </div>
                      </td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px' }}>
                          <Building size={14} style={{ color: 'var(--text-muted)' }} />
                          <span>{sch.clinic_name}</span>
                        </div>
                      </td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px' }}>
                          <Calendar size={14} style={{ color: 'var(--text-muted)' }} />
                          <span>{sch.schedule_date}</span>
                        </div>
                      </td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px' }}>
                          <Clock size={14} style={{ color: 'var(--text-muted)' }} />
                          <span>{sch.start_time} - {sch.end_time} WIB</span>
                        </div>
                      </td>
                      <td style={{ minWidth: '180px' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', marginBottom: '4px' }}>
                          <span style={{ fontWeight: 600 }}>{sch.booked_count} terisi</span>
                          <span style={{ color: 'var(--text-muted)' }}>Maks {sch.capacity} slot</span>
                        </div>
                        <div className="progress-bar-bg">
                          <div
                            className="progress-bar-fill"
                            style={{
                              width: `${percentage}%`,
                              backgroundColor: fillColor,
                            }}
                          />
                        </div>
                      </td>
                      <td>
                        {sch.status === 'available' ? (
                          <span className="badge badge-success">
                            <CheckCircle size={12} /> Tersedia ({sch.capacity - sch.booked_count} sisa)
                          </span>
                        ) : sch.status === 'full' ? (
                          <span className="badge badge-danger">
                            <AlertCircle size={12} /> Kuota Penuh
                          </span>
                        ) : (
                          <span className="badge badge-neutral">{sch.status}</span>
                        )}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
