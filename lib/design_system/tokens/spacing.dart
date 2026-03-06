import 'package:flutter/material.dart';

/// 🏗 DEM Design System - Spacing Tokens
class DEMSpacing {
  // Base unit = 4px
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  // Common combinations
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets paddingHorizontalLg =
      EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingVerticalLg =
      EdgeInsets.symmetric(vertical: lg);
}
