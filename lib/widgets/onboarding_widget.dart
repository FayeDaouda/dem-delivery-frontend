import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/storage/secure_storage_service.dart';

/// Widget réutilisable pour l'Onboarding
///
/// Fonctionnalités :
/// - Vérifie si l'utilisateur a déjà ouvert l'application
/// - Si première fois → Affiche l'onboarding
/// - Sinon → Redirige vers Home (selon le rôle JWT)
class OnboardingWidget extends StatefulWidget {
  /// Clé pour stocker si l'onboarding a été complété
  final String onboardingDoneKey;

  /// Clé pour stocker le rôle sélectionné
  final String selectedRoleKey;

  /// Route vers la page de login (par défaut '/login')
  final String loginRoute;

  /// Route vers le home client (par défaut '/clientHome')
  final String clientHomeRoute;

  /// Route vers le home driver (par défaut '/livreurHome')
  final String driverHomeRoute;

  /// Liste des slides d'onboarding
  final List<OnboardingSlide> slides;

  /// Couleur du bouton principal
  final Color? buttonColor;

  /// Couleur de l'indicateur de page actif
  final Color? activeIndicatorColor;

  /// Couleur de l'indicateur de page inactif
  final Color? inactiveIndicatorColor;

  /// Texte du bouton de démarrage
  final String startButtonText;

  /// Si true, affiche la sélection de rôle avant l'onboarding
  final bool requireRoleSelection;

  const OnboardingWidget({
    super.key,
    this.onboardingDoneKey = 'onboarding_done',
    this.selectedRoleKey = 'selected_role',
    this.loginRoute = '/login',
    this.clientHomeRoute = '/clientHome',
    this.driverHomeRoute = '/livreurHome',
    this.slides = const [],
    this.buttonColor,
    this.activeIndicatorColor,
    this.inactiveIndicatorColor,
    this.startButtonText = 'Commencer',
    this.requireRoleSelection = true,
  });

  @override
  State<OnboardingWidget> createState() => _OnboardingWidgetState();
}

class _OnboardingWidgetState extends State<OnboardingWidget>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = true;
  bool _showRoleSelection = false;
  String? _selectedRole;

  late AnimationController _pulseController;
  late SecureStorageService _storage;

  @override
  void initState() {
    super.initState();

    _storage = SecureStorageService();

    // Animation de pulse pour le bouton
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);

    _checkFirstTimeAndNavigate();
  }

  /// Vérifie si c'est la première ouverture et navigue si nécessaire
  Future<void> _checkFirstTimeAndNavigate() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Vérifier si l'onboarding a déjà été complété
      final onboardingDone = prefs.getBool(widget.onboardingDoneKey) ?? false;

      if (onboardingDone) {
        // Onboarding déjà complété, vérifier si l'utilisateur est connecté
        final token = await _storage.getAccessToken();

        if (!mounted) return;

        if (token != null && token.isNotEmpty) {
          // Utilisateur connecté, rediriger vers home selon rôle
          final role = await _storage.getRole();

          if (!mounted) return;

          if (role == 'CLIENT') {
            Navigator.pushReplacementNamed(context, widget.clientHomeRoute);
          } else if (role == 'DRIVER' || role == 'LIVREUR') {
            Navigator.pushReplacementNamed(context, widget.driverHomeRoute);
          } else {
            // Rôle invalide, aller au login
            Navigator.pushReplacementNamed(context, widget.loginRoute);
          }
        } else {
          // Pas de token, aller au login
          Navigator.pushReplacementNamed(context, widget.loginRoute);
        }
        return;
      }

      // Première fois, charger le rôle si nécessaire
      if (widget.requireRoleSelection) {
        final role = prefs.getString(widget.selectedRoleKey);
        if (!mounted) return;
        setState(() {
          _selectedRole = role;
          _showRoleSelection = role == null;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification de l\'onboarding: $e');
      // En cas d'erreur, afficher l'onboarding
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Sélectionne un rôle
  Future<void> _selectRole(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(widget.selectedRoleKey, role);

      if (!mounted) return;
      setState(() {
        _selectedRole = role;
        _showRoleSelection = false;
      });
    } catch (e) {
      debugPrint('Erreur lors de la sélection du rôle: $e');
    }
  }

  /// Complète l'onboarding et navigue vers le login
  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(widget.onboardingDoneKey, true);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, widget.loginRoute);
    } catch (e) {
      debugPrint('Erreur lors de la complétion de l\'onboarding: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_showRoleSelection) {
      return _RoleSelectionScreen(
        onSelectRole: _selectRole,
        buttonColor: widget.buttonColor,
      );
    }

    return _OnboardingSlidesView(
      pageController: _pageController,
      slides: widget.slides.isNotEmpty ? widget.slides : _defaultSlides,
      currentPage: _currentPage,
      selectedRole: _selectedRole,
      pulseController: _pulseController,
      onPageChanged: (index) => setState(() => _currentPage = index),
      onComplete: _completeOnboarding,
      buttonColor: widget.buttonColor ?? const Color(0xFF35CBF0),
      activeIndicatorColor:
          widget.activeIndicatorColor ?? const Color(0xFF33B7EB),
      inactiveIndicatorColor: widget.inactiveIndicatorColor ?? Colors.grey,
      startButtonText: widget.startButtonText,
    );
  }

  // Slides par défaut
  static const List<OnboardingSlide> _defaultSlides = [
    OnboardingSlide(
      title: 'Bienvenue !',
      description:
          'Découvrez Delivery Express Mobility, votre solution rapide et fiable.',
      imagePath: 'assets/images/logo.png',
    ),
    OnboardingSlide(
      title: 'Sécurité & suivi',
      description:
          'Profitez d\'un service sécurisé et d\'un suivi en temps réel.',
      imagePath: 'assets/images/logo.png',
    ),
  ];
}

