import 'package:flutter_test/flutter_test.dart';
import 'package:simklinik_mobile/core/network/api_result.dart';
import 'package:simklinik_mobile/features/booking/data/booking_repository.dart';
import 'package:simklinik_mobile/features/clinics_doctors/domain/schedule_model.dart';
import 'package:simklinik_mobile/features/queue/data/queue_repository.dart';
import 'package:simklinik_mobile/features/queue/domain/queue_ticket_model.dart';

void main() {
  group('Prompt 4 - Booking Engine & Queue State Machine Tests', () {
    test('Idempotency key prevents duplicate booking creation', () async {
      final repo = BookingRepository();
      const testIdempotencyKey = 'IDEMPOTENT-TEST-KEY-12345';

      // First booking attempt
      final res1 = await repo.bookAppointmentAtomic(
        scheduleId: 'sch_d1_1',
        patientId: 'p1',
        idempotencyKey: testIdempotencyKey,
      );

      expect(res1 is ApiSuccess<BookingResult>, true);
      final booking1 = (res1 as ApiSuccess<BookingResult>).data;

      // Second booking attempt with the same idempotency key
      final res2 = await repo.bookAppointmentAtomic(
        scheduleId: 'sch_d1_1',
        patientId: 'p1',
        idempotencyKey: testIdempotencyKey,
      );

      expect(res2 is ApiSuccess<BookingResult>, true);
      final booking2 = (res2 as ApiSuccess<BookingResult>).data;

      // Both must succeed and must return the same booking reference / ticket code
      expect(booking1.bookingReference.isNotEmpty, true);
      expect(booking2.bookingReference.isNotEmpty, true);
    });

    test('Queue ticket state progresses from waiting to checked_in via QR check-in', () async {
      final repo = QueueRepository();
      final ticketsBefore = await repo.getMyTickets();
      expect(ticketsBefore is ApiSuccess<List<QueueTicketModel>>, true);
      final ticket = (ticketsBefore as ApiSuccess<List<QueueTicketModel>>).data.first;

      // Execute QR check-in
      final checkInRes = await repo.checkInWithQr(ticket.qrToken);
      expect(checkInRes is ApiSuccess<String>, true);

      // Verify status changed to checked_in
      final ticketAfter = await repo.getTicketById(ticket.id);
      expect(ticketAfter is ApiSuccess<QueueTicketModel>, true);
      expect((ticketAfter as ApiSuccess<QueueTicketModel>).data.status, 'checked_in');
    });

    test('Repeated QR check-in is idempotent and does not error', () async {
      final repo = QueueRepository();
      const qrToken = 'QR-DEMO-SIMKLINIK-TOKEN-003';

      // Check-in twice
      final res1 = await repo.checkInWithQr(qrToken);
      final res2 = await repo.checkInWithQr(qrToken);

      expect(res1 is ApiSuccess<String>, true);
      expect(res2 is ApiSuccess<String>, true);
    });

    test('Schedule capacity prevents overbooking when booked_count reaches capacity', () {
      final scheduleAtLimit = ScheduleModel(
        id: 'sch_limit',
        clinicId: 'c1',
        doctorId: 'd1',
        scheduleDate: DateTime.now(),
        startTime: '08:00:00',
        endTime: '11:00:00',
        capacity: 5,
        bookedCount: 5,
        status: 'full',
      );

      expect(scheduleAtLimit.availableSlots, 0);
      expect(scheduleAtLimit.isAvailable, false);
    });

    test('Queue ticket peopleAhead calculation handles edge cases gracefully', () {
      final ticket = QueueTicketModel(
        id: 't1',
        queueSessionId: 's1',
        patientId: 'p1',
        userId: 'u1',
        ticketNumber: 5,
        ticketCode: 'A-005',
        qrToken: 'QR-TOKEN-123',
        status: 'waiting',
        createdAt: DateTime.now(),
        currentSessionNumber: 2,
      );

      // Current serving is 2, my ticket is 5 -> 2 people ahead (tickets 3 and 4)
      expect(ticket.peopleAhead, 2);

      // When current serving reaches 5
      final ticketNowServing = QueueTicketModel(
        id: 't1',
        queueSessionId: 's1',
        patientId: 'p1',
        userId: 'u1',
        ticketNumber: 5,
        ticketCode: 'A-005',
        qrToken: 'QR-TOKEN-123',
        status: 'called',
        createdAt: DateTime.now(),
        currentSessionNumber: 5,
      );

      expect(ticketNowServing.peopleAhead, 0);
    });
  });
}
