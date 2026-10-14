import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';

export const isLiveConfigured = Boolean(supabaseUrl && supabaseAnonKey);
export const isDemoMode = !isLiveConfigured;

export const supabase = isLiveConfigured
  ? createClient(supabaseUrl, supabaseAnonKey)
  : null;

// ==============================================================================
// Mock Data Store for Demo Mode (Strictly mirrors seed.sql & migrations)
// ==============================================================================
export interface Doctor {
  id: string;
  full_name: string;
  specialty_name: string;
  sip_number: string;
  phone: string;
  bio: string;
  is_active: boolean;
}

export interface DoctorSchedule {
  id: string;
  doctor_id: string;
  doctor_name: string;
  specialty_name: string;
  clinic_name: string;
  schedule_date: string;
  start_time: string;
  end_time: string;
  capacity: number;
  booked_count: number;
  status: 'available' | 'full' | 'cancelled' | 'completed';
}

export interface QueueTicket {
  id: string;
  ticket_number: number;
  ticket_code: string;
  patient_name: string;
  doctor_name: string;
  specialty_name: string;
  status: 'waiting' | 'checked_in' | 'called' | 'in_service' | 'completed' | 'skipped' | 'cancelled';
  qr_token: string;
  checked_in_at: string | null;
  called_at: string | null;
  started_at: string | null;
  completed_at: string | null;
  created_at: string;
}

export interface Appointment {
  id: string;
  booking_reference: string;
  patient_name: string;
  patient_nik: string;
  doctor_name: string;
  specialty_name: string;
  schedule_date: string;
  schedule_time: string;
  status: 'confirmed' | 'cancelled' | 'completed' | 'no_show';
  notes: string | null;
  created_at: string;
}

export interface AuditLog {
  id: string;
  action: string;
  actor_name: string;
  resource_type: string;
  resource_id: string;
  payload: Record<string, unknown>;
  created_at: string;
}

// In-Memory store
const mockSchedules: DoctorSchedule[] = [
  {
    id: 'sch-1',
    doctor_id: 'd1',
    doctor_name: 'dr. Budi Santoso',
    specialty_name: 'Poli Umum',
    clinic_name: 'Klinik Pratama Sehat Harmoni',
    schedule_date: new Date().toISOString().split('T')[0],
    start_time: '08:00',
    end_time: '11:00',
    capacity: 10,
    booked_count: 7,
    status: 'available',
  },
  {
    id: 'sch-2',
    doctor_id: 'd2',
    doctor_name: 'drg. Siti Rahmawati',
    specialty_name: 'Poli Gigi & Mulut',
    clinic_name: 'Klinik Pratama Sehat Harmoni',
    schedule_date: new Date().toISOString().split('T')[0],
    start_time: '13:00',
    end_time: '16:00',
    capacity: 8,
    booked_count: 8,
    status: 'full',
  },
  {
    id: 'sch-3',
    doctor_id: 'd3',
    doctor_name: 'dr. Maya Kartika, Sp.A',
    specialty_name: 'Poli Anak (Pediatri)',
    clinic_name: 'Klinik Pratama Sehat Harmoni',
    schedule_date: new Date().toISOString().split('T')[0],
    start_time: '09:00',
    end_time: '12:00',
    capacity: 8,
    booked_count: 5,
    status: 'available',
  },
  {
    id: 'sch-4',
    doctor_id: 'd4',
    doctor_name: 'dr. Andi Wijaya, Sp.PD',
    specialty_name: 'Poli Penyakit Dalam',
    clinic_name: 'Klinik Pratama Sehat Harmoni',
    schedule_date: new Date().toISOString().split('T')[0],
    start_time: '16:00',
    end_time: '19:00',
    capacity: 6,
    booked_count: 2,
    status: 'available',
  },
];

