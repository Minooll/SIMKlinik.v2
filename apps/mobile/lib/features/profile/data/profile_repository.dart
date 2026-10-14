import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_result.dart';
import '../domain/patient_profile_model.dart';

class ProfileRepository {
  static final List<PatientProfileModel> _demoProfiles = [
    PatientProfileModel(
      id: 'p1',
      userId: '11111111-aaaa-aaaa-aaaa-111111111111',
      fullName: 'Ahmad Fauzi',
      nik: '3171012345670001',
      dateOfBirth: DateTime(1992, 5, 14),
      gender: 'male',
      phone: '081234567890',
      address: 'Jl. Melati No. 22, Jakarta Selatan',
      bloodType: 'O',
    ),
  ];

  Future<ApiResult<List<PatientProfileModel>>> getPatientProfiles() async {
    try {
      if (AppConfig.isLiveConfigured) {
        final res = await Supabase.instance.client
            .from('patient_profiles')
            .select()
            .order('created_at', ascending: false);

        final list = (res as List)
            .map((e) => PatientProfileModel.fromJson(e))
            .toList();
        return list.isEmpty
            ? const ApiEmpty(message: 'Belum ada profil pasien terdaftar.')
            : ApiSuccess(list);
      } else {
        await Future.delayed(const Duration(milliseconds: 250));
        return ApiSuccess(_demoProfiles);
      }
    } catch (e) {
      return ApiError(message: 'Gagal memuat profil pasien: $e');
    }
  }

  Future<ApiResult<PatientProfileModel>> createPatientProfile({
    required String fullName,
    required String nik,
    required DateTime dateOfBirth,
    required String gender,
    String? phone,
    String? address,
    String? bloodType,
  }) async {
    try {
      if (AppConfig.isLiveConfigured) {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) {
          return const ApiError(message: 'Pengguna belum terautentikasi');
        }

        final res = await Supabase.instance.client
            .from('patient_profiles')
            .insert({
              'user_id': userId,
              'full_name': fullName,
              'nik': nik,
              'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
              'gender': gender,
              'phone': phone,
              'address': address,
              'blood_type': bloodType,
            })
            .select()
            .single();

        return ApiSuccess(PatientProfileModel.fromJson(res));
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
        final newProfile = PatientProfileModel(
          id: 'p_${DateTime.now().millisecondsSinceEpoch}',
          userId: '11111111-aaaa-aaaa-aaaa-111111111111',
          fullName: fullName,
          nik: nik,
          dateOfBirth: dateOfBirth,
          gender: gender,
          phone: phone,
          address: address,
          bloodType: bloodType,
        );
        _demoProfiles.add(newProfile);
        return ApiSuccess(newProfile);
      }
    } catch (e) {
      return ApiError(message: 'Gagal menambahkan profil pasien: $e');
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});
