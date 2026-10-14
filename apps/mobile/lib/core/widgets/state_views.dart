import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Tampilan Loading standar SIMKlinik
class AppLoadingView extends StatelessWidget {
  final String? message;
  const AppLoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tampilan Error dengan tombol coba lagi (Retry)
class AppErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool isPermissionDenied;

  const AppErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.isPermissionDenied = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPermissionDenied ? Icons.lock_outline : Icons.error_outline,
                size: 42,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isPermissionDenied ? 'Akses Dibatasi' : 'Terjadi Kendala',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba Lagi'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(140, 44),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tampilan Kosong (Empty State)
class AppEmptyView extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const AppEmptyView({
    super.key,
    this.title = 'Belum Ada Data',
    required this.description,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(160, 44),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Banner Demo Mode Eksplisit (Sesuai Aturan: Tidak menyamarkan mock data di UI)
class AppDemoBanner extends StatelessWidget {
  const AppDemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFFFEF3C7),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 14, color: Color(0xFF92400E)),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Mode Demo Aktif: Simulasi data lokal aman (kredensial backend belum disetel).',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge status warna semantik dengan teks eksplisit
class AppStatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const AppStatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory AppStatusBadge.fromQueueStatus(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
        return const AppStatusBadge(
          label: 'Menunggu',
          backgroundColor: AppColors.warningLight,
          textColor: AppColors.warning,
          icon: Icons.hourglass_top,
        );
      case 'checked_in':
        return const AppStatusBadge(
          label: 'Sudah Check-In',
          backgroundColor: AppColors.infoLight,
          textColor: AppColors.info,
          icon: Icons.check_circle_outline,
        );
      case 'called':
        return const AppStatusBadge(
          label: 'Sedang Dipanggil',
          backgroundColor: Color(0xFFF3E8FF),
          textColor: Color(0xFF7E22CE),
          icon: Icons.volume_up,
        );
      case 'in_service':
        return const AppStatusBadge(
          label: 'Dalam Pelayanan',
          backgroundColor: AppColors.primaryLight,
          textColor: AppColors.primary,
          icon: Icons.medical_services_outlined,
        );
      case 'completed':
        return const AppStatusBadge(
          label: 'Selesai',
          backgroundColor: AppColors.successLight,
          textColor: AppColors.success,
          icon: Icons.done_all,
        );
      case 'cancelled':
      case 'skipped':
        return const AppStatusBadge(
          label: 'Dilewati/Batal',
          backgroundColor: AppColors.errorLight,
          textColor: AppColors.error,
          icon: Icons.cancel_outlined,
        );
      default:
        return AppStatusBadge(
          label: status,
          backgroundColor: AppColors.borderSubtle,
          textColor: AppColors.textSecondary,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
