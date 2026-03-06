import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/widgets/app_dialog.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';

/// Page d'inscription avec OTP - MVP Phase 1
/// Flux : Numéro + Rôle → OTP → Création profil → Home
class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SignupPageContent();
  }
}

class _SignupPageContent extends StatefulWidget {
  const _SignupPageContent();

  @override
  State<_SignupPageContent> createState() => _SignupPageContentState();
}

class _SignupPageContentState extends State<_SignupPageContent> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _avatarController = TextEditingController();
  String? _selectedRole;
  bool _showOTPScreen = false;
  bool _showProfileScreen = false;

  String _normalizeRole(String? role) {
    final value = role?.trim().toUpperCase();
    if (value == 'LIVREUR') return 'DRIVER';
    return value ?? '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _fullNameController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  void _handleSendOTP(BuildContext context) {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      AppDialog.showWarning(context, 'Veuillez entrer votre numéro');
      return;
    }

    if (_selectedRole == null) {
      AppDialog.showWarning(context, 'Veuillez sélectionner votre profil');
      return;
    }

    print(
      '📝 [SIGNUP UI] Send OTP with phone=$phone, selectedRole=$_selectedRole',
    );

    // Envoyer OTP
    context.read<AuthBloc>().add(AuthSendOtpEvent(phone: phone));
  }

  void _handleCreateProfile(BuildContext context) {
    final role = _selectedRole;
    if (role == null) {
      AppDialog.showWarning(context, 'Rôle manquant pour créer le profil');
      return;
    }

    final fullName = _fullNameController.text.trim();
    final avatar = _avatarController.text.trim();

    print(
      '📝 [SIGNUP UI] Create profile with phone=${_phoneController.text.trim()}, role=$role, fullName=${fullName.isEmpty ? null : fullName}, avatar=${avatar.isEmpty ? null : avatar}',
    );

    context.read<AuthBloc>().add(
          AuthCreateProfileEvent(
            phone: _phoneController.text.trim(),
            role: role,
            fullName: _fullNameController.text.trim().isEmpty
                ? null
                : _fullNameController.text.trim(),
            avatar: _avatarController.text.trim().isEmpty
                ? null
                : _avatarController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthOtpSent) {
            setState(() {
              _showOTPScreen = true;
              _showProfileScreen = false;
            });
            AppDialog.showInfo(context, 'Code OTP envoyé avec succès');
          }

          if (state is AuthOtpVerified) {
            setState(() {
              _showProfileScreen = true;
            });
          }

          // Inscription réussie
          if (state is AuthSuccess) {
            final selectedRole = _normalizeRole(_selectedRole);
            final returnedRole = _normalizeRole(state.role);

            // Cas important: numéro déjà existant avec un autre rôle
            if (selectedRole.isNotEmpty &&
                returnedRole.isNotEmpty &&
                selectedRole != returnedRole) {
              context.read<AuthBloc>().add(const AuthLogoutEvent());

              setState(() {
                _showOTPScreen = false;
                _showProfileScreen = false;
              });

              AppDialog.showError(
                context,
                'Ce numéro est déjà associé au profil ${state.role}. '
                'Utilisez un autre numéro pour créer un compte Driver.',
              );
              return;
            }

            if (state.role == "CLIENT") {
              Navigator.pushReplacementNamed(context, '/clientHome');
            } else if (state.role == "DRIVER" || state.role == "LIVREUR") {
              Navigator.pushReplacementNamed(context, '/livreurHome');
            }
          }

          // Erreur
          if (state is AuthFailure) {
            AppDialog.showError(context, state.message);
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: _showProfileScreen
                  ? _buildProfileScreen(context)
                  : (_showOTPScreen
                      ? _buildOTPScreen(context)
                      : _buildPhoneRoleScreen(context)),
            ),
          ),
        ),
      ),
    );
  }

  /// Écran 1: Numéro + Sélection de rôle
  Widget _buildPhoneRoleScreen(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        Text(
          'Créer un compte',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: const Color(0xFF2196F3),
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Inscrivez-vous pour commencer',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 40),
        _buildPhoneField(),
        const SizedBox(height: 24),
        _buildRoleSelection(),
        const SizedBox(height: 32),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _handleSendOTP(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
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
                        "Recevoir le code OTP",
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                      ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildLoginLink(context),
      ],
    );
  }

  /// Écran 2: Vérification OTP
  Widget _buildOTPScreen(BuildContext context) {
    return OTPVerificationWidget(
      phoneNumber: _phoneController.text.trim(),
      onBackPressed: () {
        setState(() {
          _showOTPScreen = false;
          _showProfileScreen = false;
        });
      },
    );
  }

  /// Écran 3: Création de profil (nom/avatar optionnels)
  Widget _buildProfileScreen(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _showProfileScreen = false;
                  _showOTPScreen = true;
                });
              },
            ),
            const SizedBox(width: 8),
            Text(
              'Créer votre profil',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _fullNameController,
          decoration: InputDecoration(
            hintText: 'Nom complet (optionnel)',
            prefixIcon: const Icon(Icons.person_outline),
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _avatarController,
          decoration: InputDecoration(
            hintText: 'URL avatar (optionnel)',
            prefixIcon: const Icon(Icons.image_outlined),
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    isLoading ? null : () => _handleCreateProfile(context),
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
                        'Finaliser mon compte',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Champ numéro de téléphone
  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Numéro de Téléphone',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'Saisissez votre numéro (+221...)',
            hintStyle: const TextStyle(color: Color(0xFF2196F3)),
            prefixIcon: const Icon(
              Icons.phone_outlined,
              color: Color(0xFF2196F3),
            ),
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  /// Sélection du rôle
  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sélectionnez votre profil',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRoleCard(
                role: 'CLIENT',
                label: 'Je veux envoyer un colis',
                icon: Icons.shopping_bag_outlined,
                isSelected: _selectedRole == 'CLIENT',
                onTap: () {
                  setState(() {
                    _selectedRole = 'CLIENT';
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRoleCard(
                role: 'DRIVER',
                label: 'Je veux livrer des colis',
                icon: Icons.delivery_dining_outlined,
                isSelected: _selectedRole == 'DRIVER',
                onTap: () {
                  setState(() {
                    _selectedRole = 'DRIVER';
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Carte de sélection de rôle
  Widget _buildRoleCard({
    required String role,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2196F3).withValues(alpha: 0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF2196F3) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? const Color(0xFF2196F3) : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? const Color(0xFF2196F3) : Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lien vers la page de connexion
  Widget _buildLoginLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Vous avez un compte ? ",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: Text(
            "Se connecter",
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

/// Widget de vérification OTP réutilisable
class OTPVerificationWidget extends StatefulWidget {
  final String phoneNumber;
  final VoidCallback onBackPressed;

  const OTPVerificationWidget({
    super.key,
    required this.phoneNumber,
    required this.onBackPressed,
  });

  @override
  State<OTPVerificationWidget> createState() => _OTPVerificationWidgetState();
}

class _OTPVerificationWidgetState extends State<OTPVerificationWidget> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60;
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
        _startResendCountdown();
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleVerifyOTP(BuildContext context) {
    final otp = _otpControllers.map((c) => c.text).join().replaceAll(' ', '');

    if (otp.length != 6) {
      AppDialog.showWarning(context, 'Veuillez entrer tous les 6 chiffres');
      return;
    }

    final maskedOtp = '${otp.substring(0, 2)}****';
    print(
      '📝 [SIGNUP UI] Verify OTP with phone=${widget.phoneNumber}, code=$maskedOtp',
    );

    // Vérifier OTP
    context.read<AuthBloc>().add(
          AuthVerifyOtpEvent(phone: widget.phoneNumber, code: otp),
        );
  }

  void _handleResendOTP() {
    context.read<AuthBloc>().add(AuthSendOtpEvent(phone: widget.phoneNumber));
    _startResendCountdown();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBackPressed,
            ),
            const SizedBox(width: 8),
            Text(
              'Vérification',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        Text(
          'Entrez le code OTP',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF2196F3),
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Nous avons envoyé un code à ${widget.phoneNumber}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 40),
        _buildOTPInputFields(),
        const SizedBox(height: 32),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _handleVerifyOTP(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
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
                        "Vérifier",
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                      ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        _buildResendSection(),
      ],
    );
  }

  /// Champs d'entrée OTP
  Widget _buildOTPInputFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        6,
        (index) => SizedBox(
          width: 50,
          height: 60,
          child: TextField(
            controller: _otpControllers[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey[300]!,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey[300]!,
                ),
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
    );
  }

  /// Section renvoi de OTP
  Widget _buildResendSection() {
    return Column(
      children: [
        Text(
          'Vous n\'avez pas reçu le code ?',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 8),
        if (_resendCountdown > 0)
          Text(
            'Renvoyer dans ${_resendCountdown}s',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[400],
                ),
          )
        else
          TextButton(
            onPressed: _handleResendOTP,
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
