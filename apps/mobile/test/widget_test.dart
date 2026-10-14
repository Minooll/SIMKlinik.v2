import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simklinik_mobile/core/network/api_result.dart';
import 'package:simklinik_mobile/core/widgets/state_views.dart';
import 'package:simklinik_mobile/features/auth/data/auth_repository.dart';
import 'package:simklinik_mobile/features/booking/data/booking_repository.dart';
import 'package:simklinik_mobile/features/clinics_doctors/data/doctor_repository.dart';
import 'package:simklinik_mobile/features/clinics_doctors/domain/schedule_model.dart';
import 'package:simklinik_mobile/main.dart';

void main() {
  group('Unit Tests - Domain & Business Rules', () {
    test('ScheduleModel calculates available slots correctly', () {
      final schedule = ScheduleModel(
        id: 'sch1',
        clinicId: 'c1',
        doctorId: 'd1',
        scheduleDate: DateTime.now(),
        startTime: '08:00:00',
        endTime: '11:00:00',
        capacity: 10,
        bookedCount: 4,
        status: 'available',
      );

      expect(schedule.availableSlots, 6);
      expect(schedule.isAvailable, true);

      final fullSchedule = ScheduleModel(
        id: 'sch2',
        clinicId: 'c1',
        doctorId: 'd1',
        scheduleDate: DateTime.now(),
        startTime: '08:00:00',
        endTime: '11:00:00',
        capacity: 10,
        bookedCount: 10,
        status: 'full',
      );

      expect(fullSchedule.availableSlots, 0);
      expect(fullSchedule.isAvailable, false);
    });

    test('AuthRepository authenticates user in demo mode', () async {
      final repo = AuthRepository();
      final result = await repo.signInWithEmailPassword(
        email: 'test@simklinik.local',
        password: 'Password123!',
      );

      expect(result is ApiSuccess<AuthUser>, true);
      expect(
        (result as ApiSuccess<AuthUser>).data.email,
        'test@simklinik.local',
      );
      expect(repo.isAuthenticated, true);
    });

    test(
      'DoctorRepository returns specialties and doctors in demo mode',
      () async {
        final repo = DoctorRepository();
        final specialtiesRes = await repo.getSpecialties();
        expect(specialtiesRes is ApiSuccess, true);

        final doctorsRes = await repo.getDoctors();
        expect(doctorsRes is ApiSuccess, true);
      },
    );

    test(
      'BookingRepository atomic booking succeeds and allocates queue ticket',
      () async {
        final repo = BookingRepository();
        final result = await repo.bookAppointmentAtomic(
          scheduleId: 'sch_d1_1',
          patientId: 'p1',
          notes: 'Keluhan flu batuk demam',
        );

        expect(result is ApiSuccess<BookingResult>, true);
        final booking = (result as ApiSuccess<BookingResult>).data;
        expect(booking.success, true);
        expect(booking.bookingReference.startsWith('APT-'), true);
        expect(booking.ticketCode.startsWith('A-'), true);
      },
    );
  });

  group('Widget Tests - UI Components & Semantic Badges', () {
    testWidgets(
      'AppStatusBadge displays correct text and semantic color for statuses',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AppStatusBadge(
                    label: 'Menunggu',
                    backgroundColor: Colors.amber,
                    textColor: Colors.black,
                    icon: Icons.hourglass_top,
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Menunggu'), findsOneWidget);
        expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
      },
    );

    testWidgets('AppEmptyView renders title, description, and action button', (
      tester,
    ) async {
      bool actionClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyView(
              title: 'Belum Ada Tiket',
              description: 'Silakan pesan jadwal terlebih dahulu.',
              actionLabel: 'Cari Jadwal',
              onAction: () => actionClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Belum Ada Tiket'), findsOneWidget);
      expect(
        find.text('Silakan pesan jadwal terlebih dahulu.'),
        findsOneWidget,
      );
      expect(find.text('Cari Jadwal'), findsOneWidget);

      await tester.tap(find.text('Cari Jadwal'));
      expect(actionClicked, true);
    });

    testWidgets('SIMKlinikApp smoke test renders navigation and theme', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: SIMKlinikApp()));
      await tester.pumpAndSettle();

      // Verify app rendered home screen with SIMKlinik branding
      expect(find.textContaining('Selamat Datang'), findsOneWidget);
      expect(find.text('Layanan Utama'), findsOneWidget);
      expect(find.text('Cari Dokter'), findsAtLeastNWidgets(1));
    });
  });
}
