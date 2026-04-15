import 'package:flutter/material.dart';

class AppPalette {
  const AppPalette({
    required this.primary,
    required this.primarySoft,
    required this.primaryStrong,
    required this.scaffold,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceInset,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.divider,
    required this.success,
    required this.warning,
    required this.danger,
    required this.avatar,
    required this.shadow,
  });

  final Color primary;
  final Color primarySoft;
  final Color primaryStrong;
  final Color scaffold;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceInset;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;
  final Color divider;
  final Color success;
  final Color warning;
  final Color danger;
  final Color avatar;
  final Color shadow;

  Color get brand => primary;
  Color get brandSoft => primarySoft;
  Color get brandAccent => primaryStrong;
  Color get brandHover => primaryStrong;
  Color get canvas => scaffold;
  Color get panel => surface;
  Color get surfaceSecondary => surfaceRaised;
  Color get title => textPrimary;
  Color get text => textSecondary;
  Color get subtitle => textSecondary;
  Color get muted => textTertiary;
  Color get borderSubtle => divider;
  Color get borderStrong => border;
  Color get overlay => shadow;
}

abstract final class AppColors {
  static const light = AppPalette(
    primary: Color(0xFF0C66E4),
    primarySoft: Color(0xFFE9F2FF),
    primaryStrong: Color(0xFF0055CC),
    scaffold: Color(0xFFF4F5F7),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF7F8F9),
    surfaceInset: Color(0xFFF1F2F4),
    textPrimary: Color(0xFF172B4D),
    textSecondary: Color(0xFF626F86),
    textTertiary: Color(0xFF8993A4),
    border: Color(0xFFDDE1E6),
    divider: Color(0xFFEBECF0),
    success: Color(0xFF22A06B),
    warning: Color(0xFFCA3521),
    danger: Color(0xFFAE2E24),
    avatar: Color(0xFF12B5CB),
    shadow: Color(0x12091E42),
  );

  static const dark = AppPalette(
    primary: Color(0xFF579DFF),
    primarySoft: Color(0xFF1C2B41),
    primaryStrong: Color(0xFF85B8FF),
    scaffold: Color(0xFF111214),
    surface: Color(0xFF1D2125),
    surfaceRaised: Color(0xFF22272B),
    surfaceInset: Color(0xFF161A1D),
    textPrimary: Color(0xFFD7DBDF),
    textSecondary: Color(0xFF8C9BAB),
    textTertiary: Color(0xFF738496),
    border: Color(0xFF2C333A),
    divider: Color(0xFF262C33),
    success: Color(0xFF4BCE97),
    warning: Color(0xFFF5CD47),
    danger: Color(0xFFF87168),
    avatar: Color(0xFF12B5CB),
    shadow: Color(0x33000000),
  );
}

abstract final class AppThemePalette {
  static AppPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
  }
}

abstract final class AppSpace {
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(16, 14, 16, 24);
  static const EdgeInsets pagePaddingWithNav = EdgeInsets.fromLTRB(
    16,
    14,
    16,
    112,
  );
  static const double radiusSmall = 6;
  static const double radius = 10;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 24;
  static const double radiusFull = 999;
  static const double cardRadius = radiusLarge;
  static const double dialogRadius = radiusXLarge;
  static const double pillRadius = radiusFull;
}

abstract final class AppShadows {
  static List<BoxShadow> get cardSoft => [
    const BoxShadow(
      color: Color(0x0A091E42), // Very subtle shade
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get cardHover => [
    const BoxShadow(
      color: Color(0x14091E42), // More pronounced
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get dialog => [
    const BoxShadow(
      color: Color(0x1A091E42),
      blurRadius: 32,
      spreadRadius: 2,
      offset: Offset(0, 12),
    ),
  ];
}

abstract final class AppDecorations {
  static BoxDecoration surface(
    BuildContext context, {
    double radius = AppSpace.radiusLarge,
    Color? color,
    Border? border,
    List<BoxShadow>? customShadow,
  }) {
    final palette = AppThemePalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      color: color ?? palette.surface,
      borderRadius: BorderRadius.circular(radius),
      border:
          border ??
          Border.all(color: isDark ? palette.border : Colors.transparent),
      boxShadow: isDark ? null : (customShadow ?? AppShadows.cardSoft),
    );
  }
}
