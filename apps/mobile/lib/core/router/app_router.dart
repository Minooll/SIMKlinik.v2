import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/booking/data/booking_repository.dart';
import '../../features/booking/presentation/booking_screen.dart';
import '../../features/booking/presentation/booking_success_screen.dart';
import '../../features/clinics_doctors/domain/schedule_model.dart';
import '../../features/clinics_doctors/presentation/doctor_detail_screen.dart';
import '../../features/clinics_doctors/presentation/doctor_search_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/main_shell.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/queue/presentation/queue_list_screen.dart';
import '../../features/queue/presentation/queue_ticket_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    // Auth Routes
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // Main App Shell with Bottom Navigation
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/doctors',
          builder: (context, state) {
            final specId = state.uri.queryParameters['specialtyId'];
            return DoctorSearchScreen(initialSpecialtyId: specId);
          },
        ),
        GoRoute(
          path: '/tickets',
          builder: (context, state) => const QueueListScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),

    // Detail & Flow Routes
    GoRoute(
      path: '/doctor/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return DoctorDetailScreen(doctorId: id);
      },
    ),
    GoRoute(
      path: '/booking/:scheduleId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final scheduleId = state.pathParameters['scheduleId'] ?? '';
        final schedule = state.extra as ScheduleModel?;
        return BookingScreen(scheduleId: scheduleId, schedule: schedule);
      },
    ),
    GoRoute(
      path: '/booking-success',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final result = state.extra as BookingResult?;
        return BookingSuccessScreen(result: result);
      },
    ),
    GoRoute(
      path: '/ticket/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return QueueTicketScreen(ticketId: id);
      },
    ),
  ],
  redirect: (context, state) {
    final authRepo = AuthRepository();
    final isAuth = authRepo.isAuthenticated;
    final isLoggingIn =
        state.uri.path == '/login' || state.uri.path == '/register';

    if (!isAuth && !isLoggingIn) {
      return '/login';
    }
    if (isAuth && isLoggingIn) {
      return '/home';
    }
    return null;
  },
);
