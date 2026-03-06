/// 🎨 Glass Draggable Sheet - Premium Uber/Glovo Style Panel
import 'package:flutter/material.dart';

import '../tokens/animation_constants.dart';

class GlassDraggableSheet extends StatefulWidget {
  final Widget child;
  final double minSize;
  final double initialSize;
  final double maxSize;
  final List<double>? snapSizes;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final ValueChanged<double>? onHeightChanged;
  final EdgeInsets padding;
  final Color tintColor;
  final double opacity;
  final double sigmaX;
  final double sigmaY;
  final bool enableHandleBar;

  const GlassDraggableSheet({
    super.key,
    required this.child,
    this.minSize = 0.25,
    this.initialSize = 0.35,
    this.maxSize = 0.75,
    this.snapSizes,
    this.onDragStart,
    this.onDragEnd,
    this.onHeightChanged,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 16),
    this.tintColor = Colors.white,
    this.opacity = 0.88,
    this.sigmaX = 30,
    this.sigmaY = 30,
    this.enableHandleBar = true,
  });

  @override
  State<GlassDraggableSheet> createState() => _GlassDraggableSheetState();
}

class _GlassDraggableSheetState extends State<GlassDraggableSheet>
    with SingleTickerProviderStateMixin {
  late DraggableScrollableController _scrollController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _scrollController = DraggableScrollableController();
    _animationController = AnimationController(
      duration: DEMAnimationConstants.glassAppearDuration,
      vsync: this,
    );
    // Animate in
    _animationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultSnapSizes = [
      widget.minSize,
      widget.initialSize,
      widget.maxSize
    ];
    final effectiveSnapSizes = widget.snapSizes ?? defaultSnapSizes;

    return DraggableScrollableSheet(
      controller: _scrollController,
      initialChildSize: widget.initialSize,
      minChildSize: widget.minSize,
      maxChildSize: widget.maxSize,
      snap: true,
      snapSizes: effectiveSnapSizes,
      builder: (context, scrollController) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: DEMAnimationConstants.glassEntryCurve,
            ),
          ),
          child: SlideTransition(
            position:
                Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
                    .animate(
              CurvedAnimation(
                parent: _animationController,
                curve: DEMAnimationConstants.glassEntryCurve,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: widget.tintColor.withValues(alpha: widget.opacity),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 32,
                    spreadRadius: -8,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle Bar - Top aligned
                  if (widget.enableHandleBar)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                  // Content with inner margin
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: widget.padding,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            widget.child,
                            // Bottom margin to prevent navbar overlap
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
