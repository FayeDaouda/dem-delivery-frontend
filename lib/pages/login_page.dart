import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/service_locator.dart';
import '../core/storage/secure_storage_service.dart';
import '../core/widgets/app_dialog.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';

/// Login OTP-only:
/// Téléphone -> OTP -> Home (sans mot de passe)
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());

  bool _showOtpScreen = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _phoneController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = 60);

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendCountdown <= 1) {
        timer.cancel();
        setState(() => _resendCountdown = 0);
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  void _handleSendOtp() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      AppDialog.showWarning(context, 'Veuillez entrer votre numéro');
      return;
    }

    context.read<AuthBloc>().add(AuthSendOtpEvent(phone: phone));
  }

  void _handleVerifyOtp() {
    final otp = _otpControllers.map((c) => c.text).join().trim();
    if (otp.length != 6) {
      AppDialog.showWarning(context, 'Le code OTP doit contenir 6 chiffres');
      return;
    }

    context.read<AuthBloc>().add(
          AuthVerifyOtpEvent(
            phone: _phoneController.text.trim(),
            code: otp,
          ),
        );
  }

  Future<void> _handleAuthState(BuildContext context, AuthState state) async {
    if (state is AuthOtpSent) {
      setState(() => _showOtpScreen = true);
      _startResendCountdown();
      await AppDialog.showInfo(context, 'Code OTP envoyé avec succès');
      return;
    }

    if (state is AuthSuccess) {
      if (state.role == 'CLIENT') {
        Navigator.pushReplacementNamed(context, '/clientHome');
      } else if (state.role == 'DRIVER' || state.role == 'LIVREUR') {
        Navigator.pushReplacementNamed(context, '/livreurHome');
      }
      return;
    }

    if (state is AuthOtpVerified) {
      final storage = getIt<SecureStorageService>();
      final role = await storage.getRole();
      print('🔑 ROLE FROM STORAGE after OTP: $role');

      if (!mounted) return;

      if (role == 'CLIENT') {
        print('✅ Redirecting to CLIENT home');
        Navigator.pushReplacementNamed(context, '/clientHome');
        return;
      }

      if (role == 'DRIVER' || role == 'LIVREUR') {
        print('✅ Redirecting to DRIVER home');
        Navigator.pushReplacementNamed(context, '/livreurHome');
        return;
      }

      // OTP validé mais profil incomplet -> inscription
      print('⚠️ No role found, redirecting to signup');
      Navigator.pushReplacementNamed(context, '/signup');
      return;
    }

    if (state is AuthFailure) {
      await AppDialog.showError(context, state.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<AuthBloc, AuthState>(
        listener: _handleAuthState,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: _showOtpScreen
                  ? _buildOtpScreen(context)
                  : _buildPhoneScreen(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneScreen(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        Text(
          'Bienvenue !',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: const Color(0xFF2196F3),
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Connexion avec numéro de téléphone',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 40),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: 'Saisissez votre numéro (+221...)',
            hintStyle: TextStyle(color: Color(0xFF2196F3)),
            prefixIcon: Icon(
              Icons.phone_outlined,
              color: Color(0xFF2196F3),
            ),
            filled: true,
            fillColor: Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 32),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleSendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Recevoir le code OTP',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Vous n'avez pas de compte ? ",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/signup'),
              child: Text(
                'Créer un compte',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF2196F3),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtpScreen(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                _resendTimer?.cancel();
                setState(() {
                  _showOtpScreen = false;
                });
              },
            ),
            const SizedBox(width: 8),
            Text(
              'Vérification OTP',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Text(
          'Entrez le code reçu',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF2196F3),
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'Code envoyé à ${_phoneController.text.trim()}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            6,
            (index) => SizedBox(
              width: 48,
              height: 58,
              child: TextField(
                controller: _otpControllers[index],
                keyboardType: TextInputType.number,
                maxLength: 1,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2196F3),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    FocusScope.of(context).nextFocus();
                  } else if (value.isEmpty && index > 0) {
                    FocusScope.of(context).previousFocus();
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleVerifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Vérifier',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        if (_resendCountdown > 0)
          Text(
            'Renvoyer dans ${_resendCountdown}s',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
          )
        else
          TextButton(
            onPressed: _handleSendOtp,
            child: Text(
              'Renvoyer le code',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF2196F3),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
      ],
    );
  }
}
