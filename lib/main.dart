import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/di/service_locator.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local caching
  await Hive.initFlutter();

  // Setup dependency injection
  await setupDependencies();

  final storage = SecureStorageService();
  final user = await storage.getUser();
  final userPhone = user?['phone'];
  final userName = user?['name'];
  final role = await storage.getRole();

  runApp(MyApp(userPhone: userPhone, userName: userName, role: role));
}

class MyApp extends StatelessWidget {
  final String? userPhone;
  final String? userName;
  final String? role;

  const MyApp({super.key, this.userPhone, this.userName, this.role});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => getIt<AuthBloc>(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Delivery Express Mobility',

        // 🌞 Light Theme Premium
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
          primaryColor: const Color(0xFF29B6F6),
          useMaterial3: true,
        ),

        // 🌙 Dark Theme Premium Glass
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          primaryColor: const Color(0xFF29B6F6),
          useMaterial3: true,
        ),

        // 🔥 Suit automatiquement le système
        themeMode: ThemeMode.system,

        initialRoute: AppRouter.initialRoute,
        routes: AppRouter.routes(userName: userName),
      ),
    );
  }
}
