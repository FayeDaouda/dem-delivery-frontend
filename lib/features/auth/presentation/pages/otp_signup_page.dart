import 'package:delivery_express_mobility_frontend/core/utils/navigation_helper.dart';
import 'package:delivery_express_mobility_frontend/core/widgets/app_dialog.dart';
import 'package:delivery_express_mobility_frontend/design_system/tokens/colors.dart';
import 'package:delivery_express_mobility_frontend/design_system/tokens/spacing.dart';
import 'package:delivery_express_mobility_frontend/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:delivery_express_mobility_frontend/widgets/driver_type_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Page d'inscription OTP-Only avec sélection MOTO/VTC
/// Flux complet en 3 étapes :
/// 1. Demander OTP (numéro de téléphone)
/// 2. Vérifier OTP (code SMS)
/// 3. Créer profil + Sélectionner MOTO/VTC
class OtpSignupPage extends StatelessWidget {
  const OtpSignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _OtpSignupPageContent();
  }
}

class _OtpSignupPageContent extends StatefulWidget {
  const _OtpSignupPageContent();

  @override
  State<_OtpSignupPageContent> createState() => _OtpSignupPageContentState();
}

class _OtpSignupPageContentState extends State<_OtpSignupPageContent> {
  // Controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());

  // État local
  int _currentStep = 1; // 1: Phone, 2: OTP, 3: Profile + Driver Type
  String _selectedRole = 'CLIENT'; // CLIENT ou DRIVER
  String? _selectedDriverType; // "MOTO" ou "VTC"

  @override
  void dispose() {
    _phoneController.dispose();
    _fullNameController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join().trim();

  bool get _isStep1Valid =>
      _phoneController.text.trim().isNotEmpty &&
      _phoneController.text.trim().length >= 9;

  bool get _isStep2Valid => _otpCode.length == 6;

  bool get _isStep3Valid =>
      _fullNameController.text.trim().length >= 3 &&
      (_selectedRole == 'CLIENT' || _selectedDriverType != null);

  void _handleSendOTP() {
    if (!_isStep1Valid) {
      AppDialog.showWarning(
        context,
        'Veuillez entrer un numéro valide',
      );
      return;
    }

    final phone = _phoneController.text.trim();
    final formattedPhone = phone.startsWith('+221') ? phone : '+221$phone';

    context.read<AuthBloc>().add(AuthSendOtpEvent(phone: formattedPhone));
  }

  void _handleVerifyOTP() {
    if (!_isStep2Valid) {
      AppDialog.showWarning(context, 'Le code OTP doit contenir 6 chiffres');
      return;
    }

    final phone = _phoneController.text.trim();
    final formattedPhone = phone.startsWith('+221') ? phone : '+221$phone';

    context
        .read<AuthBloc>()
        .add(AuthVerifyOtpEvent(phone: formattedPhone, code: _otpCode));
  }

  void _handleCreateProfile() {
    if (!_isStep3Valid) {
      AppDialog.showWarning(
        context,
        'Nom complet (min 3) requis. Pour DRIVER, choisissez MOTO ou VTC.',
      );
      return;
    }

    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final formattedPhone = phone.startsWith('+221') ? phone : '+221$phone';

    context.read<AuthBloc>().add(
          AuthCreateProfileOtpEvent(
            phone: formattedPhone,
            fullName: fullName,
            role: _selectedRole,
            driverType: _selectedRole == 'DRIVER' ? _selectedDriverType : null,
            preferredLanguage: 'fr',
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Inscription',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // Étape 1: OTP envoyé avec succès
          if (state is AuthOtpSent) {
            setState(() => _currentStep = 2);
            AppDialog.showInfo(context, 'Code OTP envoyé par SMS');
          }

          // Étape 2: OTP vérifié - Récupérer userId et tempToken
          if (state is AuthOtpVerified) {
            // Toujours passer à l'étape 3 après OTP validé
            // (certains backends ne retournent pas userId/tempToken)
            setState(() => _currentStep = 3);
          }

          // Gestion des réponses du backend après vérification OTP
          if (state is AuthSuccess && _currentStep == 2) {
            // Si on reçoit AuthSuccess en step 2 = user existant qui se reconnecte
            final route = NavigationHelper.getHomeRoute(
              role: state.role,
              driverType: state.driverType,
              hasActivePass: state.hasActivePass,
            );

            Navigator.pushReplacementNamed(context, route);
            return;
          }

          // Étape 3: Profil créé avec succès
          if (state is AuthSuccess && _currentStep == 3) {
            AppDialog.showInfo(context, 'Bienvenue !');

            // Navigation conditionnelle avec NavigationHelper
            Future.delayed(const Duration(milliseconds: 500), () {
              if (!context.mounted) return;

              final route = NavigationHelper.getHomeRoute(
                role: state.role,
                driverType: state.driverType,
                hasActivePass: state.hasActivePass,
              );
              Navigator.pushReplacementNamed(context, route);
            });
            return;
          }

          // Erreur
          if (state is AuthFailure) {
            AppDialog.showError(context, state.message);
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DEMSpacing.lg,
                vertical: DEMSpacing.lg,
              ),
              child: _currentStep == 1
                  ? _buildStep1Phone(context)
                  : (_currentStep == 2
                      ? _buildStep2OTP(context)
                      : _buildStep3Profile(context)),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // ÉTAPE 1: DEMANDER OTP (Numéro de téléphone)
  // ============================================================================

  Widget _buildStep1Phone(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress indicator
        _buildProgressIndicator(1),
        const SizedBox(height: DEMSpacing.xl),

        // Titre
        Text(
          'Entrez votre numéro de téléphone',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: DEMColors.gray900,
              ),
        ),
        const SizedBox(height: DEMSpacing.sm),
        Text(
          'Nous vous enverrons un code OTP par SMS',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DEMColors.gray600,
              ),
        ),
        const SizedBox(height: DEMSpacing.xl),

        // Input téléphone
        TextField(
          controller: _phoneController,
          enabled: _currentStep == 1,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: '77 123 45 67',
            prefixText: '+221 ',
            prefixStyle: const TextStyle(color: DEMColors.gray900),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DEMSpacing.md,
              vertical: DEMSpacing.md,
            ),
          ),
        ),
        const SizedBox(height: DEMSpacing.xl),

        // Bouton suivant
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleSendOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DEMColors.primary,
                  disabledBackgroundColor: DEMColors.primary.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(
                    vertical: DEMSpacing.md,
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Recevoir OTP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isLoading ? Colors.grey : Colors.white,
                        ),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ============================================================================
  // ÉTAPE 2: VÉRIFIER OTP (Code SMS)
  // ============================================================================

  Widget _buildStep2OTP(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress indicator
        _buildProgressIndicator(2),
        const SizedBox(height: DEMSpacing.xl),

        // Titre
        Text(
          'Vérifiez votre numéro',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: DEMColors.gray900,
              ),
        ),
        const SizedBox(height: DEMSpacing.sm),
        Text(
          'Entrez le code reçu par SMS',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DEMColors.gray600,
              ),
        ),
        const SizedBox(height: DEMSpacing.xl),