const mockTickets: QueueTicket[] = [
  {
    id: 'qt-1',
    ticket_number: 1,
    ticket_code: 'A-001',
    patient_name: 'Dewi Lestari',
    doctor_name: 'dr. Budi Santoso',
    specialty_name: 'Poli Umum',
    status: 'completed',
    qr_token: 'QR-DEMO-001',
    checked_in_at: '2026-10-14T08:05:00Z',
    called_at: '2026-10-14T08:15:00Z',
    started_at: '2026-10-14T08:18:00Z',
    completed_at: '2026-10-14T08:35:00Z',
    created_at: '2026-10-14T07:45:00Z',
  },
  {
    id: 'qt-2',
    ticket_number: 2,
    ticket_code: 'A-002',
    patient_name: 'Bambang Supriyanto',
    doctor_name: 'dr. Budi Santoso',
    specialty_name: 'Poli Umum',
    status: 'in_service',
    qr_token: 'QR-DEMO-002',
    checked_in_at: '2026-10-14T08:20:00Z',
    called_at: '2026-10-14T08:38:00Z',
    started_at: '2026-10-14T08:40:00Z',
    completed_at: null,
    created_at: '2026-10-14T07:50:00Z',
  },
  {
    id: 'qt-3',
    ticket_number: 3,
    ticket_code: 'A-003',
    patient_name: 'Ahmad Fauzi',
    doctor_name: 'dr. Budi Santoso',
    specialty_name: 'Poli Umum',
    status: 'called',
    qr_token: 'QR-DEMO-003',
    checked_in_at: '2026-10-14T08:30:00Z',
    called_at: '2026-10-14T08:55:00Z',
    started_at: null,
    completed_at: null,
    created_at: '2026-10-14T08:00:00Z',
  },
  {
    id: 'qt-4',
    ticket_number: 4,
    ticket_code: 'A-004',
    patient_name: 'Rina Wulandari',
    doctor_name: 'dr. Budi Santoso',
    specialty_name: 'Poli Umum',
    status: 'checked_in',
    qr_token: 'QR-DEMO-004',
    checked_in_at: '2026-10-14T08:45:00Z',
    called_at: null,
    started_at: null,
    completed_at: null,
    created_at: '2026-10-14T08:10:00Z',
  },
  {
    id: 'qt-5',
    ticket_number: 5,
    ticket_code: 'A-005',
    patient_name: 'Hendra Gunawan',
    doctor_name: 'dr. Budi Santoso',
    specialty_name: 'Poli Umum',
    status: 'waiting',
    qr_token: 'QR-DEMO-005',
    checked_in_at: null,
    called_at: null,
    started_at: null,
    completed_at: null,
    created_at: '2026-10-14T08:20:00Z',
  },
];

const mockAppointments: Appointment[] = [
  {
    id: 'apt-1',
    booking_reference: 'APT-20261014-DEWI',
    patient_name: 'Dewi Lestari',
    patient_nik: '3171015502900001',
    doctor_name: 'dr. Budi Santoso',
    specialty_name: 'Poli Umum',
    schedule_date: '2026-10-14',
    schedule_time: '08:00 - 11:00 WIB',
    status: 'completed',
    notes: 'Pusing kepala dan flu ringan',
    created_at: '2026-10-13T10:15:00Z',
  },
  {
    id: 'apt-2',
    booking_reference: 'APT-20261014-BAMG',
    patient_name: 'Bambang Supriyanto',
    patient_nik: '3171011203850002',
    doctor_name: 'dr. Budi Santoso',
    specialty_name: 'Poli Umum',
    schedule_date: '2026-10-14',
    schedule_time: '08:00 - 11:00 WIB',
    status: 'confirmed',
    notes: 'Pemeriksaan tensi rutin',
    created_at: '2026-10-13T11:20:00Z',
  },
  {
    id: 'apt-3',
    booking_reference: 'APT-20261014-FAUZ',
    patient_name: 'Ahmad Fauzi',
    patient_nik: '3171012345670001',
    doctor_name: 'dr. Budi Santoso',
    specialty_name: 'Poli Umum',
    schedule_date: '2026-10-14',
    schedule_time: '08:00 - 11:00 WIB',
    status: 'confirmed',
    notes: 'Batuk kering sejak 3 hari',
    created_at: '2026-10-13T14:30:00Z',
  },
];

const mockAuditLogs: AuditLog[] = [
  {
    id: 'log-1',
    action: 'ADVANCE_QUEUE_TICKET',
    actor_name: 'dr. Budi Santoso',
    resource_type: 'queue_ticket',
    resource_id: 'qt-3',
    payload: { previous_status: 'checked_in', new_status: 'called', ticket_code: 'A-003' },
    created_at: '2026-10-14T08:55:00Z',
  },
  {
    id: 'log-2',
    action: 'CHECK_IN_QR',
    actor_name: 'Petugas Front Desk',
    resource_type: 'queue_ticket',
    resource_id: 'qt-4',
    payload: { ticket_code: 'A-004', method: 'kiosk_qr_scan' },
    created_at: '2026-10-14T08:45:00Z',
  },
  {
    id: 'log-3',
    action: 'BOOK_APPOINTMENT_ATOMIC',
    actor_name: 'Ahmad Fauzi (Pasien)',
    resource_type: 'appointment',
    resource_id: 'apt-3',
    payload: { booking_ref: 'APT-20261014-FAUZ', slot: '08:00' },
    created_at: '2026-10-13T14:30:00Z',
  },
];

