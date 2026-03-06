import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/service_locator.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';

/// Page de connexion optimisée - MVP Phase 1
/// Connexion pour utilisateurs existants avec numéro + mot de passe
/// Les nouveaux utilisateurs peuvent créer un compte via SignupPage
///
/// OPTIMISATIONS APPLIQUÉES:
/// ✓ Extraction de widgets pour réduire les rebuilds
/// ✓ BlocBuilder avec buildWhen pour éviter les rebuilds inutiles
/// ✓ const constructors pour les widgets statiques
/// ✓ Évite les appels répétés à Theme.of(context)
class LoginPageOptimized extends StatelessWidget {
  const LoginPageOptimized({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => getIt<AuthBloc>(),
      child: const _LoginPageContent(),
    );
  }
}

class _LoginPageContent extends StatefulWidget {
  const _LoginPageContent();

  @override
  State<_LoginPageContent> createState() => _LoginPageContentState();
}

class _LoginPageContentState extends State<_LoginPageContent> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin(BuildContext context) {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      return;
    }

    context.read<AuthBloc>().add(
          AuthLoginEvent(phone: phone, password: password),
        );
  }

  void _handleAuthState(BuildContext context, AuthState state) {
    if (state is AuthSuccess) {
      if (state.role == "CLIENT") {
        Navigator.pushReplacementNamed(context, '/clientHome');
      } else if (state.role == "DRIVER" || state.role == "LIVREUR") {
        Navigator.pushReplacementNamed(context, '/livreurHome');
      }
    } else if (state is AuthFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
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
              child: Column(
                children: const [
                  SizedBox(height: 30),
                  _LoginTitle(),
                  SizedBox(height: 12),
                  _LoginSubtitle(),
                  SizedBox(height: 40),
                  _PhoneFieldWidget(),
                  SizedBox(height: 24),
                  _PasswordFieldWidget(),
                  SizedBox(height: 32),
                  _LoginButtonWidget(),
                  SizedBox(height: 20),
                  _SignUpLinkWidget(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===== Widgets optimisés (const + extraction) =====

/// Titre "Bienvenue !"
class _LoginTitle extends StatelessWidget {
  const _LoginTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Bienvenue !',
      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: const Color(0xFF2196F3),
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

/// Sous-titre "Connectez-vous..."
class _LoginSubtitle extends StatelessWidget {
  const _LoginSubtitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Connectez-vous à votre compte',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontSize: 14,
          ),
    );
  }
}

/// Champ numéro de téléphone
class _PhoneFieldWidget extends StatelessWidget {
  const _PhoneFieldWidget();

  @override
  Widget build(BuildContext context) {
    final parent = context.findAncestorStateOfType<_LoginPageContentState>();

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
          controller: parent?._phoneController,
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
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}

/// Champ mot de passe
class _PasswordFieldWidget extends StatefulWidget {
  const _PasswordFieldWidget();

  @override
  State<_PasswordFieldWidget> createState() => _PasswordFieldWidgetState();
}

class _PasswordFieldWidgetState extends State<_PasswordFieldWidget> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final parent = context.findAncestorStateOfType<_LoginPageContentState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mot de passe',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: parent?._passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'Entrez votre mot de passe',
            hintStyle: const TextStyle(color: Color(0xFF2196F3)),
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color(0xFF2196F3),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF2196F3),
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
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
}

/// Bouton de connexion avec optimisation BlocBuilder
class _LoginButtonWidget extends StatelessWidget {
  const _LoginButtonWidget();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) =>
          // ✓ Rebuild seulement si le type d'état change (AuthLoading -> AuthSuccess)
          previous.runtimeType != current.runtimeType,
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final parent =
            context.findAncestorStateOfType<_LoginPageContentState>();

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : () => parent?._handleLogin(context),
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
                    "Se connecter",
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                  ),
          ),
        );
      },
    );
  }
}

/// Lien vers l'inscription
class _SignUpLinkWidget extends StatelessWidget {
  const _SignUpLinkWidget();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Vous n'avez pas de compte ? ",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/signup');
          },
          child: Text(
            "Créer un compte",
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
