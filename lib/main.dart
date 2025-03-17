import 'package:flutter/material.dart';
import 'screen/splash_screen.dart';
import 'screen/user_login_screen.dart';
import 'screen/user_signup_screen.dart';
import 'screen/user_dashboard_screen.dart';
import 'screen/complaint_submission_screen.dart';
import 'screen/complaint_history.dart';
import 'screen/complaint_tracking_screen.dart';
import 'screen/role_selection_screen.dart';
import 'screen/admin_login_screen.dart';
import 'screen/admin_dashboard_screen.dart';
import 'screen/complaint_management_screen.dart';
import 'screen/reports_analytics_screen.dart';

void main() {
  runApp(const GrievEaseApp());
}

class GrievEaseApp extends StatelessWidget {
  const GrievEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GrievEase',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/role': (context) => const RoleSelectionScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/login': (context) => const UserLoginScreen(),
        '/signup': (context) => const UserSignupScreen(),
        '/dashboard': (context) => UserDashboardScreen(
            userName: (ModalRoute.of(context)?.settings.arguments is String)
                ? ModalRoute.of(context)?.settings.arguments as String
                : 'User'),
        '/submit-complaint': (context) => ComplaintSubmissionScreen(
            userName: ModalRoute.of(context)?.settings.arguments as String? ??
                'User'),
        '/complaint-history': (context) => ComplaintHistoryScreen(
            userName: ModalRoute.of(context)?.settings.arguments as String? ??
                'User'),
        '/track-complaint': (context) => const ComplaintTrackingScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/complaint-management': (context) => const ComplaintManagementScreen(),
        '/reports-analytics': (context) => const ReportsAnalyticsScreen(),
      },
    );
  }
}
