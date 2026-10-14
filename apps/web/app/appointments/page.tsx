'use client';

import React, { useEffect, useState } from 'react';
import {
  CalendarCheck,
  Search,
  RefreshCw,
  XCircle,
  CheckCircle,
  Clock,
  User,
  AlertTriangle,
  X,
  Check,
  AlertCircle,
} from 'lucide-react';
import {
  getAppointments,
  cancelAppointment,
  Appointment,
} from '@/lib/supabase';

export default function AppointmentsPage() {
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [selectedAppointment, setSelectedAppointment] = useState<Appointment | null>(null);
  const [cancelReason, setCancelReason] = useState('');
  const [submittingCancel, setSubmittingCancel] = useState(false);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const loadData = async () => {
    try {
      setLoading(true);
      const data = await getAppointments();
      setAppointments(data);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Gagal memuat reservasi';
      showToast(msg, 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const showToast = (message: string, type: 'success' | 'error') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 4000);
  };

  const handleConfirmCancel = async () => {
    if (!selectedAppointment) return;
    if (!cancelReason.trim()) {
      showToast('Mohon masukkan alasan pembatalan.', 'error');
      return;
    }

    try {
      setSubmittingCancel(true);
      const res = await cancelAppointment(selectedAppointment.id, cancelReason);
      showToast(res.message, 'success');
      setSelectedAppointment(null);
      setCancelReason('');
      await loadData();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Gagal membatalkan reservasi';
      showToast(msg, 'error');
    } finally {
      setSubmittingCancel(false);
    }
  };

  const filtered = appointments.filter((apt) => {
    const matchesQuery =
      apt.booking_reference.toLowerCase().includes(searchQuery.toLowerCase()) ||
      apt.patient_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      apt.patient_nik.includes(searchQuery) ||
      apt.doctor_name.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesStatus = statusFilter === 'all' ? true : apt.status === statusFilter;
    return matchesQuery && matchesStatus;
  });

  const getStatusBadge = (status: Appointment['status']) => {
    switch (status) {
      case 'confirmed':
        return <span className="badge badge-info"><CheckCircle size={12} /> Terkonfirmasi</span>;
      case 'completed':
        return <span className="badge badge-success"><CheckCircle size={12} /> Selesai</span>;
      case 'cancelled':
        return <span className="badge badge-danger"><XCircle size={12} /> Dibatalkan</span>;
      case 'no_show':
        return <span className="badge badge-warning"><AlertTriangle size={12} /> Tidak Hadir</span>;
      default:
        return <span className="badge badge-neutral">{status}</span>;
    }
  };

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '22px' }}>
        <div>
          <h1 style={{ fontSize: '24px', fontWeight: 700, color: 'var(--text-primary)', letterSpacing: '-0.5px' }}>
            Manajemen Reservasi & Janji Temu
          </h1>
          <p style={{ fontSize: '13.5px', color: 'var(--text-muted)' }}>
            Daftar seluruh booking janji temu pasien, status kehadiran, dan riwayat pembatalan.
          </p>
        </div>
        <button
          onClick={loadData}
          disabled={loading}
          className="btn btn-secondary"
          title="Segarkan daftar reservasi"
        >
          <RefreshCw size={15} className={loading ? 'animate-spin' : ''} />
          <span>Refresh</span>
        </button>
      </div>

      {/* Toast Alert */}
      {toast && (
        <div className={`toast-alert ${toast.type === 'success' ? 'toast-success' : 'toast-error'}`}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            {toast.type === 'success' ? <Check size={16} /> : <AlertCircle size={16} />}
            <span>{toast.message}</span>
          </div>
          <button onClick={() => setToast(null)} style={{ color: 'inherit', fontWeight: 'bold' }}>×</button>
        </div>
      )}

      {/* Filter and Search */}
      <div className="filter-bar">
        <div className="search-input-wrapper">
          <Search size={16} />
          <input
            type="text"
            className="input-search"
            placeholder="Cari ref booking, pasien, NIK, dokter..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        <div className="filter-pills">
          {[
            { id: 'all', label: 'Semua Status' },
            { id: 'confirmed', label: 'Terkonfirmasi' },
            { id: 'completed', label: 'Selesai' },
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

      {/* Appointments Table */}
      <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
        <div className="table-container" style={{ border: 'none' }}>
          <table className="data-table">
            <thead>
              <tr>
                <th>Ref Booking</th>
                <th>Pasien & NIK</th>
                <th>Dokter & Poli</th>
                <th>Jadwal Pelayanan</th>
                <th>Status</th>
                <th>Catatan / Keluhan</th>
                <th style={{ textAlign: 'right' }}>Aksi</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={7} style={{ textAlign: 'center', padding: '36px' }}>
                    <div style={{ color: 'var(--text-muted)', fontSize: '13.5px' }}>Memuat daftar reservasi...</div>
                  </td>
                </tr>
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan={7}>
                    <div className="empty-state">
                      <div className="empty-state-icon">
                        <CalendarCheck size={24} />
                      </div>
                      <div className="empty-state-title">Tidak ada reservasi ditemukan</div>
                      <div className="empty-state-text">
                        Belum ada reservasi yang cocok dengan kata kunci pencarian atau filter status.
                      </div>
                    </div>
                  </td>
                </tr>
              ) : (
                filtered.map((apt) => (
                  <tr key={apt.id}>
                    <td>
                      <span style={{ fontWeight: 600, color: 'var(--primary)', fontFamily: 'monospace' }}>
                        {apt.booking_reference}
                      </span>
                    </td>
                    <td>
                      <div style={{ fontWeight: 600 }}>{apt.patient_name}</div>
                      <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>NIK: {apt.patient_nik}</div>
                    </td>
                    <td>
                      <div>{apt.doctor_name}</div>
                      <div style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>{apt.specialty_name}</div>
                    </td>
                    <td>
                      <div>{apt.schedule_date}</div>
                      <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>{apt.schedule_time}</div>
                    </td>
                    <td>{getStatusBadge(apt.status)}</td>
                    <td style={{ maxWidth: '200px', fontSize: '12.5px', color: 'var(--text-secondary)' }}>
                      {apt.notes || '-'}
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      {apt.status === 'confirmed' ? (
                        <button
                          onClick={() => setSelectedAppointment(apt)}
                          className="btn btn-danger btn-sm"
                          title="Batalkan reservasi"
                        >
                          <XCircle size={13} /> Batalkan
                        </button>
                      ) : (
                        <span style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Tidak ada aksi</span>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Cancellation Confirmation Dialog */}
      {selectedAppointment && (
        <div className="modal-backdrop">
          <div className="modal-card">
            <div className="modal-header">
              <h3>Konfirmasi Pembatalan Reservasi</h3>
              <button
                onClick={() => setSelectedAppointment(null)}
                style={{ color: 'var(--text-muted)' }}
              >
                <X size={18} />
              </button>
            </div>
            <div className="modal-body">
              <p style={{ fontSize: '13.5px', color: 'var(--text-secondary)' }}>
                Apakah Anda yakin ingin membatalkan reservasi untuk{' '}
                <strong>{selectedAppointment.patient_name}</strong> (
                <span style={{ fontFamily: 'monospace' }}>{selectedAppointment.booking_reference}</span>)?
              </p>

              <div>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, marginBottom: '6px' }}>
                  Alasan Pembatalan <span style={{ color: 'var(--danger)' }}>*</span>
                </label>
                <textarea
                  className="input-text"
                  rows={3}
                  placeholder="Contoh: Pasien berhalangan hadir / Permintaan dokter jadwal dialihkan..."
                  value={cancelReason}
                  onChange={(e) => setCancelReason(e.target.value)}
                  style={{ width: '100%', resize: 'none' }}
                />
              </div>

              <div style={{ padding: '10px 14px', background: 'var(--warning-bg)', borderRadius: 'var(--radius-md)', fontSize: '12px', color: 'var(--warning)' }}>
                Pembatalan ini akan mengembalikan kuota slot jadwal dokter secara atomik dan mencatat riwayat audit.
              </div>
            </div>
            <div className="modal-footer">
              <button
                onClick={() => setSelectedAppointment(null)}
                className="btn btn-secondary"
                disabled={submittingCancel}
              >
                Batal
              </button>
              <button
                onClick={handleConfirmCancel}
                className="btn btn-danger"
                disabled={submittingCancel || !cancelReason.trim()}
              >
                {submittingCancel ? 'Memproses...' : 'Ya, Batalkan Reservasi'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
