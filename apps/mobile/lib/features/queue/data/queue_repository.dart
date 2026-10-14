import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_result.dart';
import '../domain/queue_ticket_model.dart';

class QueueRepository {
  static final List<QueueTicketModel> _demoTickets = [
    QueueTicketModel(
      id: 'qt1',
      queueSessionId: 'qs1',
      patientId: 'p1',
      userId: '11111111-aaaa-aaaa-aaaa-111111111111',
      ticketNumber: 3,
      ticketCode: 'A-003',
      qrToken: 'QR-DEMO-SIMKLINIK-TOKEN-003',
      status: 'waiting',
      createdAt: DateTime.now(),
      patientName: 'Ahmad Fauzi',
      doctorName: 'dr. Budi Santoso',
      specialtyName: 'Poli Umum',
      clinicName: 'Klinik Pratama Sehat Harmoni',
      currentSessionNumber: 1,
      estimatedWaitMinutes: 30,
    ),
  ];

  Future<ApiResult<List<QueueTicketModel>>> getMyTickets() async {
    try {
      if (AppConfig.isLiveConfigured) {
        final res = await Supabase.instance.client
            .from('queue_tickets')
            .select(
              '*, patient_profiles(full_name), queue_sessions(*, doctors(full_name, specialties(name)), clinics(name))',
            )
            .order('created_at', ascending: false);

        final list = (res as List)
            .map((e) => QueueTicketModel.fromJson(e))
            .toList();
        return list.isEmpty
            ? const ApiEmpty(message: 'Tidak ada tiket antrean aktif saat ini.')
            : ApiSuccess(list);
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
        return _demoTickets.isEmpty
            ? const ApiEmpty(message: 'Tidak ada tiket antrean aktif.')
            : ApiSuccess(_demoTickets);
      }
    } catch (e) {
      return ApiError(message: 'Gagal memuat tiket antrean: $e');
    }
  }

  Future<ApiResult<QueueTicketModel>> getTicketById(String ticketId) async {
    try {
      if (AppConfig.isLiveConfigured) {
        final res = await Supabase.instance.client
            .from('queue_tickets')
            .select(
              '*, patient_profiles(full_name), queue_sessions(*, doctors(full_name, specialties(name)), clinics(name))',
            )
            .eq('id', ticketId)
            .single();

        return ApiSuccess(QueueTicketModel.fromJson(res));
      } else {
        await Future.delayed(const Duration(milliseconds: 250));
        final ticket = _demoTickets.firstWhere(
          (t) => t.id == ticketId,
          orElse: () => _demoTickets.first,
        );
        return ApiSuccess(ticket);
      }
    } catch (e) {
      return ApiError(message: 'Gagal memuat detail tiket: $e');
    }
  }

  Future<ApiResult<String>> checkInWithQr(String qrToken) async {
    try {
      if (AppConfig.isLiveConfigured) {
        final res = await Supabase.instance.client.rpc(
          'check_in_with_qr',
          params: {'p_qr_token': qrToken},
        );
        final map = res as Map<String, dynamic>;
        return ApiSuccess(map['message'] as String? ?? 'Check-in berhasil');
      } else {
        await Future.delayed(const Duration(milliseconds: 400));
        // Update demo in-memory ticket
        final idx = _demoTickets.indexWhere(
          (t) => t.qrToken == qrToken || t.id == 'qt1',
        );
        if (idx != -1) {
          final old = _demoTickets[idx];
          _demoTickets[idx] = QueueTicketModel(
            id: old.id,
            queueSessionId: old.queueSessionId,
            patientId: old.patientId,
            userId: old.userId,
            ticketNumber: old.ticketNumber,
            ticketCode: old.ticketCode,
            qrToken: old.qrToken,
            status: 'checked_in',
            checkedInAt: DateTime.now(),
            createdAt: old.createdAt,
            patientName: old.patientName,
            doctorName: old.doctorName,
            specialtyName: old.specialtyName,
            clinicName: old.clinicName,
            currentSessionNumber: old.currentSessionNumber,
            estimatedWaitMinutes: old.estimatedWaitMinutes,
          );
        }
        return const ApiSuccess(
          'Check-in berhasil! Anda telah terdaftar dalam antrean aktif hari ini.',
        );
      }
    } catch (e) {
      return ApiError(message: 'Gagal melakukan check-in: $e');
    }
  }
}

final queueRepositoryProvider = Provider<QueueRepository>((ref) {
  return QueueRepository();
});
