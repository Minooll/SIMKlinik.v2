import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import {
  getDashboardMetrics,
  getQueueTickets,
  advanceQueueStatus,
  getAppointments,
  cancelAppointment,
  getDoctorSchedules,
  getDoctors,
  getAuditLogs,
} from '../lib/supabase';

describe('Admin Web Dashboard API & State Operations', () => {
  test('getDashboardMetrics returns valid metric counters', async () => {
    const metrics = await getDashboardMetrics();
    assert.ok(typeof metrics.totalPatientsToday === 'number');
    assert.ok(typeof metrics.activeQueueCount === 'number');
    assert.ok(typeof metrics.completedToday === 'number');
    assert.ok(typeof metrics.totalAppointments === 'number');
    assert.ok(metrics.totalPatientsToday >= 0);
  });

  test('getQueueTickets returns ticket list with valid fields', async () => {
    const tickets = await getQueueTickets();
    assert.ok(Array.isArray(tickets));
    assert.ok(tickets.length > 0);

    const firstTicket = tickets[0];
    assert.ok(firstTicket.id);
    assert.ok(firstTicket.ticket_code);
    assert.ok(firstTicket.patient_name);
    assert.ok(firstTicket.status);
  });

  test('advanceQueueStatus transitions ticket and creates audit log', async () => {
    const tickets = await getQueueTickets();
    const target = tickets.find((t) => t.status === 'checked_in') || tickets[0];
    assert.ok(target, 'Target ticket exists');

    const result = await advanceQueueStatus(target.id, 'called');
    assert.strictEqual(result.success, true);

    const updatedTickets = await getQueueTickets();
    const updated = updatedTickets.find((t) => t.id === target.id);
    assert.strictEqual(updated?.status, 'called');

    const logs = await getAuditLogs();
    const callLog = logs.find((l) => l.resource_id === target.id && l.action === 'ADVANCE_QUEUE_TICKET');
    assert.ok(callLog, 'Audit log exists for queue advance');
    assert.strictEqual(callLog?.actor_name, 'Admin / Petugas (Web)');
  });

  test('cancelAppointment cancels booking and records audit trail', async () => {
    const appointments = await getAppointments();
    const confirmed = appointments.find((a) => a.status === 'confirmed');
    assert.ok(confirmed, 'Confirmed appointment exists');

    const res = await cancelAppointment(confirmed.id, 'Pasien mendadak sakit');
    assert.strictEqual(res.success, true);

    const updatedAppointments = await getAppointments();
    const cancelled = updatedAppointments.find((a) => a.id === confirmed.id);
    assert.strictEqual(cancelled?.status, 'cancelled');

    const logs = await getAuditLogs();
    const cancelLog = logs.find((l) => l.resource_id === confirmed.id && l.action === 'CANCEL_APPOINTMENT_ATOMIC');
    assert.ok(cancelLog, 'Audit log created for appointment cancellation');
  });

  test('getDoctorSchedules returns schedules with valid capacity numbers', async () => {
    const schedules = await getDoctorSchedules();
    assert.ok(Array.isArray(schedules));
    assert.ok(schedules.length > 0);

    for (const sch of schedules) {
      assert.ok(sch.capacity > 0);
      assert.ok(sch.booked_count >= 0);
      assert.ok(sch.booked_count <= sch.capacity);
      assert.ok(sch.doctor_name);
      assert.ok(sch.specialty_name);
    }
  });

  test('getDoctors returns doctor list with active status and SIP number', async () => {
    const doctors = await getDoctors();
    assert.ok(Array.isArray(doctors));
    assert.strictEqual(doctors.length, 4);

    const drBudi = doctors.find((d) => d.full_name.includes('Budi Santoso'));
    assert.ok(drBudi);
    assert.strictEqual(drBudi.is_active, true);
    assert.ok(drBudi.sip_number.length > 5);
  });
});
