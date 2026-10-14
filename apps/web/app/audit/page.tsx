'use client';

import React, { useEffect, useState } from 'react';
import {
  ShieldAlert,
  Search,
  RefreshCw,
  Code,
  Eye,
  User,
  Clock,
  Database,
  X,
  FileCheck,
} from 'lucide-react';
import { getAuditLogs, AuditLog } from '@/lib/supabase';

export default function AuditTrailPage() {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [actionFilter, setActionFilter] = useState<string>('all');
  const [selectedLog, setSelectedLog] = useState<AuditLog | null>(null);

  const loadData = async () => {
    try {
      setLoading(true);
      const data = await getAuditLogs();
      setLogs(data);
    } catch (err: unknown) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const actionTypes = ['all', ...Array.from(new Set(logs.map((l) => l.action)))];

  const filtered = logs.filter((log) => {
    const matchesQuery =
      log.action.toLowerCase().includes(searchQuery.toLowerCase()) ||
      log.actor_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      log.resource_type.toLowerCase().includes(searchQuery.toLowerCase()) ||
      log.resource_id.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesAction = actionFilter === 'all' ? true : log.action === actionFilter;
    return matchesQuery && matchesAction;
  });

  const getActionBadge = (action: string) => {
    if (action.includes('ADVANCE_QUEUE')) {
      return <span className="badge badge-info">{action}</span>;
    }
    if (action.includes('BOOK')) {
      return <span className="badge badge-success">{action}</span>;
    }
    if (action.includes('CANCEL')) {
      return <span className="badge badge-danger">{action}</span>;
    }
    if (action.includes('CHECK_IN')) {
      return <span className="badge badge-warning">{action}</span>;
    }
    return <span className="badge badge-neutral">{action}</span>;
  };

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '22px' }}>
        <div>
          <h1 style={{ fontSize: '24px', fontWeight: 700, color: 'var(--text-primary)', letterSpacing: '-0.5px' }}>
            Audit Trail & Log Keamanan
          </h1>
          <p style={{ fontSize: '13.5px', color: 'var(--text-muted)' }}>
            Rekaman aktivitas mutasi data medis, pergeseran antrean, booking, dan pembatalan dengan metadata aktor.
          </p>
        </div>
        <button
          onClick={loadData}
          disabled={loading}
          className="btn btn-secondary"
          title="Segarkan log audit"
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
            placeholder="Cari aksi, nama aktor, resource ID..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        <div className="filter-pills">
          {actionTypes.map((action) => (
            <button
              key={action}
              onClick={() => setActionFilter(action)}
              className={`filter-pill ${actionFilter === action ? 'active' : ''}`}
            >
              {action === 'all' ? 'Semua Aksi' : action}
            </button>
          ))}
        </div>
      </div>

      {/* Audit Log Table */}
      <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
        <div className="table-container" style={{ border: 'none' }}>
          <table className="data-table">
            <thead>
              <tr>
                <th>Waktu Log</th>
                <th>Aksi Sistem / RPC</th>
                <th>Aktor Pelaksana</th>
                <th>Tipe Entitas</th>
                <th>Resource ID</th>
                <th style={{ textAlign: 'right' }}>Payload JSON</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: 'center', padding: '36px' }}>
                    <div style={{ color: 'var(--text-muted)', fontSize: '13.5px' }}>Memuat rekam jejak audit...</div>
                  </td>
                </tr>
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan={6}>
                    <div className="empty-state">
                      <div className="empty-state-icon">
                        <ShieldAlert size={24} />
                      </div>
                      <div className="empty-state-title">Tidak ada catatan audit</div>
                      <div className="empty-state-text">
                        Tidak ada log audit yang cocok dengan kata kunci pencarian.
                      </div>
                    </div>
                  </td>
                </tr>
              ) : (
                filtered.map((log) => (
                  <tr key={log.id}>
                    <td>
                      <div style={{ fontSize: '12.5px', color: 'var(--text-primary)', fontWeight: 500 }}>
                        {new Date(log.created_at).toLocaleDateString('id-ID')}
                      </div>
                      <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>
                        {new Date(log.created_at).toLocaleTimeString('id-ID')}
                      </div>
                    </td>
                    <td>{getActionBadge(log.action)}</td>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px', fontWeight: 600 }}>
                        <User size={13} style={{ color: 'var(--text-muted)' }} />
                        <span>{log.actor_name}</span>
                      </div>
                    </td>
                    <td>
                      <span style={{ fontSize: '12.5px', color: 'var(--text-secondary)', fontFamily: 'monospace' }}>
                        {log.resource_type}
                      </span>
                    </td>
                    <td>
                      <span style={{ fontSize: '12.5px', color: 'var(--text-muted)', fontFamily: 'monospace' }}>
                        {log.resource_id}
                      </span>
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <button
                        onClick={() => setSelectedLog(log)}
                        className="btn btn-secondary btn-sm"
                        title="Lihat rincian payload data"
                      >
                        <Eye size={12} /> Detail
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* JSON Payload Modal */}
      {selectedLog && (
        <div className="modal-backdrop">
          <div className="modal-card" style={{ maxWidth: '580px' }}>
            <div className="modal-header">
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Code size={18} style={{ color: 'var(--primary)' }} />
                <h3>Payload Data Audit: {selectedLog.action}</h3>
              </div>
              <button
                onClick={() => setSelectedLog(null)}
                style={{ color: 'var(--text-muted)' }}
              >
                <X size={18} />
              </button>
            </div>
            <div className="modal-body">
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', fontSize: '12.5px', padding: '12px', background: 'var(--bg)', borderRadius: 'var(--radius-md)' }}>
                <div><strong>Aktor:</strong> {selectedLog.actor_name}</div>
                <div><strong>Waktu:</strong> {new Date(selectedLog.created_at).toLocaleString('id-ID')}</div>
                <div><strong>Resource:</strong> {selectedLog.resource_type}</div>
                <div><strong>ID:</strong> {selectedLog.resource_id}</div>
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: 'var(--text-muted)', marginBottom: '6px' }}>
                  RAW JSON PAYLOAD
                </label>
                <pre
                  style={{
                    background: '#0f172a',
                    color: '#38bdf8',
                    padding: '14px',
                    borderRadius: 'var(--radius-md)',
                    fontSize: '12px',
                    fontFamily: 'monospace',
                    overflowX: 'auto',
                    maxHeight: '260px',
                  }}
                >
                  {JSON.stringify(selectedLog.payload, null, 2)}
                </pre>
              </div>
            </div>
            <div className="modal-footer">
              <button onClick={() => setSelectedLog(null)} className="btn btn-primary">
                Tutup
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
