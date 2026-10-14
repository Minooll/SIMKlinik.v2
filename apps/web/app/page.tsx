'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import {
  Users,
  Clock,
  CheckCircle2,
  CalendarDays,
  ArrowRight,
  Radio,
  FileSpreadsheet,
} from 'lucide-react';
import {
  getDashboardMetrics,
  getQueueTickets,
  getDoctorSchedules,
  QueueTicket,
  DoctorSchedule,
} from '../lib/supabase';

export default function DashboardPage() {
  const [metrics, setMetrics] = useState({
    totalPatientsToday: 0,
    activeQueueCount: 0,
    completedToday: 0,
    totalAppointments: 0,
  });
  const [tickets, setTickets] = useState<QueueTicket[]>([]);
  const [schedules, setSchedules] = useState<DoctorSchedule[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    async function loadData() {
      try {
        const [m, t, s] = await Promise.all([
          getDashboardMetrics(),
          getQueueTickets(),
          getDoctorSchedules(),
        ]);
        setMetrics(m);
        setTickets(t);
        setSchedules(s);
      } catch (err) {
        console.error('Error loading dashboard:', err);
      } finally {
        setIsLoading(false);
      }
    }
    loadData();
  }, []);

  const getStatusBadge = (status: QueueTicket['status']) => {
    switch (status) {
      case 'waiting':
        return <span className="badge badge-warning">Menunggu</span>;
      case 'checked_in':
        return <span className="badge badge-info">Sudah Check-In</span>;
      case 'called':
        return <span className="badge badge-warning" style={{ background: '#f3e8ff', color: '#7e22ce' }}>Dipanggil</span>;
      case 'in_service':
        return <span className="badge badge-info" style={{ background: '#e6f3f4', color: '#106369' }}>Dalam Pelayanan</span>;
      case 'completed':
        return <span className="badge badge-success">Selesai</span>;
      default:
        return <span className="badge badge-neutral">{status}</span>;
    }
  };

  return (
    <div>
      {/* Title Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px' }}>
        <div>
          <h1 style={{ fontSize: '22px', fontWeight: 700, color: 'var(--text-primary)' }}>
            Ringkasan Operasional Klinik
          </h1>
          <p style={{ fontSize: '13.5px', color: 'var(--text-secondary)' }}>
            Pantauan live antrean pasien, kapasitas slot dokter, dan status pelayanan hari ini.
          </p>
        </div>

        <div style={{ display: 'flex', gap: '10px' }}>
          <Link href="/queue" className="btn btn-primary">
            <Radio size={16} />
            <span>Buka Terminal Pemanggilan</span>
          </Link>
          <Link href="/appointments" className="btn btn-secondary">
            <FileSpreadsheet size={16} />
            <span>Lihat Semua Booking</span>
          </Link>
        </div>
      </div>

      {/* Metric Cards */}
      <div className="grid-metrics">
        <div className="metric-card">
          <div>
            <div className="metric-label">Pasien Antrean Hari Ini</div>
            <div className="metric-value">{metrics.totalPatientsToday}</div>
            <div className="metric-badge badge-info">Terbit Resmi</div>
          </div>
          <div className="metric-icon-box" style={{ background: 'var(--info-bg)', color: 'var(--info)' }}>
            <Users size={22} />
          </div>
        </div>

        <div className="metric-card">
          <div>
            <div className="metric-label">Antrean Aktif Berjalan</div>
            <div className="metric-value">{metrics.activeQueueCount}</div>
            <div className="metric-badge badge-warning">Perlu Diproses</div>
          </div>
          <div className="metric-icon-box" style={{ background: 'var(--warning-bg)', color: 'var(--warning)' }}>
            <Clock size={22} />
          </div>
        </div>

        <div className="metric-card">
          <div>
            <div className="metric-label">Pelayanan Selesai</div>
            <div className="metric-value">{metrics.completedToday}</div>
            <div className="metric-badge badge-success">Selesai Konsultasi</div>
          </div>
          <div className="metric-icon-box" style={{ background: 'var(--success-bg)', color: 'var(--success)' }}>
            <CheckCircle2 size={22} />
          </div>
        </div>

        <div className="metric-card">
          <div>
            <div className="metric-label">Reservasi Booking</div>
            <div className="metric-value">{metrics.totalAppointments}</div>
            <div className="metric-badge badge-neutral">Terkonfirmasi</div>
          </div>
          <div className="metric-icon-box" style={{ background: 'var(--primary-light)', color: 'var(--primary)' }}>
            <CalendarDays size={22} />
          </div>
        </div>
      </div>

      {/* Main Content Split: Live Queue Table & Schedules */}
      <div style={{ display: 'grid', gridTemplateColumns: '1.6fr 1fr', gap: '22px' }}>
        {/* Left: Next Patients to Call */}
        <div className="card">
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '16px' }}>
            <div>
              <h2 style={{ fontSize: '16px', fontWeight: 700, color: 'var(--text-primary)' }}>
                Urutan Antrean Teratas
              </h2>
              <p style={{ fontSize: '12.5px', color: 'var(--text-muted)' }}>
                Pasien yang sedang menunggu dan perlu dipanggil ke ruang dokter
              </p>
            </div>
            <Link href="/queue" style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '12.5px', color: 'var(--primary)', fontWeight: 600 }}>
              Terminal Lengkap <ArrowRight size={14} />
            </Link>
          </div>

          {isLoading ? (
            <div style={{ textAlign: 'center', padding: '36px', color: 'var(--text-muted)' }}>
              Memuat data antrean...
            </div>
          ) : tickets.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '36px', color: 'var(--text-muted)' }}>
              Belum ada antrean terdaftar hari ini.
            </div>
          ) : (
            <div className="table-container">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>No. Tiket</th>
                    <th>Nama Pasien</th>
                    <th>Dokter / Poli</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {tickets.slice(0, 5).map((ticket) => (
                    <tr key={ticket.id}>
                      <td>
                        <span style={{ fontWeight: 700, color: 'var(--primary)', fontSize: '14px' }}>
                          {ticket.ticket_code}
                        </span>
                      </td>
                      <td style={{ fontWeight: 600 }}>{ticket.patient_name}</td>
                      <td>
                        <div>{ticket.doctor_name}</div>
                        <div style={{ fontSize: '11.5px', color: 'var(--text-muted)' }}>{ticket.specialty_name}</div>
                      </td>
                      <td>{getStatusBadge(ticket.status)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Right: Doctor Schedule Occupancy */}
        <div className="card">
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '16px' }}>
            <h2 style={{ fontSize: '16px', fontWeight: 700, color: 'var(--text-primary)' }}>
              Kapasitas Jadwal Hari Ini
            </h2>
            <Link href="/schedules" style={{ fontSize: '12.5px', color: 'var(--primary)', fontWeight: 600 }}>
              Kelola Jadwal
            </Link>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            {schedules.map((sch) => {
              const percentage = Math.min(100, Math.round((sch.booked_count / sch.capacity) * 100));
              const isFull = sch.booked_count >= sch.capacity;

              return (
                <div
                  key={sch.id}
                  style={{
                    padding: '14px',
                    borderRadius: 'var(--radius-md)',
                    border: '1px solid var(--border)',
                    background: 'var(--bg)',
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '6px' }}>
                    <div>
                      <div style={{ fontSize: '13.5px', fontWeight: 600, color: 'var(--text-primary)' }}>
                        {sch.doctor_name}
                      </div>
                      <div style={{ fontSize: '12px', color: 'var(--primary)', fontWeight: 500 }}>
                        {sch.specialty_name} • {sch.start_time} - {sch.end_time} WIB
                      </div>
                    </div>
                    <span className={`badge ${isFull ? 'badge-danger' : 'badge-success'}`}>
                      {isFull ? 'Penuh' : `Sisa ${sch.capacity - sch.booked_count} slot`}
                    </span>
                  </div>

                  {/* Progress Bar */}
                  <div style={{ width: '100%', height: '6px', background: 'var(--border)', borderRadius: '9999px', overflow: 'hidden', marginTop: '8px' }}>
                    <div
                      style={{
                        width: `${percentage}%`,
                        height: '100%',
                        background: isFull ? 'var(--danger)' : 'var(--primary)',
                        borderRadius: '9999px',
                        transition: 'width 0.3s ease',
                      }}
                    />
                  </div>

                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '11px', color: 'var(--text-muted)', marginTop: '4px' }}>
                    <span>Terisi {sch.booked_count} pasien</span>
                    <span>Kapasitas {sch.capacity} slot ({percentage}%)</span>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}
