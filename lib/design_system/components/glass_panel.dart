/// 🎨 Glass Morphism Component - Senior Grade (Uber/Apple Maps level)
import 'dart:ui';

import 'package:flutter/material.dart';

import '../tokens/animation_constants.dart';
import '../tokens/radii.dart';

enum GlassPanelSize {
  small,
  medium,
  large,
}

class GlassPanel extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final double sigmaX;
  final double sigmaY;
  final Color? tintColor;
  final double opacity;
  final BoxBorder? border;
  final GlassPanelSize size;
  final bool enableGradient;
  final bool enableShadow;
  final bool enableAnimation;
  final Duration animationDuration;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = DEMRadii.borderRadiusXxl,
    this.sigmaX = 30,
    this.sigmaY = 30,
    this.tintColor,
    this.opacity = 0.88,
    this.border,
    this.size = GlassPanelSize.medium,
    this.enableGradient = false,
    this.enableShadow = true,
    this.enableAnimation = true,
    this.animationDuration = DEMAnimationConstants.glassAppearDuration,
  });

  // Factory Constructors - Variantes
  factory GlassPanel.small({
    required Widget child,
    Color? tintColor,
  }) =>
      GlassPanel(
        child: child,
        padding: const EdgeInsets.all(12),
        size: GlassPanelSize.small,
        tintColor: tintColor,
      );

  factory GlassPanel.large({
    required Widget child,
    Color? tintColor,
  }) =>
      GlassPanel(
        child: child,
        padding: const EdgeInsets.all(24),
        size: GlassPanelSize.large,
        tintColor: tintColor,
      );

  @override
  State<GlassPanel> createState() => _GlassPanelState();
}

class _GlassPanelState extends State<GlassPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: DEMAnimationConstants.glassEntryCurve,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: DEMAnimationConstants.glassEntryCurve,
      ),
    );

    if (widget.enableAnimation) {
      _animationController.forward();
    } else {
      _animationController.forward(from: 1);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getAdaptiveTintColor(BuildContext context) {
    if (widget.tintColor != null) return widget.tintColor!;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey.shade900.withValues(alpha: 0.4) : Colors.white;
  }

  List<BoxShadow> _getPremiumShadow(BuildContext context) {
    if (!widget.enableShadow) return [];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.12);

    return [
      BoxShadow(
        color: shadowColor,
        blurRadius: DEMAnimationConstants.shadowBlurRadius,
        spreadRadius: DEMAnimationConstants.shadowSpreadRadius,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: shadowColor.withValues(alpha: shadowColor.alpha * 0.5),
        blurRadius: 12,
        spreadRadius: -4,
        offset: const Offset(0, 4),
      ),
    ];
  }

  Gradient? _getGradientGlass(BuildContext context) {
    if (!widget.enableGradient) return null;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.2);

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor,
        baseColor.withValues(
          alpha: baseColor.alpha * DEMAnimationConstants.gradientOpacityEnd,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: BackdropFilter(
            filter:
                ImageFilter.blur(sigmaX: widget.sigmaX, sigmaY: widget.sigmaY),
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                color: _getAdaptiveTintColor(context).withValues(
                  alpha: widget.opacity,
                ),
                borderRadius: widget.borderRadius,
                border: widget.border,
                gradient: _getGradientGlass(context),
                boxShadow: _getPremiumShadow(context),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
