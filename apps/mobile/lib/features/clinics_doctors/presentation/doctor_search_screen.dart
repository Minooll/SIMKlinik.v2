import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_result.dart';
import '../../../core/widgets/state_views.dart';
import '../data/doctor_repository.dart';
import '../domain/doctor_model.dart';
import '../domain/specialty_model.dart';

class SelectedSpecialtyNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? val) => state = val;
}

final selectedSpecialtyFilterProvider =
    NotifierProvider<SelectedSpecialtyNotifier, String?>(
      SelectedSpecialtyNotifier.new,
    );

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String val) => state = val;
}

final searchQueryFilterProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

final searchDoctorsListProvider = FutureProvider<ApiResult<List<DoctorModel>>>((
  ref,
) {
  final specialtyId = ref.watch(selectedSpecialtyFilterProvider);
  final query = ref.watch(searchQueryFilterProvider);
  return ref
      .watch(doctorRepositoryProvider)
      .getDoctors(specialtyId: specialtyId, query: query);
});

final searchSpecialtiesProvider =
    FutureProvider<ApiResult<List<SpecialtyModel>>>((ref) {
      return ref.watch(doctorRepositoryProvider).getSpecialties();
    });

class DoctorSearchScreen extends ConsumerWidget {
  final String? initialSpecialtyId;
  const DoctorSearchScreen({super.key, this.initialSpecialtyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSpecialty = ref.watch(selectedSpecialtyFilterProvider);
    final specialtiesAsync = ref.watch(searchSpecialtiesProvider);
    final doctorsAsync = ref.watch(searchDoctorsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cari Jadwal Dokter')),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari nama dokter atau keluhan...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: ref.watch(searchQueryFilterProvider).isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => ref
                            .read(searchQueryFilterProvider.notifier)
                            .set(''),
                      )
                    : null,
              ),
              onChanged: (val) {
                ref.read(searchQueryFilterProvider.notifier).set(val);
              },
            ),
          ),

          // Specialty Filter Chips
          specialtiesAsync.when(
            data: (result) {
              if (result is ApiSuccess<List<SpecialtyModel>>) {
                return SizedBox(
                  height: 44,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: result.data.length + 1,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isAll = selectedSpecialty == null;
                        return ChoiceChip(
                          label: const Text('Semua Poli'),
                          selected: isAll,
                          onSelected: (_) => ref
                              .read(selectedSpecialtyFilterProvider.notifier)
                              .set(null),
                        );
                      }
                      final spec = result.data[index - 1];
                      final isSelected = selectedSpecialty == spec.id;
                      return ChoiceChip(
                        label: Text(spec.name),
                        selected: isSelected,
                        onSelected: (_) => ref
                            .read(selectedSpecialtyFilterProvider.notifier)
                            .set(isSelected ? null : spec.id),
                      );
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (err, stack) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 10),

          // Doctor Results List
          Expanded(
            child: doctorsAsync.when(
              data: (result) {
                if (result is ApiSuccess<List<DoctorModel>>) {
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: result.data.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = result.data[index];
                      return _buildDoctorCard(context, doc);
                    },
                  );
                } else if (result is ApiEmpty<List<DoctorModel>>) {
                  return AppEmptyView(
                    icon: Icons.search_off,
                    title: 'Dokter Tidak Ditemukan',
                    description: result.message,
                  );
                } else if (result is ApiError<List<DoctorModel>>) {
                  return AppErrorView(
                    message: result.message,
                    onRetry: () => ref.invalidate(searchDoctorsListProvider),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const AppLoadingView(message: 'Mencari dokter...'),
              error: (err, stack) => AppErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(searchDoctorsListProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, DoctorModel doctor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  doctor.fullName.isNotEmpty ? doctor.fullName[0] : 'D',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
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
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.specialtyName ?? 'Poli Umum',
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
          if (doctor.bio != null) ...[
            const SizedBox(height: 12),
            Text(
              doctor.bio!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => context.go('/doctor/${doctor.id}'),
            child: const Text('Pilih Jadwal & Booking'),
          ),
        ],
      ),
    );
  }
}
