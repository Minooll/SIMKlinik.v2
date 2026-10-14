import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_result.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/data/auth_repository.dart';
import '../../clinics_doctors/data/doctor_repository.dart';
import '../../clinics_doctors/domain/doctor_model.dart';
import '../../clinics_doctors/domain/specialty_model.dart';
import '../../queue/data/queue_repository.dart';
import '../../queue/domain/queue_ticket_model.dart';

final homeSpecialtiesProvider = FutureProvider<ApiResult<List<SpecialtyModel>>>(
  (ref) {
    return ref.watch(doctorRepositoryProvider).getSpecialties();
  },
);

final homeDoctorsProvider = FutureProvider<ApiResult<List<DoctorModel>>>((ref) {
  return ref.watch(doctorRepositoryProvider).getDoctors();
});

final homeActiveTicketProvider =
    FutureProvider<ApiResult<List<QueueTicketModel>>>((ref) {
      return ref.watch(queueRepositoryProvider).getMyTickets();
    });

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final specialtiesAsync = ref.watch(homeSpecialtiesProvider);
    final doctorsAsync = ref.watch(homeDoctorsProvider);
    final ticketsAsync = ref.watch(homeActiveTicketProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(homeSpecialtiesProvider);
          ref.invalidate(homeDoctorsProvider);
          ref.invalidate(homeActiveTicketProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selamat Datang,',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.fullName ?? 'Pasien SIMKlinik',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Active Queue Preview Card
              ticketsAsync.when(
                data: (result) {
                  if (result is ApiSuccess<List<QueueTicketModel>> &&
                      result.data.isNotEmpty) {
                    final ticket = result.data.first;
                    return _buildActiveQueueCard(context, ticket);
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
              ),

              // Quick Actions
              const Text(
                'Layanan Utama',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: 'Cari Dokter',
                      subtitle: 'Pilih jadwal & poli',
                      icon: Icons.search,
                      color: AppColors.primary,
                      onTap: () => context.go('/doctors'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: 'Antrean Saya',
                      subtitle: 'Status & QR Code',
                      icon: Icons.confirmation_number_outlined,
                      color: AppColors.secondary,
                      onTap: () => context.go('/tickets'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Specialties Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Poli Spesialisasi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/doctors'),
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              specialtiesAsync.when(
                data: (result) {
                  if (result is ApiSuccess<List<SpecialtyModel>>) {
                    return SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: result.data.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final spec = result.data[index];
                          return ActionChip(
                            avatar: const Icon(
                              Icons.medical_services_outlined,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            label: Text(spec.name),
                            onPressed: () =>
                                context.go('/doctors?specialtyId=${spec.id}'),
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (e, stack) => Text('Gagal memuat: $e'),
              ),
              const SizedBox(height: 24),

              // Recommended Doctors Section
              const Text(
                'Jadwal Dokter Tersedia',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              doctorsAsync.when(
                data: (result) {
                  if (result is ApiSuccess<List<DoctorModel>>) {
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: result.data.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final doctor = result.data[index];
                        return _buildDoctorCard(context, doctor);
                      },
                    );
                  } else if (result is ApiEmpty<List<DoctorModel>>) {
                    return AppEmptyView(description: result.message);
                  } else if (result is ApiError<List<DoctorModel>>) {
                    return AppErrorView(message: result.message);
                  }
                  return const SizedBox.shrink();
                },
                loading: () =>
                    const AppLoadingView(message: 'Memuat dokter...'),
                error: (err, stack) => AppErrorView(message: err.toString()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveQueueCard(BuildContext context, QueueTicketModel ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Antrean Aktif Anda',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              AppStatusBadge.fromQueueStatus(ticket.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ticket.ticketCode,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.doctorName ?? 'Dokter Klinik',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      ticket.specialtyName ?? 'Poli Umum',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (ticket.peopleAhead > 0)
                      Text(
                        '${ticket.peopleAhead} pasien di depan Anda (~${ticket.estimatedWaitMinutes ?? 15} mnt)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.go('/ticket/${ticket.id}'),
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, DoctorModel doctor) {
    return InkWell(
      onTap: () => context.go('/doctor/${doctor.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                doctor.fullName.isNotEmpty ? doctor.fullName[0] : 'D',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.fullName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    doctor.specialtyName ?? 'Poli Umum',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    doctor.clinicName ?? 'Klinik Pratama',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
