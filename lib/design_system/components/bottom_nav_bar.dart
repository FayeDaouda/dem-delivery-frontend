/// 🎨 Bottom Navigation Bar - Glass Morphism Style (Uber/Maps)
/// Responsive: Mobile, Tablet, iOS, Android
import 'package:flutter/material.dart';

import 'glass_panel.dart';

class BottomNavBarItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const BottomNavBarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });
}

class BottomNavBar extends StatelessWidget {
  final List<BottomNavBarItem> items;
  final int activeIndex;
  final ValueChanged<int> onTap;
  final EdgeInsets? padding;
  final double? height;

  const BottomNavBar({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.onTap,
    this.padding,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    // Responsive padding
    final responsivePadding = padding ??
        EdgeInsets.fromLTRB(
          isTablet ? 32 : 16,
          isTablet ? 16 : 12,
          isTablet ? 32 : 16,
          isTablet ? 20 : 16,
        );

    // Responsive height
    final responsiveHeight = height ?? (isTablet ? 100 : 80);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: responsivePadding,
          child: GlassPanel.small(
            child: SizedBox(
              height: responsiveHeight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    items.length,
                    (index) => SizedBox(
                      width: (screenSize.width -
                              (responsivePadding.left +
                                  responsivePadding.right) -
                              32) /
                          items.length,
                      child: _NavBarItemWidget(
                        item: items[index],
                        isActive: index == activeIndex,
                        onTap: () => onTap(index),
                        isTablet: isTablet,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItemWidget extends StatelessWidget {
  final BottomNavBarItem item;
  final bool isActive;
  final VoidCallback onTap;
  final bool isTablet;

  const _NavBarItemWidget({
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconSize = isTablet ? 28.0 : 24.0;
    final fontSize = isTablet ? 13.0 : 11.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.08))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 300),
              scale: isActive ? 1.15 : 1.0,
              child: Icon(
                item.icon,
                color: isActive
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.6)),
                size: iconSize,
              ),
            ),
            SizedBox(height: isTablet ? 8 : 4),
            AnimatedOpacity(
              opacity: isActive ? 1.0 : 0.6,
              duration: const Duration(milliseconds: 300),
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: fontSize,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.black.withValues(alpha: 0.6)),
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
