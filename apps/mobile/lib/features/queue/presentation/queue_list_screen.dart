import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_result.dart';
import '../../../core/widgets/state_views.dart';
import '../data/queue_repository.dart';
import '../domain/queue_ticket_model.dart';

final myTicketsListProvider = FutureProvider<ApiResult<List<QueueTicketModel>>>(
  (ref) {
    return ref.watch(queueRepositoryProvider).getMyTickets();
  },
);

class QueueListScreen extends ConsumerWidget {
  const QueueListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(myTicketsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tiket Antrean Saya')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myTicketsListProvider),
        child: ticketsAsync.when(
          data: (result) {
            if (result is ApiSuccess<List<QueueTicketModel>>) {
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: result.data.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final ticket = result.data[index];
                  return _buildTicketCard(context, ticket);
                },
              );
            } else if (result is ApiEmpty<List<QueueTicketModel>>) {
              return AppEmptyView(
                icon: Icons.confirmation_number_outlined,
                title: 'Belum Ada Tiket Antrean',
                description: 'Anda belum memiliki tiket antrean kunjungan aktif hari ini.',
                actionLabel: 'Cari Dokter Sekarang',
                onAction: () => context.go('/doctors'),
              );
            } else if (result is ApiError<List<QueueTicketModel>>) {
              return AppErrorView(
                message: result.message,
                onRetry: () => ref.invalidate(myTicketsListProvider),
              );
            }
            return const SizedBox.shrink();
          },
          loading: () =>
              const AppLoadingView(message: 'Memuat tiket antrean...'),
          error: (err, _) => AppErrorView(
            message: err.toString(),
            onRetry: () => ref.invalidate(myTicketsListProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, QueueTicketModel ticket) {
    return InkWell(
      onTap: () => context.go('/ticket/${ticket.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    ticket.ticketCode,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                AppStatusBadge.fromQueueStatus(ticket.status),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              ticket.doctorName ?? 'Dokter Spesialis',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${ticket.specialtyName ?? 'Poli Umum'} • ${ticket.clinicName ?? 'Klinik Pratama'}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pasien: ${ticket.patientName ?? 'Pasien'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Row(
                  children: [
                    Text(
                      'Buka QR Tiket',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
