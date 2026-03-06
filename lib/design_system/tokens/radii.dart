/// 🔵 DEM Design System - Border Radius Tokens
import 'package:flutter/material.dart';

class DEMRadii {
  // Small - 8px
  static const sm = 8.0;

  // Medium - 12px
  static const md = 12.0;

  // Large - 16px
  static const lg = 16.0;

  // Extra Large - 20px
  static const xl = 20.0;

  // 2X Large - 24px
  static const xxl = 24.0;

  // Full circle
  static const full = 999.0;

  // Common BorderRadius
  static const borderRadiusSm = BorderRadius.all(Radius.circular(sm));
  static const borderRadiusMd = BorderRadius.all(Radius.circular(md));
  static const borderRadiusLg = BorderRadius.all(Radius.circular(lg));
  static const borderRadiusXl = BorderRadius.all(Radius.circular(xl));
  static const borderRadiusXxl = BorderRadius.all(Radius.circular(xxl));
  static const borderRadiusFull = BorderRadius.all(Radius.circular(full));

  // Top rounded
  static const borderRadiusTopXxl = BorderRadius.only(
    topLeft: Radius.circular(xxl),
    topRight: Radius.circular(xxl),
  );
}
