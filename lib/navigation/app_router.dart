import 'package:delivery_express_mobility_frontend/features/admin/navigation/admin_routes.dart';
import 'package:delivery_express_mobility_frontend/features/admin/presentation/pages/admin_home_page.dart';
import 'package:delivery_express_mobility_frontend/features/auth/presentation/pages/kyc_submission_page.dart';
import 'package:delivery_express_mobility_frontend/features/auth/presentation/pages/login_page.dart';
import 'package:delivery_express_mobility_frontend/features/auth/presentation/pages/onboarding_page.dart';
import 'package:delivery_express_mobility_frontend/features/auth/presentation/pages/otp_signup_page.dart';
import 'package:delivery_express_mobility_frontend/features/auth/presentation/pages/splash_page.dart';
import 'package:delivery_express_mobility_frontend/features/client/navigation/client_routes.dart';
import 'package:delivery_express_mobility_frontend/features/client/presentation/pages/client_home_entry_page.dart';
import 'package:delivery_express_mobility_frontend/features/driver_moto/navigation/driver_moto_routes.dart';
import 'package:delivery_express_mobility_frontend/features/driver_moto/presentation/pages/driver_moto_home_entry_page.dart';
import 'package:delivery_express_mobility_frontend/features/driver_vtc/navigation/driver_vtc_routes.dart';
import 'package:delivery_express_mobility_frontend/features/driver_vtc/presentation/pages/driver_dashboard_pro_page.dart';
import 'package:delivery_express_mobility_frontend/features/driver_vtc/presentation/pages/driver_passes_purchase_page.dart';
import 'package:delivery_express_mobility_frontend/features/driver_vtc/presentation/pages/driver_rides_history_page.dart';
import 'package:delivery_express_mobility_frontend/features/driver_vtc/presentation/pages/driver_vtc_home_page.dart';
import 'package:delivery_express_mobility_frontend/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';

abstract class AppRouter {
  AppRouter._();

  static const initialRoute = '/splash';

  static Map<String, WidgetBuilder> routes({String? userName}) {
    return {
      '/splash': (context) => const SplashPage(),
      '/onboarding': (context) => const OnboardingPage(),
      '/login': (context) => const LoginPage(),
      '/signup': (context) => const OtpSignupPage(),
      '/kycSubmission': (context) => const KycSubmissionPage(),
      '/profile': (context) => const ProfilePage(),

      // Pro role-based routes
      ClientRoutes.home: (context) => ClientHomeEntryPage(
            userName: userName,
          ),
      DriverMotoRoutes.home: (context) => const DriverMotoHomeEntryPage(),
      DriverVtcRoutes.passPurchase: (context) =>
          const DriverPassesPurchasePage(),
      DriverVtcRoutes.home: (context) => const DriverVtcHomePage(),
      DriverVtcRoutes.history: (context) => const DriverRidesHistoryPage(),
      DriverVtcRoutes.dashboard: (context) => const DriverDashboardProPage(),
      AdminRoutes.home: (context) => const AdminHomePage(),

      // Legacy aliases (compatibilité)
      '/clientHome': (context) => ClientHomeEntryPage(
            userName: userName,
          ),
      '/livreurHome': (context) => const DriverVtcHomePage(),
      '/driver/passes/purchase': (context) => const DriverPassesPurchasePage(),
      '/driver/vtc/home': (context) => const DriverVtcHomePage(),
      '/driver/history': (context) => const DriverRidesHistoryPage(),
      '/driver/dashboard/pro': (context) => const DriverDashboardProPage(),
      '/admin/home': (context) => const AdminHomePage(),
    };
  }
}
