import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ============ PRIMARY PALETTE ============
  // Azul confianza - Color principal de la marca
  static const Color bluePrimary = Color(0xFF1976D2);
  static const Color bluePrimaryLight = Color(0xFF42A5F5);
  static const Color bluePrimaryDark = Color(0xFF0D47A1);
  static const Color blueSecondary = Color(0xFF2E86AB);
  static const Color blueSecondaryLight = Color(0xFF64B5F6);

  // Verde esperanza - Éxito y progreso
  static const Color greenHope = Color(0xFF4CAF50);
  static const Color greenHopeLight = Color(0xFF81C784);
  static const Color greenHopeDark = Color(0xFF2E7D32);
  static const Color greenSoft = Color(0xFFA8DADC);
  static const Color greenSuccess = Color(0xFF28A745);

  // Naranja acción - Llamados a la acción
  static const Color orangeAction = Color(0xFFF28E2C);
  static const Color orangeActionLight = Color(0xFFFFB74D);
  static const Color orangeActionDark = Color(0xFFE65100);

  // ============ NEUTRAL COLORS ============
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF2C3E50);
  static const Color mediumText = Color(0xFF5A6C7D);
  static const Color lightText = Color(0xFF8F9BB3);
  static const Color grayNeutral = Color(0xFFBFC3C7);
  static const Color grayLight = Color(0xFFE8EAED);
  static const Color grayDark = Color(0xFF6C757D);
  static const Color dividerColor = Color(0xFFE0E0E0);

  // ============ SEMANTIC COLORS ============
  static const Color error = Color(0xFFDC3545);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFD54F);
  static const Color info = Color(0xFF17A2B8);
  static const Color infoLight = Color(0xFF29B6F6);

  // ============ GRADIENTS ============
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bluePrimary, blueSecondary],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [greenHope, greenHopeLight],
  );

  static const LinearGradient actionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [orangeAction, orangeActionLight],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
  );

  // ============ SHADOWS ============
  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // ============ SPACING SYSTEM (4pt grid) ============
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // ============ BORDER RADIUS ============
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusRound = 999.0;

  // ============ SIZES ============
  static const double iconSizeSm = 16.0;
  static const double iconSizeMd = 24.0;
  static const double iconSizeLg = 32.0;
  static const double iconSizeXl = 48.0;

  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 48.0;
  static const double buttonHeightLg = 56.0;

  static const double avatarSizeSm = 32.0;
  static const double avatarSizeMd = 48.0;
  static const double avatarSizeLg = 64.0;
  static const double avatarSizeXl = 96.0;

  // ============ OPACITY LEVELS ============
  /// Opacidad para elementos deshabilitados
  static const double opacityDisabled = 0.38;
  /// Opacidad para textos secundarios
  static const double opacitySecondary = 0.60;
  /// Opacidad para textos medios
  static const double opacityMedium = 0.75;
  /// Opacidad para overlays sutiles
  static const double opacityOverlay = 0.08;
  /// Opacidad para hover states
  static const double opacityHover = 0.12;

  // ============ FONT SIZES (Escala tipográfica) ============
  static const double fontSizeXs = 11.0;
  static const double fontSizeSm = 12.0;
  static const double fontSizeBase = 14.0;
  static const double fontSizeMd = 16.0;
  static const double fontSizeLg = 18.0;
  static const double fontSizeXl = 20.0;
  static const double fontSize2xl = 24.0;
  static const double fontSize3xl = 28.0;
  static const double fontSize4xl = 32.0;

  // ============ FONT WEIGHTS ============
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtraBold = FontWeight.w800;

  // ============ LINE HEIGHTS ============
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.75;

  // ============ LETTER SPACING ============
  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.3;
}
