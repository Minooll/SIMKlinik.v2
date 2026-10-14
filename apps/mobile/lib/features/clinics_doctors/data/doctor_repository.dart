import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_result.dart';
import '../domain/doctor_model.dart';
import '../domain/specialty_model.dart';
import '../domain/schedule_model.dart';

class DoctorRepository {
  // Demo data matching seed.sql
  static final List<SpecialtyModel> _demoSpecialties = [
    const SpecialtyModel(
      id: 's1',
      name: 'Poli Umum',
      description: 'Pelayanan umum dan keluhan primer',
      iconName: 'medical_services',
    ),
    const SpecialtyModel(
      id: 's2',
      name: 'Poli Gigi & Mulut',
      description: 'Perawatan gigi dan estetika mulut',
      iconName: 'dentistry',
    ),
    const SpecialtyModel(
      id: 's3',
      name: 'Poli Anak (Pediatri)',
      description: 'Kesehatan anak dan imunisasi',
      iconName: 'child_care',
    ),
    const SpecialtyModel(
      id: 's4',
      name: 'Poli Penyakit Dalam',
      description: 'Diagnosis organ dalam dan metabolisme',
      iconName: 'favorite',
    ),
  ];

  static final List<DoctorModel> _demoDoctors = [
    const DoctorModel(
      id: 'd1',
      specialtyId: 's1',
      clinicId: 'c1',
      fullName: 'dr. Budi Santoso',
      specialtyName: 'Poli Umum',
      clinicName: 'Klinik Pratama Sehat Harmoni',
      sipNumber: 'SIP: 503/4321/IDI-JAKSEL/2022',
      bio: 'Dokter umum berdedikasi dengan fokus pelayanan komprehensif pasien rawat jalan.',
    ),
    const DoctorModel(
      id: 'd2',
      specialtyId: 's2',
      clinicId: 'c1',
      fullName: 'drg. Siti Rahmawati',
      specialtyName: 'Poli Gigi & Mulut',
      clinicName: 'Klinik Pratama Sehat Harmoni',
      sipNumber: 'SIP: 503/8765/PDGI-JAKSEL/2023',
      bio: 'Dokter gigi lulusan Universitas Indonesia spesialis estetika dan kesehatan periodonsium.',
    ),
    const DoctorModel(
      id: 'd3',
      specialtyId: 's3',
      clinicId: 'c1',
      fullName: 'dr. Maya Kartika, Sp.A',
      specialtyName: 'Poli Anak (Pediatri)',
      clinicName: 'Klinik Pratama Sehat Harmoni',
      sipNumber: 'SIP: 503/1122/IDAI-JAKSEL/2021',
      bio: 'Dokter spesialis anak dengan pengalaman luas dalam pemantauan nutrisi dan tumbuh kembang balita.',
    ),
    const DoctorModel(
      id: 'd4',
      specialtyId: 's4',
      clinicId: 'c1',
      fullName: 'dr. Andi Wijaya, Sp.PD',
      specialtyName: 'Poli Penyakit Dalam',
      clinicName: 'Klinik Pratama Sehat Harmoni',
      sipNumber: 'SIP: 503/9900/PAPDI-JAKSEL/2020',
      bio: 'Spesialis penyakit dalam konsultan diabetes, kardiometabolik, dan hipertensi.',
    ),
  ];

  Future<ApiResult<List<SpecialtyModel>>> getSpecialties() async {
    try {
      if (AppConfig.isLiveConfigured) {
        final res = await Supabase.instance.client
            .from('specialties')
            .select()
            .order('name');
        final list = (res as List)
            .map((e) => SpecialtyModel.fromJson(e))
            .toList();
        return ApiSuccess(list);
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
        return ApiSuccess(_demoSpecialties);
      }
    } catch (e) {
      return ApiError(message: 'Gagal memuat daftar poli: $e');
    }
  }

