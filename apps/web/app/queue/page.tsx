'use client';

import React, { useEffect, useState } from 'react';
import {
  Users,
  Search,
  RefreshCw,
  Megaphone,
  CheckCircle,
  Play,
  SkipForward,
  Clock,
  QrCode,
  AlertCircle,
  Check,
} from 'lucide-react';
import {
  getQueueTickets,
  advanceQueueStatus,
  QueueTicket,
  isDemoMode,
} from '@/lib/supabase';

export default function QueueMonitorPage() {
  const [tickets, setTickets] = useState<QueueTicket[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const loadData = async () => {
    try {
      setLoading(true);
      const data = await getQueueTickets();
      setTickets(data);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Gagal memuat antrean';
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

  const handleStatusChange = async (ticketId: string, newStatus: QueueTicket['status']) => {
    try {
      setActionLoading(ticketId);
      const res = await advanceQueueStatus(ticketId, newStatus);
      showToast(res.message, 'success');
      await loadData();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Gagal mengubah status tiket';
      showToast(msg, 'error');
    } finally {
      setActionLoading(null);
    }
  };

  // Find the primary active ticket (called or in_service) or the next waiting ticket
  const currentActiveTicket =
    tickets.find((t) => t.status === 'in_service') ||
    tickets.find((t) => t.status === 'called') ||
    tickets.find((t) => t.status === 'checked_in') ||
    tickets.find((t) => t.status === 'waiting');

  const filteredTickets = tickets.filter((t) => {
    const matchesQuery =
      t.patient_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      t.ticket_code.toLowerCase().includes(searchQuery.toLowerCase()) ||
      t.doctor_name.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesStatus = statusFilter === 'all' ? true : t.status === statusFilter;
    return matchesQuery && matchesStatus;
  });

  const getStatusBadge = (status: QueueTicket['status']) => {
    switch (status) {
      case 'waiting':
        return <span className="badge badge-neutral"><Clock size={12} /> Menunggu</span>;
      case 'checked_in':
        return <span className="badge badge-info"><QrCode size={12} /> Hadir (QR)</span>;
      case 'called':
        return <span className="badge badge-warning"><Megaphone size={12} /> Dipanggil</span>;
      case 'in_service':
        return <span className="badge badge-success"><Play size={12} /> Sedang Dilayani</span>;
      case 'completed':
        return <span className="badge badge-success"><CheckCircle size={12} /> Selesai</span>;
      case 'skipped':
        return <span className="badge badge-danger"><SkipForward size={12} /> Dilewati</span>;
      default:
        return <span className="badge badge-neutral">{status}</span>;
    }
  };

  return (
    <div>
      {/* Page Title & Controls */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '22px' }}>
        <div>
          <h1 style={{ fontSize: '24px', fontWeight: 700, color: 'var(--text-primary)', letterSpacing: '-0.5px' }}>
            Live Queue Monitor
          </h1>
          <p style={{ fontSize: '13.5px', color: 'var(--text-muted)' }}>
            Terminal pemanggilan dan pengendali alur antrean pasien klinik real-time.
          </p>
        </div>
        <button
          onClick={loadData}
          disabled={loading}
          className="btn btn-secondary"
          title="Segarkan data antrean"
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

      {/* Primary Caller Board */}
      {currentActiveTicket && (
        <div className="queue-caller-board">
          <div className="current-ticket-card">
            <div>
              <div className="current-ticket-badge">
                <Megaphone size={12} /> Antrean Terkini
              </div>
              <div className="current-ticket-number">{currentActiveTicket.ticket_code}</div>
              <div className="current-ticket-patient">{currentActiveTicket.patient_name}</div>
              <div className="current-ticket-sub">{currentActiveTicket.specialty_name} • {currentActiveTicket.doctor_name}</div>
            </div>

            <div className="caller-actions">
              {currentActiveTicket.status !== 'called' && currentActiveTicket.status !== 'in_service' && (
                <button
                  onClick={() => handleStatusChange(currentActiveTicket.id, 'called')}
                  disabled={actionLoading === currentActiveTicket.id}
                  className="btn-terminal btn-terminal-call"
                >
                  <Megaphone size={14} /> Panggil
                </button>
              )}
              {currentActiveTicket.status === 'called' && (
                <button
                  onClick={() => handleStatusChange(currentActiveTicket.id, 'in_service')}
                  disabled={actionLoading === currentActiveTicket.id}
                  className="btn-terminal btn-terminal-serve"
                >
                  <Play size={14} /> Mulai Layanan
                </button>
              )}
              {currentActiveTicket.status === 'in_service' && (
                <button
                  onClick={() => handleStatusChange(currentActiveTicket.id, 'completed')}
                  disabled={actionLoading === currentActiveTicket.id}
                  className="btn-terminal btn-terminal-done"
                >
                  <CheckCircle size={14} /> Selesai
                </button>
              )}
              <button
                onClick={() => handleStatusChange(currentActiveTicket.id, 'skipped')}
                disabled={actionLoading === currentActiveTicket.id}
                className="btn-terminal btn-terminal-skip"
              >
                <SkipForward size={14} /> Lewati
              </button>
            </div>
          </div>

          {/* Quick Queue Stats Panel */}
          <div className="card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
            <div>
              <h3 style={{ fontSize: '15px', fontWeight: 600, marginBottom: '14px', color: 'var(--text-primary)' }}>
                Ringkasan Antrean Sesi Hari Ini
              </h3>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '12px' }}>
                <div style={{ padding: '12px', background: 'var(--bg)', borderRadius: 'var(--radius-md)', textAlign: 'center' }}>
                  <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Menunggu / Hadir</div>
                  <div style={{ fontSize: '22px', fontWeight: 700, color: 'var(--text-primary)' }}>
                    {tickets.filter((t) => ['waiting', 'checked_in'].includes(t.status)).length}
                  </div>
                </div>
                <div style={{ padding: '12px', background: 'var(--primary-light)', borderRadius: 'var(--radius-md)', textAlign: 'center' }}>
                  <div style={{ fontSize: '12px', color: 'var(--primary)', fontWeight: 600 }}>Dipanggil / Layanan</div>
                  <div style={{ fontSize: '22px', fontWeight: 700, color: 'var(--primary)' }}>
                    {tickets.filter((t) => ['called', 'in_service'].includes(t.status)).length}
                  </div>
                </div>
                <div style={{ padding: '12px', background: 'var(--success-bg)', borderRadius: 'var(--radius-md)', textAlign: 'center' }}>
                  <div style={{ fontSize: '12px', color: 'var(--success)', fontWeight: 600 }}>Selesai Berobat</div>
                  <div style={{ fontSize: '22px', fontWeight: 700, color: 'var(--success)' }}>
                    {tickets.filter((t) => t.status === 'completed').length}
                  </div>
                </div>
              </div>
            </div>

            <div style={{ marginTop: '16px', padding: '12px', background: 'var(--bg)', borderRadius: 'var(--radius-md)', fontSize: '12.5px', color: 'var(--text-secondary)' }}>
              <strong>Keterangan Alur:</strong> Pasien hadir melakukan scan QR Check-in → Petugas/Dokter memanggil nomor → Mulai konsultasi medis → Status ditandai selesai.
            </div>
          </div>
        </div>
      )}

      {/* Filter and Search Bar */}
      <div className="filter-bar">
        <div className="search-input-wrapper">
          <Search size={16} />
          <input
            type="text"
            className="input-search"
            placeholder="Cari nomor tiket, nama pasien, dokter..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        <div className="filter-pills">
          {[
            { id: 'all', label: 'Semua Status' },
            { id: 'waiting', label: 'Menunggu' },
            { id: 'checked_in', label: 'Hadir (QR)' },
            { id: 'called', label: 'Dipanggil' },
            { id: 'in_service', label: 'Dilayani' },
            { id: 'completed', label: 'Selesai' },
            { id: 'skipped', label: 'Dilewati' },
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

      {/* Tickets Table */}
      <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
        <div className="table-container" style={{ border: 'none' }}>
          <table className="data-table">
            <thead>
              <tr>
                <th style={{ width: '90px' }}>No. Tiket</th>
                <th>Pasien</th>
                <th>Dokter & Poli</th>
                <th>Status</th>
                <th>Waktu Hadir</th>
                <th style={{ textAlign: 'right' }}>Aksi Terminal</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: 'center', padding: '36px' }}>
                    <div style={{ color: 'var(--text-muted)', fontSize: '13.5px' }}>Memuat daftar antrean...</div>
                  </td>
                </tr>
              ) : filteredTickets.length === 0 ? (
                <tr>
                  <td colSpan={6}>
                    <div className="empty-state">
                      <div className="empty-state-icon">
                        <Users size={24} />
                      </div>
                      <div className="empty-state-title">Tidak ada antrean ditemukan</div>
                      <div className="empty-state-text">
                        Tidak ada data antrean yang cocok dengan kriteria filter atau pencarian saat ini.
                      </div>
                    </div>
                  </td>
                </tr>
              ) : (
                filteredTickets.map((ticket) => (
                  <tr key={ticket.id}>
                    <td>
                      <span style={{ fontWeight: 700, fontSize: '14px', color: 'var(--primary)' }}>
                        {ticket.ticket_code}
                      </span>
                    </td>
                    <td>
                      <div style={{ fontWeight: 600 }}>{ticket.patient_name}</div>
                      <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>Token: {ticket.qr_token}</div>
                    </td>
                    <td>
                      <div>{ticket.doctor_name}</div>
                      <div style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>{ticket.specialty_name}</div>
                    </td>
                    <td>{getStatusBadge(ticket.status)}</td>
                    <td style={{ fontSize: '12.5px', color: 'var(--text-secondary)' }}>
                      {ticket.checked_in_at ? new Date(ticket.checked_in_at).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) : '-'}
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <div style={{ display: 'inline-flex', gap: '6px' }}>
                        {ticket.status !== 'called' && ticket.status !== 'in_service' && ticket.status !== 'completed' && (
                          <button
                            onClick={() => handleStatusChange(ticket.id, 'called')}
                            disabled={actionLoading === ticket.id}
                            className="btn btn-secondary btn-sm"
                            title="Panggil pasien"
                          >
                            <Megaphone size={12} /> Panggil
                          </button>
                        )}
                        {ticket.status === 'called' && (
                          <button
                            onClick={() => handleStatusChange(ticket.id, 'in_service')}
                            disabled={actionLoading === ticket.id}
                            className="btn btn-primary btn-sm"
                            title="Mulai pemeriksaan"
                          >
                            <Play size={12} /> Layani
                          </button>
                        )}
                        {ticket.status === 'in_service' && (
                          <button
                            onClick={() => handleStatusChange(ticket.id, 'completed')}
                            disabled={actionLoading === ticket.id}
                            className="btn btn-primary btn-sm"
                            style={{ background: 'var(--success)' }}
                            title="Selesaikan kunjungan"
                          >
                            <CheckCircle size={12} /> Selesai
                          </button>
                        )}
                        {ticket.status !== 'completed' && ticket.status !== 'skipped' && (
                          <button
                            onClick={() => handleStatusChange(ticket.id, 'skipped')}
                            disabled={actionLoading === ticket.id}
                            className="btn btn-danger btn-sm"
                            title="Lewati antrean"
                          >
                            <SkipForward size={12} /> Lewati
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
