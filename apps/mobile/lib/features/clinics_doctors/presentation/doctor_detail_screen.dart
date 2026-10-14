import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_result.dart';
import '../../../core/widgets/state_views.dart';
import '../data/doctor_repository.dart';
import '../domain/doctor_model.dart';
import '../domain/schedule_model.dart';

final doctorDetailProvider = FutureProvider.family<DoctorModel?, String>((
  ref,
  doctorId,
) async {
  final res = await ref.watch(doctorRepositoryProvider).getDoctors();
  if (res is ApiSuccess<List<DoctorModel>>) {
    return res.data.firstWhere(
      (d) => d.id == doctorId,
      orElse: () => res.data.first,
    );
  }
  return null;
});

final doctorSchedulesProvider =
    FutureProvider.family<ApiResult<List<ScheduleModel>>, String>((
      ref,
      doctorId,
    ) {
      return ref.watch(doctorRepositoryProvider).getDoctorSchedules(doctorId);
    });

class SelectedScheduleNotifier extends Notifier<ScheduleModel?> {
  @override
  ScheduleModel? build() => null;
  void set(ScheduleModel? val) => state = val;
}

final selectedScheduleSlotProvider =
    NotifierProvider<SelectedScheduleNotifier, ScheduleModel?>(
      SelectedScheduleNotifier.new,
    );

class DoctorDetailScreen extends ConsumerWidget {
  final String doctorId;
  const DoctorDetailScreen({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorAsync = ref.watch(doctorDetailProvider(doctorId));
    final schedulesAsync = ref.watch(doctorSchedulesProvider(doctorId));
    final selectedSchedule = ref.watch(selectedScheduleSlotProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil & Jadwal Dokter')),
      body: doctorAsync.when(
        data: (doctor) {
          if (doctor == null) {
            return const AppEmptyView(
              description: 'Data dokter tidak ditemukan.',
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Bio Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          doctor.fullName.isNotEmpty ? doctor.fullName[0] : 'D',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor.fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              doctor.specialtyName ?? 'Poli Spesialis',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              doctor.clinicName ?? 'Klinik Pratama',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (doctor.sipNumber != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                doctor.sipNumber!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (doctor.bio != null) ...[
                  const Text(
                    'Tentang Dokter',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    doctor.bio!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Schedule Slots Section
                const Text(
                  'Pilih Jadwal Praktek',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kapasitas slot diverifikasi secara real-time dari database.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),

                schedulesAsync.when(
                  data: (result) {
                    if (result is ApiSuccess<List<ScheduleModel>>) {
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: result.data.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final slot = result.data[index];
                          final isSelected = selectedSchedule?.id == slot.id;
                          final dateStr = DateFormat(
                            'EEEE, d MMMM yyyy',
                            'id_ID',
                          ).format(slot.scheduleDate);
                          final timeStr =
                              '${slot.startTime.substring(0, 5)} - ${slot.endTime.substring(0, 5)} WIB';

                          return InkWell(
                            onTap: slot.isAvailable
                                ? () => ref
                                      .read(
                                        selectedScheduleSlotProvider.notifier,
                                      )
                                      .set(slot)
                                : null,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryLight
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (slot.isAvailable
                                            ? AppColors.border
                                            : AppColors.borderSubtle),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dateStr,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          timeStr,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: slot.isAvailable
                                          ? AppColors.primarySubtle
                                          : AppColors.errorLight,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      slot.isAvailable
                                          ? 'Sisa ${slot.availableSlots} slot'
                                          : 'Penuh',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: slot.isAvailable
                                            ? AppColors.primary
                                            : AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    } else if (result is ApiEmpty<List<ScheduleModel>>) {
                      return AppEmptyView(description: result.message);
                    } else if (result is ApiError<List<ScheduleModel>>) {
                      return AppErrorView(message: result.message);
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const AppLoadingView(
                    message: 'Memeriksa jadwal praktek...',
                  ),
                  error: (err, stack) => AppErrorView(message: err.toString()),
                ),
              ],
            ),
          );
        },
        loading: () => const AppLoadingView(message: 'Memuat profil dokter...'),
        error: (err, stack) => AppErrorView(message: err.toString()),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: ElevatedButton(
          onPressed: selectedSchedule != null
              ? () {
                  context.go(
                    '/booking/${selectedSchedule.id}',
                    extra: selectedSchedule,
                  );
                }
              : null,
          child: const Text('Lanjutkan Booking'),
        ),
      ),
    );
  }
}
