import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_result.dart';

class AuthUser {
  final String id;
  final String email;
  final String fullName;
  final String role;

  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.role = 'patient',
  });
}

class AuthRepository {
  // In-memory user for demo mode
  static AuthUser? _demoUser = const AuthUser(
    id: '11111111-aaaa-aaaa-aaaa-111111111111',
    email: 'pasien.demo@simklinik.local',
    fullName: 'Ahmad Fauzi (Demo)',
    role: 'patient',
  );

  AuthUser? get currentUser {
    if (AppConfig.isLiveConfigured) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;
      return AuthUser(
        id: user.id,
        email: user.email ?? '',
        fullName: (user.userMetadata?['full_name'] as String?) ?? 'Pengguna',
      );
    }
    return _demoUser;
  }

  bool get isAuthenticated => currentUser != null;

  Future<ApiResult<AuthUser>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      if (AppConfig.isLiveConfigured) {
        final res = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        final user = res.user;
        if (user == null) {
          return const ApiError(message: 'Pengguna tidak ditemukan.');
        }
        return ApiSuccess(
          AuthUser(
            id: user.id,
            email: user.email ?? '',
            fullName:
                (user.userMetadata?['full_name'] as String?) ?? 'Pengguna',
          ),
        );
      } else {
        // Demo mode simulation
        await Future.delayed(const Duration(milliseconds: 400));
        _demoUser = AuthUser(
          id: '11111111-aaaa-aaaa-aaaa-111111111111',
          email: email,
          fullName: email.split('@').first.toUpperCase(),
          role: 'patient',
        );
        return ApiSuccess(_demoUser!);
      }
    } on AuthException catch (e) {
      return ApiError(message: e.message, code: e.statusCode);
    } catch (e) {
      return ApiError(message: 'Gagal masuk: $e');
    }
  }

  Future<ApiResult<AuthUser>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      if (AppConfig.isLiveConfigured) {
        final res = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': fullName, 'phone': phone},
        );
        final user = res.user;
        if (user == null) {
          return const ApiError(message: 'Gagal membuat akun.');
        }
        return ApiSuccess(
          AuthUser(id: user.id, email: user.email ?? '', fullName: fullName),
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 400));
        _demoUser = AuthUser(
          id: '11111111-aaaa-aaaa-aaaa-111111111111',
          email: email,
          fullName: fullName,
          role: 'patient',
        );
        return ApiSuccess(_demoUser!);
      }
    } on AuthException catch (e) {
      return ApiError(message: e.message, code: e.statusCode);
    } catch (e) {
      return ApiError(message: 'Gagal mendaftar: $e');
    }
  }

  Future<void> signOut() async {
    if (AppConfig.isLiveConfigured) {
      await Supabase.instance.client.auth.signOut();
    } else {
      _demoUser = null;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