/// Modèle pour un slide d'onboarding
class OnboardingSlide {
  final String title;
  final String description;
  final String imagePath;

  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

/// Vue des slides d'onboarding
class _OnboardingSlidesView extends StatelessWidget {
  final PageController pageController;
  final List<OnboardingSlide> slides;
  final int currentPage;
  final String? selectedRole;
  final AnimationController pulseController;
  final Function(int) onPageChanged;
  final VoidCallback onComplete;
  final Color buttonColor;
  final Color activeIndicatorColor;
  final Color inactiveIndicatorColor;
  final String startButtonText;

  const _OnboardingSlidesView({
    required this.pageController,
    required this.slides,
    required this.currentPage,
    required this.selectedRole,
    required this.pulseController,
    required this.onPageChanged,
    required this.onComplete,
    required this.buttonColor,
    required this.activeIndicatorColor,
    required this.inactiveIndicatorColor,
    required this.startButtonText,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide > 600;

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: pageController,
            itemCount: slides.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final slide = slides[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      slide.imagePath,
                      width: isTablet ? 250 : 180,
                      height: isTablet ? 250 : 180,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.image_not_supported,
                          size: isTablet ? 250 : 180,
                          color: Colors.grey,
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    Text(
                      slide.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isTablet ? 36 : 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      slide.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 16,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                    if (selectedRole != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Profil sélectionné: ${selectedRole == 'CLIENT' ? 'Client' : 'Livreur'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slides.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: currentPage == index ? 24 : 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: currentPage == index
                        ? activeIndicatorColor
                        : inactiveIndicatorColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
              }),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ScaleTransition(
                scale: pulseController,
                child: ElevatedButton(
                  onPressed: onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    startButtonText,
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Écran de sélection du rôle
class _RoleSelectionScreen extends StatelessWidget {
  final Future<void> Function(String role) onSelectRole;
  final Color? buttonColor;

  const _RoleSelectionScreen({
    required this.onSelectRole,
    this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Choisissez votre profil',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => onSelectRole('CLIENT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.person),
                  label: const Text('Je suis Client'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => onSelectRole('DRIVER'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.delivery_dining),
                  label: const Text('Je suis Livreur'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