// ==============================================================================
// Admin API Methods
// ==============================================================================
export async function getDashboardMetrics() {
  if (isLiveConfigured && supabase) {
    const { count: totalTickets } = await supabase.from('queue_tickets').select('*', { count: 'exact', head: true });
    const { count: waitingCount } = await supabase.from('queue_tickets').select('*', { count: 'exact', head: true }).eq('status', 'waiting');
    const { count: completedCount } = await supabase.from('queue_tickets').select('*', { count: 'exact', head: true }).eq('status', 'completed');
    const { count: totalAppointments } = await supabase.from('appointments').select('*', { count: 'exact', head: true });

    return {
      totalPatientsToday: totalTickets || 0,
      activeQueueCount: waitingCount || 0,
      completedToday: completedCount || 0,
      totalAppointments: totalAppointments || 0,
    };
  }

  // Demo fallback
  return {
    totalPatientsToday: mockTickets.length,
    activeQueueCount: mockTickets.filter((t) => ['waiting', 'checked_in', 'called'].includes(t.status)).length,
    completedToday: mockTickets.filter((t) => t.status === 'completed').length,
    totalAppointments: mockAppointments.length,
  };
}

export async function getQueueTickets(): Promise<QueueTicket[]> {
  if (isLiveConfigured && supabase) {
    const { data, error } = await supabase
      .from('queue_tickets')
      .select('*, patient_profiles(full_name), queue_sessions(doctors(full_name, specialties(name)))')
      .order('ticket_number', { ascending: true });

    if (error) throw error;
    return (data || []).map((t) => ({
      id: t.id,
      ticket_number: t.ticket_number,
      ticket_code: t.ticket_code,
      patient_name: t.patient_profiles?.full_name || 'Pasien',
      doctor_name: t.queue_sessions?.doctors?.full_name || 'Dokter',
      specialty_name: t.queue_sessions?.doctors?.specialties?.name || 'Poli Umum',
      status: t.status,
      qr_token: t.qr_token,
      checked_in_at: t.checked_in_at,
      called_at: t.called_at,
      started_at: t.started_at,
      completed_at: t.completed_at,
      created_at: t.created_at,
    }));
  }

  return [...mockTickets];
}

export async function advanceQueueStatus(
  ticketId: string,
  newStatus: QueueTicket['status'],
  reason?: string
): Promise<{ success: boolean; message: string }> {
  if (isLiveConfigured && supabase) {
    const { data, error } = await supabase.rpc('advance_queue_ticket', {
      p_ticket_id: ticketId,
      p_new_status: newStatus,
      p_reason: reason || null,
    });
    if (error) throw error;
    return { success: true, message: data?.message || 'Status berhasil diubah' };
  }

  // Demo mutation
  const ticket = mockTickets.find((t) => t.id === ticketId);
  if (!ticket) throw new Error('Tiket tidak ditemukan');

  const oldStatus = ticket.status;
  ticket.status = newStatus;
  const now = new Date().toISOString();
  if (newStatus === 'called') ticket.called_at = now;
  if (newStatus === 'in_service') ticket.started_at = now;
  if (newStatus === 'completed') ticket.completed_at = now;

  mockAuditLogs.unshift({
    id: `log-${Date.now()}`,
    action: 'ADVANCE_QUEUE_TICKET',
    actor_name: 'Admin / Petugas (Web)',
    resource_type: 'queue_ticket',
    resource_id: ticketId,
    payload: { previous_status: oldStatus, new_status: newStatus, reason },
    created_at: now,
  });

  return { success: true, message: `Status tiket ${ticket.ticket_code} berhasil diubah ke ${newStatus}.` };
}

export async function getAppointments(): Promise<Appointment[]> {
  if (isLiveConfigured && supabase) {
    const { data, error } = await supabase
      .from('appointments')
      .select('*, patient_profiles(full_name, nik), doctor_schedules(schedule_date, start_time, end_time, doctors(full_name, specialties(name)))')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return (data || []).map((a) => ({
      id: a.id,
      booking_reference: a.booking_reference,
      patient_name: a.patient_profiles?.full_name || 'Pasien',
      patient_nik: a.patient_profiles?.nik || '-',
      doctor_name: a.doctor_schedules?.doctors?.full_name || 'Dokter',
      specialty_name: a.doctor_schedules?.doctors?.specialties?.name || 'Poli',
      schedule_date: a.doctor_schedules?.schedule_date || '',
      schedule_time: `${a.doctor_schedules?.start_time || ''} - ${a.doctor_schedules?.end_time || ''}`,
      status: a.status,
      notes: a.notes,
      created_at: a.created_at,
    }));
  }

  return [...mockAppointments];
}

