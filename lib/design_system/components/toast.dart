import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import 'glass_panel.dart';

enum DriverToastType { online, offline, passRequired, info }

enum ToastType { success, error, warning, info }

/// Classe générique pour afficher des toasts personnalisés
class DEMToast {
  static final List<_DEMToastEntry> _activeToasts = [];
  static OverlayEntry? _overlayEntry;

  static void show({
    required BuildContext context,
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final toast = _DEMToastEntry(
      message: message,
      type: type,
      duration: duration,
    );

    _activeToasts.add(toast);
    _updateOverlay(context);

    // Pour les toasts success, durée plus longue pour fade-out doux
    final fadeDuration = type == ToastType.success
        ? const Duration(milliseconds: 800)
        : const Duration(milliseconds: 300);

    Future.delayed(duration - fadeDuration, () {
      toast.shouldFadeOut = true;
      _updateOverlay(context);
    });

    Future.delayed(duration, () {
      _activeToasts.remove(toast);
      if (_activeToasts.isEmpty) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      } else {
        _updateOverlay(context);
      }
    });
  }

  static void _updateOverlay(BuildContext context) {
    _overlayEntry?.remove();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + DEMSpacing.lg,
        left: DEMSpacing.lg,
        right: DEMSpacing.lg,
        child: Column(
          children:
              _activeToasts.map((e) => _DEMToastWidget(toast: e)).toList(),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void dismiss() {
    _activeToasts.clear();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class DriverToast {
  static final List<_ToastEntry> _activeToasts = [];
  static OverlayEntry? _overlayEntry;

  /// Affiche un toast dynamique selon l'état du driver
  static void showDriverStatus({
    required BuildContext context,
    required Map<String, dynamic> userData,
    Duration duration = const Duration(seconds: 4),
  }) {
    String message;
    DriverToastType type;

    if (userData['role'] != 'DRIVER') {
      message = "Utilisateur non-livreur";
      type = DriverToastType.info;
    } else if (userData['hasActivePass'] == true &&
        userData['isOnline'] == true) {
      message =
          "Vous êtes en ligne. Les livraisons autour de vous sont disponibles.";
      type = DriverToastType.online;
    } else if (userData['hasActivePass'] == false) {
      message = "Vous devez activer un pass pour recevoir des livraisons.";
      type = DriverToastType.passRequired;
    } else if (userData['hasActivePass'] == true &&
        userData['isOnline'] == false) {
      message = "Votre pass est actif, mais vous êtes hors ligne.";
      type = DriverToastType.offline;
    } else {
      message = "Statut inconnu";
      type = DriverToastType.info;
    }

    final toast = _ToastEntry(
      message: message,
      type: type,
      duration: duration,
    );

    _activeToasts.add(toast);
    _updateOverlay(context);

    Future.delayed(duration, () {
      _activeToasts.remove(toast);
      if (_activeToasts.isEmpty) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      } else {
        _updateOverlay(context);
      }
    });
  }

  static void _updateOverlay(BuildContext context) {
    _overlayEntry?.remove();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + DEMSpacing.lg,
        left: DEMSpacing.lg,
        right: DEMSpacing.lg,
        child: Column(
          children: _activeToasts.map((e) => _ToastWidget(toast: e)).toList(),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void dismiss() {
    _activeToasts.clear();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _DEMToastEntry {
  final String message;
  final ToastType type;
  final Duration duration;
  bool shouldFadeOut = false;

  _DEMToastEntry({
    required this.message,
    required this.type,
    required this.duration,
  });
}

class _ToastEntry {
  final String message;
  final DriverToastType type;
  final Duration duration;

  _ToastEntry({
    required this.message,
    required this.type,
    required this.duration,
  });
}

class _DEMToastWidget extends StatefulWidget {
  final _DEMToastEntry toast;

  const _DEMToastWidget({required this.toast});

  @override
  State<_DEMToastWidget> createState() => _DEMToastWidgetState();
}

class _DEMToastWidgetState extends State<_DEMToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getToastColor() {
    switch (widget.toast.type) {
      case ToastType.success:
        return Colors.green;
      case ToastType.error:
        return Colors.red;
      case ToastType.warning:
        return Colors.orange;
      case ToastType.info:
        return DEMColors.info;
    }
  }

  IconData _getToastIcon() {
    switch (widget.toast.type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.error:
        return Icons.error_rounded;
      case ToastType.warning:
        return Icons.warning_rounded;
      case ToastType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: DEMSpacing.md),
          child: GlassPanel(
            sigmaX: 20,
            sigmaY: 20,
            tintColor: _getToastColor(),
            opacity: 0.95,
            borderRadius: DEMRadii.borderRadiusXl,
            padding: const EdgeInsets.symmetric(
              horizontal: DEMSpacing.lg,
              vertical: DEMSpacing.md,
            ),
            border: Border.all(
              color: _getToastColor().withOpacity(0.3),
              width: 1,
            ),
            child: Row(
              children: [
                Icon(
                  _getToastIcon(),
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: DEMSpacing.md),
                Expanded(
                  child: Text(
                    widget.toast.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastWidget extends StatefulWidget {
  final _ToastEntry toast;

  const _ToastWidget({required this.toast});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getToastColor() {
    switch (widget.toast.type) {
      case DriverToastType.online:
        return DEMColors.success;
      case DriverToastType.offline:
        return DEMColors.info;
      case DriverToastType.passRequired:
        return DEMColors.warning;
      case DriverToastType.info:
        return DEMColors.info;
    }
  }

  IconData _getToastIcon() {
    switch (widget.toast.type) {
      case DriverToastType.online:
        return Icons.check_circle_rounded;
      case DriverToastType.offline:
        return Icons.cloud_off_rounded;
      case DriverToastType.passRequired:
        return Icons.warning_rounded;
      case DriverToastType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: DEMSpacing.md),
          child: GlassPanel(
            sigmaX: 20,
            sigmaY: 20,
            tintColor: _getToastColor(),
            opacity: 0.95,
            borderRadius: DEMRadii.borderRadiusXl,
            padding: const EdgeInsets.symmetric(
              horizontal: DEMSpacing.lg,
              vertical: DEMSpacing.md,
            ),
            border: Border.all(
              color: _getToastColor().withOpacity(0.3),
              width: 1,
            ),
            child: Row(
              children: [
                Icon(
                  _getToastIcon(),
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: DEMSpacing.md),
                Expanded(
                  child: Text(
                    widget.toast.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
