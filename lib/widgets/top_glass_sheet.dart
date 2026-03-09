import 'package:flutter/material.dart';

import '../design_system/index.dart';

/// Widget réutilisable pour afficher un GlassDraggableSheet depuis le haut
/// avec un bouton de fermeture
class TopGlassSheet extends StatelessWidget {
  final Widget child;
  final VoidCallback? onClose;
  final double minSize;
  final double initialSize;
  final double maxSize;
  final bool showCloseButton;
  final String? title;

  const TopGlassSheet({
    super.key,
    required this.child,
    this.onClose,
    this.minSize = 0.12,
    this.initialSize = 0.22,
    this.maxSize = 0.36,
    this.showCloseButton = true,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barre de dragging
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 6),
            width: 30,
            height: 3,
            decoration: BoxDecoration(
              color: DEMColors.gray400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header avec titre et bouton fermer
          if (title != null || showCloseButton)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DEMSpacing.md,
                vertical: DEMSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: DEMTypography.subtitle1.copyWith(
                          color: DEMColors.gray900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (showCloseButton)
                    IconButton(
                      icon: const Icon(Icons.close, color: DEMColors.gray700),
                      onPressed: onClose ?? () => Navigator.pop(context),
                      tooltip: 'Fermer',
                    ),
                ],
              ),
            ),

          // Contenu
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                DEMSpacing.md,
                DEMSpacing.xs,
                DEMSpacing.md,
                DEMSpacing.lg,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  /// Méthode statique pour afficher facilement le sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool showCloseButton = true,
    double minSize = 0.12,
    double initialSize = 0.22,
    double maxSize = 0.36,
    Color? barrierColor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: barrierColor ?? Colors.black.withOpacity(0.5),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: initialSize,
        minChildSize: minSize,
        maxChildSize: maxSize,
        expand: false,
        builder: (context, scrollController) {
          return TopGlassSheet(
            title: title,
            showCloseButton: showCloseButton,
            child: child,
          );
        },
      ),
    );
  }
}

/// Variante avec animation slide depuis le haut
class TopGlassSheetSlideIn extends StatefulWidget {
  final Widget child;
  final VoidCallback? onClose;
  final String? title;
  final bool showCloseButton;
  final Duration animationDuration;

  const TopGlassSheetSlideIn({
    super.key,
    required this.child,
    this.onClose,
    this.title,
    this.showCloseButton = true,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  /// Méthode statique pour afficher facilement le sheet avec animation
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool showCloseButton = true,
    Duration animationDuration = const Duration(milliseconds: 300),
    Color? barrierColor,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: barrierColor ?? Colors.black.withOpacity(0.5),
      transitionDuration: animationDuration,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: TopGlassSheetSlideIn(
              title: title,
              showCloseButton: showCloseButton,
              animationDuration: animationDuration,
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  State<TopGlassSheetSlideIn> createState() => _TopGlassSheetSlideInState();
}

class _TopGlassSheetSlideInState extends State<TopGlassSheetSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _controller.reverse();
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.36,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header avec titre et bouton fermer
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DEMSpacing.md,
                  vertical: DEMSpacing.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.title != null)
                      Expanded(
                        child: Text(
                          widget.title!,
                          style: DEMTypography.subtitle1.copyWith(
                            color: DEMColors.gray900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (widget.showCloseButton)
                      IconButton(
                        icon: const Icon(Icons.close, color: DEMColors.gray700),
                        onPressed: _close,
                        tooltip: 'Fermer',
                      ),
                  ],
                ),
              ),

              // Contenu
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    DEMSpacing.md,
                    0,
                    DEMSpacing.md,
                    DEMSpacing.lg,
                  ),
                  child: widget.child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