export async function cancelAppointment(
  appointmentId: string,
  reason: string
): Promise<{ success: boolean; message: string }> {
  if (isLiveConfigured && supabase) {
    const { data, error } = await supabase.rpc('cancel_appointment_atomic', {
      p_appointment_id: appointmentId,
      p_reason: reason,
    });
    if (error) throw error;
    return { success: true, message: data?.message || 'Reservasi berhasil dibatalkan.' };
  }

  const apt = mockAppointments.find((a) => a.id === appointmentId);
  if (!apt) throw new Error('Data reservasi tidak ditemukan');
  apt.status = 'cancelled';

  mockAuditLogs.unshift({
    id: `log-${Date.now()}`,
    action: 'CANCEL_APPOINTMENT_ATOMIC',
    actor_name: 'Petugas Admin',
    resource_type: 'appointment',
    resource_id: appointmentId,
    payload: { reason, booking_reference: apt.booking_reference },
    created_at: new Date().toISOString(),
  });

  return { success: true, message: `Reservasi ${apt.booking_reference} berhasil dibatalkan.` };
}

export async function getDoctorSchedules(): Promise<DoctorSchedule[]> {
  if (isLiveConfigured && supabase) {
    const { data, error } = await supabase
      .from('doctor_schedules')
      .select('*, doctors(full_name, specialties(name)), clinics(name)')
      .order('schedule_date', { ascending: true });

    if (error) throw error;
    return (data || []).map((s) => ({
      id: s.id,
      doctor_id: s.doctor_id,
      doctor_name: s.doctors?.full_name || 'Dokter',
      specialty_name: s.doctors?.specialties?.name || 'Poli',
      clinic_name: s.clinics?.name || 'Klinik',
      schedule_date: s.schedule_date,
      start_time: s.start_time,
      end_time: s.end_time,
      capacity: s.capacity,
      booked_count: s.booked_count,
      status: s.status,
    }));
  }

  return [...mockSchedules];
}

export async function getAuditLogs(): Promise<AuditLog[]> {
  if (isLiveConfigured && supabase) {
    const { data, error } = await supabase
      .from('audit_logs')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(50);

    if (error) throw error;
    return (data || []).map((l) => ({
      id: l.id,
      action: l.action,
      actor_name: l.actor_id || 'System / Service',
      resource_type: l.resource_type,
      resource_id: l.resource_id,
      payload: l.payload || {},
      created_at: l.created_at,
    }));
  }

  return [...mockAuditLogs];
}

const mockDoctors: Doctor[] = [
  {
    id: 'd1',
    full_name: 'dr. Budi Santoso',
    specialty_name: 'Poli Umum',
    sip_number: '446/123/SIP-D/2023',
    phone: '081234567890',
    bio: 'Dokter Umum dengan pengalaman 8 tahun di layanan primer dan kedokteran keluarga.',
    is_active: true,
  },
  {
    id: 'd2',
    full_name: 'drg. Siti Rahmawati',
    specialty_name: 'Poli Gigi & Mulut',
    sip_number: '446/456/SIP-DG/2023',
    phone: '081298765432',
    bio: 'Dokter Gigi berdedikasi tinggi dengan keahlian konservasi gigi dan pencegahan karies.',
    is_active: true,
  },
  {
    id: 'd3',
    full_name: 'dr. Maya Kartika, Sp.A',
    specialty_name: 'Poli Anak (Pediatri)',
    sip_number: '446/789/SIP-SPA/2024',
    phone: '081311223344',
    bio: 'Spesialis Anak fokus pada tumbuh kembang optimal dan imunisasi komprehensif.',
    is_active: true,
  },
  {
    id: 'd4',
    full_name: 'dr. Andi Wijaya, Sp.PD',
    specialty_name: 'Poli Penyakit Dalam',
    sip_number: '446/999/SIP-SPPD/2024',
    phone: '081355667788',
    bio: 'Spesialis Penyakit Dalam fokus manajemen penyakit kronis hipertensi dan diabetes.',
    is_active: true,
  },
];

export async function getDoctors(): Promise<Doctor[]> {
  if (isLiveConfigured && supabase) {
    const { data, error } = await supabase
      .from('doctors')
      .select('*, specialties(name)')
      .order('full_name', { ascending: true });

    if (error) throw error;
    return (data || []).map((d) => ({
      id: d.id,
      full_name: d.full_name,
      specialty_name: d.specialties?.name || 'Poli Umum',
      sip_number: d.sip_number || '-',
      phone: d.phone || '-',
      bio: d.bio || '',
      is_active: d.is_active,
    }));
  }

  return [...mockDoctors];
}
