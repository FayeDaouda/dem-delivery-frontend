import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/di/service_locator.dart';
import '../core/storage/secure_storage_service.dart';
import '../core/utils/navigation_helper.dart';
import '../features/auth/domain/repositories/auth_repository.dart';

/// Widget réutilisable pour le Splash Screen
///
/// Fonctionnalités :
/// - Affiche l'animation du logo DEM
/// - Vérifie si le JWT existe (SecureStorage)
/// - Si token valide → Home Client ou Home Driver selon rôle
/// - Sinon → OnboardingScreen
class SplashScreenWidget extends StatefulWidget {
  /// Route vers l'écran d'onboarding (par défaut '/onboarding')
  final String onboardingRoute;

  /// Route vers l'écran de connexion (par défaut '/login')
  final String loginRoute;

  /// Route vers le home client (par défaut '/clientHome')
  final String clientHomeRoute;

  /// Route vers le home driver (par défaut '/livreurHome')
  final String driverHomeRoute;

  /// Chemin vers l'image du logo (par défaut 'assets/images/logoo.png')
  final String logoPath;

  /// Durée de l'animation en millisecondes (par défaut 1500)
  final int animationDuration;

  /// Couleur de fond du splash screen
  final Color? backgroundColor;

  const SplashScreenWidget({
    super.key,
    this.onboardingRoute = '/onboarding',
    this.loginRoute = '/login',
    this.clientHomeRoute = '/clientHome',
    this.driverHomeRoute = '/livreurHome',
    this.logoPath = 'assets/images/logoo.png',
    this.animationDuration = 1500,
    this.backgroundColor,
  });

  @override
  State<SplashScreenWidget> createState() => _SplashScreenWidgetState();
}

class _SplashScreenWidgetState extends State<SplashScreenWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late SecureStorageService _storage;

  @override
  void initState() {
    super.initState();

    // Initialisation du service de stockage sécurisé
    _storage = SecureStorageService();

    // Configuration du contrôleur d'animation
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.animationDuration),
    );

    // Animation de scale (zoom avec rebond élastique)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.95), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 25),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    // Animation de fade (apparition progressive avec accélération)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Démarrer l'animation puis vérifier l'authentification
    _controller.forward().whenComplete(() => _checkAuthAndNavigate());
  }

  /// Vérifie l'authentification et navigue vers l'écran approprié
  Future<void> _checkAuthAndNavigate() async {
    try {
      final accessToken = await _storage.getAccessToken();
      final refreshToken = await _storage.getRefreshToken();

      if (!mounted) return;

      // 1) Access token valide -> Home
      if (accessToken != null &&
          accessToken.isNotEmpty &&
          !_isJwtExpired(accessToken)) {
        await _navigateToHomeByRoleOrFallback();
        return;
      }

      // 2) Access expiré mais refresh présent -> refresh silencieux
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final refreshed = await getIt<AuthRepository>().refreshSession();
        if (!mounted) return;

        if (refreshed) {
          await _navigateToHomeByRoleOrFallback();
          return;
        }
      }

      // 3) Pas de session -> onboarding/login
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, widget.onboardingRoute);
    } catch (e) {
      debugPrint('Erreur lors de la vérification auth: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, widget.onboardingRoute);
      }
    }
  }

  Future<void> _navigateToHomeByRoleOrFallback() async {
    final role = await _storage.getRole();
    final driverType = await _storage.getDriverType();
    final user = await _storage.getUser();

    bool? parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is String) {
        final normalized = value.toLowerCase();
        if (normalized == 'true') return true;
        if (normalized == 'false') return false;
      }
      return null;
    }

    final hasActivePass = parseBool(user?['hasActivePass']);

    if (!mounted) return;

    if (role == null || role.isEmpty) {
      Navigator.pushReplacementNamed(context, widget.onboardingRoute);
      return;
    }

    final route = NavigationHelper.getHomeRoute(
      role: role,
      driverType: driverType,
      hasActivePass: hasActivePass,
    );

    Navigator.pushReplacementNamed(context, route);
  }

  bool _isJwtExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = parts[1];
      final normalized = payload.padRight((payload.length + 3) & ~3, '=');
      final decoded = String.fromCharCodes(
        base64Url.decode(normalized),
      );

      final expMatch = RegExp(r'"exp"\s*:\s*(\d+)').firstMatch(decoded);
      if (expMatch == null) return true;

      final exp = int.tryParse(expMatch.group(1)!);
      if (exp == null) return true;

      final expiration = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiration);
    } catch (_) {
      return true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide > 600;
    final logoSize = isTablet ? 180.0 : 120.0;

    return Scaffold(
      backgroundColor: widget.backgroundColor ?? Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: widget.logoPath.toLowerCase().endsWith('.svg')
                ? SvgPicture.asset(
                    widget.logoPath,
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                    placeholderBuilder: (_) => SizedBox(
                      width: logoSize,
                      height: logoSize,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : Image.asset(
                    widget.logoPath,
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Si l'image ne charge pas, afficher un logo de secours
                      return Icon(
                        Icons.local_shipping,
                        size: logoSize,
                        color: const Color(0xFF29B6F6),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
