import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_result.dart';
import '../../../core/widgets/state_views.dart';
import '../data/queue_repository.dart';
import '../domain/queue_ticket_model.dart';

final ticketDetailProvider =
    FutureProvider.family<ApiResult<QueueTicketModel>, String>((ref, ticketId) {
      return ref.watch(queueRepositoryProvider).getTicketById(ticketId);
    });

class QueueTicketScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const QueueTicketScreen({super.key, required this.ticketId});

  @override
  ConsumerState<QueueTicketScreen> createState() => _QueueTicketScreenState();
}

class _QueueTicketScreenState extends ConsumerState<QueueTicketScreen> {
  bool _isCheckingIn = false;
  String? _bannerMessage;

  Future<void> _handleQrCheckIn(String qrToken) async {
    setState(() => _isCheckingIn = true);
    final repo = ref.read(queueRepositoryProvider);
    final res = await repo.checkInWithQr(qrToken);

    if (!mounted) return;
    setState(() => _isCheckingIn = false);

    if (res is ApiSuccess<String>) {
      setState(() => _bannerMessage = res.data);
      ref.invalidate(ticketDetailProvider(widget.ticketId));
    } else if (res is ApiError<String>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(ticketDetailProvider(widget.ticketId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Tiket Antrean')),
      body: ticketAsync.when(
        data: (result) {
          if (result is ApiSuccess<QueueTicketModel>) {
            final ticket = result.data;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_bannerMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _bannerMessage!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Big Ticket Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        AppStatusBadge.fromQueueStatus(ticket.status),
                        const SizedBox(height: 16),
                        const Text(
                          'NOMOR ANTREAN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ticket.ticketCode,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ticket.doctorName ?? 'Dokter Klinik',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          ticket.specialtyName ?? 'Poli Umum',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),

                        // QR Simulation Box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(
                              alpha: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.qr_code_2,
                                      size: 90,
                                      color: AppColors.primary,
                                    ),
                                    Text(
                                      'SCAN DI KIOSK',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Token: ${ticket.qrToken.substring(0, 15)}...',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Queue Estimation Box
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    'Sedang Dilayani',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    ticket.currentSessionNumber > 0
                                        ? 'A-${ticket.currentSessionNumber.toString().padLeft(3, '0')}'
                                        : 'Menunggu',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: AppColors.border,
                              ),
                              Column(
                                children: [
                                  const Text(
                                    'Pasien di Depan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${ticket.peopleAhead} Orang',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Simulation Button for Demo / Testing
                  if (ticket.status == 'waiting') ...[
                    ElevatedButton.icon(
                      onPressed: _isCheckingIn
                          ? null
                          : () => _handleQrCheckIn(ticket.qrToken),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: _isCheckingIn
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Simulasi Scan QR Check-in Kedatangan'),
                    ),
                  ] else ...[
                    OutlinedButton.icon(
                      onPressed: () =>
                          ref.invalidate(ticketDetailProvider(widget.ticketId)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Status Antrean'),
                    ),
                  ],
                ],
              ),
            );
          } else if (result is ApiError<QueueTicketModel>) {
            return AppErrorView(message: result.message);
          }
          return const SizedBox.shrink();
        },
        loading: () => const AppLoadingView(message: 'Memuat detail tiket...'),
        error: (err, _) => AppErrorView(message: err.toString()),
      ),
    );
  }
}
