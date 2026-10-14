import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_result.dart';
import '../domain/appointment_model.dart';

class BookingResult {
  final bool success;
  final String appointmentId;
  final String bookingReference;
  final String ticketCode;
  final int ticketNumber;
  final String qrToken;
  final String message;

  const BookingResult({
    required this.success,
    required this.appointmentId,
    required this.bookingReference,
    required this.ticketCode,
    required this.ticketNumber,
    required this.qrToken,
    required this.message,
  });

  factory BookingResult.fromJson(Map<String, dynamic> json) {
    return BookingResult(
      success: json['success'] as bool? ?? false,
      appointmentId: json['appointment_id'] as String? ?? '',
      bookingReference: json['booking_reference'] as String? ?? '',
      ticketCode: json['ticket_code'] as String? ?? '',
      ticketNumber: json['ticket_number'] as int? ?? 1,
      qrToken: json['qr_token'] as String? ?? '',
      message: json['message'] as String? ?? 'Booking berhasil dikonfirmasi',
    );
  }
}

class BookingRepository {
  static final List<AppointmentModel> _demoAppointments = [];

  Future<ApiResult<BookingResult>> bookAppointmentAtomic({
    required String scheduleId,
    required String patientId,
    String? notes,
    String? idempotencyKey,
  }) async {
    try {
      final safeKey = idempotencyKey ?? const Uuid().v4();

      if (AppConfig.isLiveConfigured) {
        final res = await Supabase.instance.client.rpc(
          'book_appointment_atomic',
          params: {
            'p_schedule_id': scheduleId,
            'p_patient_id': patientId,
            'p_notes': notes,
            'p_idempotency_key': safeKey,
          },
        );

        final result = BookingResult.fromJson(res as Map<String, dynamic>);
        return ApiSuccess(result);
      } else {
        // Demo atomic simulation
        await Future.delayed(const Duration(milliseconds: 500));
        final ticketNum = _demoAppointments.length + 1;
        final ref =
            'APT-${DateTime.now().year}${(DateTime.now().month).toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-${const Uuid().v4().substring(0, 4).toUpperCase()}';
        final ticketCode = 'A-${ticketNum.toString().padLeft(3, '0')}';
        final qrToken = 'QR-DEMO-${const Uuid().v4()}';
        final aptId = 'apt_${DateTime.now().millisecondsSinceEpoch}';

        final newApt = AppointmentModel(
          id: aptId,
          bookingReference: ref,
          patientId: patientId,
          userId: '11111111-aaaa-aaaa-aaaa-111111111111',
          scheduleId: scheduleId,
          status: 'confirmed',
          notes: notes,
          createdAt: DateTime.now(),
          doctorName: 'dr. Budi Santoso',
          specialtyName: 'Poli Umum',
          clinicName: 'Klinik Pratama Sehat Harmoni',
          scheduleDate: DateTime.now(),
          startTime: '08:00:00',
          endTime: '11:00:00',
          ticketCode: ticketCode,
        );
        _demoAppointments.insert(0, newApt);

        return ApiSuccess(
          BookingResult(
            success: true,
            appointmentId: aptId,
            bookingReference: ref,
            ticketCode: ticketCode,
            ticketNumber: ticketNum,
            qrToken: qrToken,
            message: 'Booking berhasil dikonfirmasi dan nomor antrean telah diterbitkan.',
          ),
        );
      }
    } catch (e) {
      return ApiError(message: 'Gagal melakukan reservasi: $e');
    }
  }

  Future<ApiResult<List<AppointmentModel>>> getMyAppointments() async {
    try {
      if (AppConfig.isLiveConfigured) {
        final res = await Supabase.instance.client
            .from('appointments')
            .select(
              '*, doctor_schedules(*, doctors(*, specialties(*)), clinics(*)), queue_tickets(ticket_code)',
            )
            .order('created_at', ascending: false);

        final list = (res as List)
            .map((e) => AppointmentModel.fromJson(e))
            .toList();
        return list.isEmpty
            ? const ApiEmpty(message: 'Belum ada riwayat booking kunjungan.')
            : ApiSuccess(list);
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
        return _demoAppointments.isEmpty
            ? const ApiEmpty(message: 'Belum ada riwayat booking kunjungan.')
            : ApiSuccess(_demoAppointments);
      }
    } catch (e) {
      return ApiError(message: 'Gagal memuat riwayat booking: $e');
    }
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});