        // Inputs OTP (6 champs)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 48,
              child: TextField(
                controller: _otpControllers[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  counter: const SizedBox.shrink(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(DEMSpacing.md),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    FocusScope.of(context).nextFocus();
                  }
                  setState(() {});
                },
              ),
            );
          }),
        ),
        const SizedBox(height: DEMSpacing.xl),

        // Bouton Vérifier
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (_isStep2Valid && !isLoading) ? _handleVerifyOTP : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DEMColors.primary,
                  disabledBackgroundColor: DEMColors.primary.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(
                    vertical: DEMSpacing.md,
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Vérifier',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            );
          },
        ),

        // Renvoi OTP
        const SizedBox(height: DEMSpacing.lg),
        Center(
          child: TextButton(
            onPressed: _handleSendOTP,
            child: Text(
              'Renvoyer le code',
              style: TextStyle(
                color: DEMColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // ÉTAPE 3: CRÉER PROFIL + SÉLECTIONNER DRIVER TYPE
  // ============================================================================

  Widget _buildStep3Profile(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress indicator
        _buildProgressIndicator(3),
        const SizedBox(height: DEMSpacing.xl),

        // Titre
        Text(
          'Complétez votre profil',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: DEMColors.gray900,
              ),
        ),
        const SizedBox(height: DEMSpacing.sm),
        Text(
          'Quelques informations pour commencer',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DEMColors.gray600,
              ),
        ),
        const SizedBox(height: DEMSpacing.xl),

        // Nom complet
        TextField(
          controller: _fullNameController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Nom complet',
            hintText: 'Moussa Diallo',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DEMSpacing.md,
              vertical: DEMSpacing.md,
            ),
          ),
        ),
        const SizedBox(height: DEMSpacing.md),

        Text(
          'Rôle',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: DEMColors.gray900,
              ),
        ),
        const SizedBox(height: DEMSpacing.sm),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('CLIENT'),
                selected: _selectedRole == 'CLIENT',
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() {
                    _selectedRole = 'CLIENT';
                    _selectedDriverType = null;
                  });
                },
              ),
            ),
            const SizedBox(width: DEMSpacing.md),
            Expanded(
              child: ChoiceChip(
                label: const Text('DRIVER'),
                selected: _selectedRole == 'DRIVER',
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() {
                    _selectedRole = 'DRIVER';
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: DEMSpacing.lg),

        if (_selectedRole == 'DRIVER') ...[
          DriverTypeSelector(
            selectedType: _selectedDriverType,
            onSelected: (type) {
              setState(() => _selectedDriverType = type);
            },
            isLoading: false,
          ),
          const SizedBox(height: DEMSpacing.xl),
        ],

        // Bouton S'inscrire
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (_isStep3Valid && !isLoading) ? _handleCreateProfile : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DEMColors.primary,
                  disabledBackgroundColor: DEMColors.primary.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(
                    vertical: DEMSpacing.md,
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'S\'inscrire',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ============================================================================
  // WIDGETS UTILITAIRES
  // ============================================================================

  Widget _buildProgressIndicator(int currentStep) {
    return Row(
      children: List.generate(3, (index) {
        final stepNumber = index + 1;
        final isActive = stepNumber <= currentStep;

        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isActive ? DEMColors.primary : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