  Future<ApiResult<List<DoctorModel>>> getDoctors({
    String? specialtyId,
    String? query,
  }) async {
    try {
      if (AppConfig.isLiveConfigured) {
        var queryBuilder = Supabase.instance.client
            .from('doctors')
            .select('*, specialties(name), clinics(name)')
            .eq('is_active', true);

        if (specialtyId != null && specialtyId.isNotEmpty) {
          queryBuilder = queryBuilder.eq('specialty_id', specialtyId);
        }
        if (query != null && query.trim().isNotEmpty) {
          queryBuilder = queryBuilder.ilike('full_name', '%${query.trim()}%');
        }

        final res = await queryBuilder.order('full_name');
        final list = (res as List).map((e) => DoctorModel.fromJson(e)).toList();
        return list.isEmpty
            ? const ApiEmpty(
                message:
                    'Tidak ada dokter yang cocok dengan kriteria pencarian.',
              )
            : ApiSuccess(list);
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
        var filtered = _demoDoctors.where((d) {
          final matchSpecialty =
              specialtyId == null ||
              specialtyId.isEmpty ||
              d.specialtyId == specialtyId;
          final matchQuery =
              query == null ||
              query.trim().isEmpty ||
              d.fullName.toLowerCase().contains(query.toLowerCase());
          return matchSpecialty && matchQuery;
        }).toList();

        return filtered.isEmpty
            ? const ApiEmpty(
                message: 'Tidak ada dokter yang cocok dengan pencarian.',
              )
            : ApiSuccess(filtered);
      }
    } catch (e) {
      return ApiError(message: 'Gagal memuat daftar dokter: $e');
    }
  }

  Future<ApiResult<List<ScheduleModel>>> getDoctorSchedules(
    String doctorId,
  ) async {
    try {
      if (AppConfig.isLiveConfigured) {
        final res = await Supabase.instance.client
            .from('doctor_schedules')
            .select('*, doctors(full_name, specialties(name)), clinics(name)')
            .eq('doctor_id', doctorId)
            .gte(
              'schedule_date',
              DateTime.now().toIso8601String().split('T').first,
            )
            .order('schedule_date')
            .order('start_time');

        final list = (res as List)
            .map((e) => ScheduleModel.fromJson(e))
            .toList();
        return list.isEmpty
            ? const ApiEmpty(
                message: 'Belum ada jadwal praktek mendatang untuk dokter ini.',
              )
            : ApiSuccess(list);
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
        final now = DateTime.now();
        final schedules = [
          ScheduleModel(
            id: 'sch_${doctorId}_1',
            clinicId: 'c1',
            doctorId: doctorId,
            scheduleDate: now,
            startTime: '08:00:00',
            endTime: '11:00:00',
            capacity: 10,
            bookedCount: 3,
            status: 'available',
            doctorName: _demoDoctors
                .firstWhere(
                  (d) => d.id == doctorId,
                  orElse: () => _demoDoctors.first,
                )
                .fullName,
            specialtyName: _demoDoctors
                .firstWhere(
                  (d) => d.id == doctorId,
                  orElse: () => _demoDoctors.first,
                )
                .specialtyName,
          ),
          ScheduleModel(
            id: 'sch_${doctorId}_2',
            clinicId: 'c1',
            doctorId: doctorId,
            scheduleDate: now.add(const Duration(days: 1)),
            startTime: '13:00:00',
            endTime: '16:00:00',
            capacity: 8,
            bookedCount: 0,
            status: 'available',
            doctorName: _demoDoctors
                .firstWhere(
                  (d) => d.id == doctorId,
                  orElse: () => _demoDoctors.first,
                )
                .fullName,
            specialtyName: _demoDoctors
                .firstWhere(
                  (d) => d.id == doctorId,
                  orElse: () => _demoDoctors.first,
                )
                .specialtyName,
          ),
        ];
        return ApiSuccess(schedules);
      }
    } catch (e) {
      return ApiError(message: 'Gagal memuat jadwal praktek: $e');
    }
  }
}

final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return DoctorRepository();
});
