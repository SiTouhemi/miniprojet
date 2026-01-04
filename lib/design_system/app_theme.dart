import 'package:flutter/material.dart';

/// Application design system
/// Provides centralized styling, spacing, and theming
class AppTheme {
  static const AppSpacing spacing = AppSpacing();
  static const AppTypography typography = AppTypography();
  static const AppColors colors = AppColors();
  static const AppShadows shadows = AppShadows();
  static const AppBorders borders = AppBorders();
}

/// Consistent spacing values throughout the app
class AppSpacing {
  const AppSpacing();
  
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  // Padding shortcuts
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);
  
  // Margin shortcuts
  static const EdgeInsets marginXS = EdgeInsets.all(xs);
  static const EdgeInsets marginSM = EdgeInsets.all(sm);
  static const EdgeInsets marginMD = EdgeInsets.all(md);
  static const EdgeInsets marginLG = EdgeInsets.all(lg);
  static const EdgeInsets marginXL = EdgeInsets.all(xl);
  
  // Vertical spacing
  static const SizedBox verticalXS = SizedBox(height: xs);
  static const SizedBox verticalSM = SizedBox(height: sm);
  static const SizedBox verticalMD = SizedBox(height: md);
  static const SizedBox verticalLG = SizedBox(height: lg);
  static const SizedBox verticalXL = SizedBox(height: xl);
  
  // Horizontal spacing
  static const SizedBox horizontalXS = SizedBox(width: xs);
  static const SizedBox horizontalSM = SizedBox(width: sm);
  static const SizedBox horizontalMD = SizedBox(width: md);
  static const SizedBox horizontalLG = SizedBox(width: lg);
  static const SizedBox horizontalXL = SizedBox(width: xl);
}

/// Typography system with consistent font styles
class AppTypography {
  const AppTypography();
  
  static const String primaryFontFamily = 'Inter';
  static const String headingFontFamily = 'Inter Tight';
  static const String bodyFontFamily = 'Inter';
  
  // Font weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  
  // Text styles
  static const TextStyle h1 = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 32.0,
    fontWeight: bold,
    height: 1.2,
  );
  
  static const TextStyle h2 = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 28.0,
    fontWeight: semiBold,
    height: 1.3,
  );
  
  static const TextStyle h3 = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 24.0,
    fontWeight: semiBold,
    height: 1.3,
  );
  
  static const TextStyle h4 = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 20.0,
    fontWeight: semiBold,
    height: 1.4,
  );
  
  static const TextStyle h5 = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 18.0,
    fontWeight: semiBold,
    height: 1.4,
  );
  
  static const TextStyle h6 = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 16.0,
    fontWeight: semiBold,
    height: 1.4,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 16.0,
    fontWeight: regular,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 14.0,
    fontWeight: regular,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 12.0,
    fontWeight: regular,
    height: 1.5,
  );
  
  static const TextStyle caption = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 10.0,
    fontWeight: regular,
    height: 1.4,
  );
  
  static const TextStyle button = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 16.0,
    fontWeight: semiBold,
    height: 1.2,
  );
  
  static const TextStyle buttonSmall = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 14.0,
    fontWeight: semiBold,
    height: 1.2,
  );
  
  static const TextStyle buttonMedium = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 16.0,
    fontWeight: semiBold,
    height: 1.2,
  );
  
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 18.0,
    fontWeight: semiBold,
    height: 1.2,
  );
}

/// Color system with semantic naming
class AppColors {
  const AppColors();
  
  // Primary colors
  static const Color primary = Color(0xFF005BAA);
  static const Color primaryLight = Color(0xFF3D7BC6);
  static const Color primaryDark = Color(0xFF003D73);
  
  // Secondary colors
  static const Color secondary = Color(0xFF00A4E4);
  static const Color secondaryLight = Color(0xFF4DB8E8);
  static const Color secondaryDark = Color(0xFF0073A3);
  
  // Semantic colors
  static const Color success = Color(0xFF00A855);
  static const Color successLight = Color(0xFF4CBB7A);
  static const Color successDark = Color(0xFF00753D);
  
  static const Color warning = Color(0xFFFF6B35);
  static const Color warningLight = Color(0xFFFF8A5C);
  static const Color warningDark = Color(0xFFCC4A1F);
  
  static const Color error = Color(0xFFE74C3C);
  static const Color errorLight = Color(0xFFED6B5E);
  static const Color errorDark = Color(0xFFB73E32);
  
  static const Color info = Color(0xFF3498DB);
  static const Color infoLight = Color(0xFF5DADE2);
  static const Color infoDark = Color(0xFF2874A6);
  
  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFE0E0E0);
  static const Color gray300 = Color(0xFFBDBDBD);
  static const Color gray400 = Color(0xFF9E9E9E);
  static const Color gray500 = Color(0xFF757575);
  static const Color gray600 = Color(0xFF616161);
  static const Color gray700 = Color(0xFF424242);
  static const Color gray800 = Color(0xFF212121);
  static const Color gray900 = Color(0xFF0D0D0D);
  
  // Background colors
  static const Color background = white;
  static const Color surface = white;
  static const Color surfaceVariant = gray50;
  
  // Text colors
  static const Color textPrimary = gray900;
  static const Color textSecondary = gray600;
  static const Color textTertiary = gray500;
  static const Color textOnPrimary = white;
  static const Color textOnSecondary = white;
  
  // Border colors
  static const Color border = gray200;
  static const Color borderLight = gray100;
  static const Color borderDark = gray300;
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient balanceGradient = LinearGradient(
    colors: [Color(0xFF052753), Color(0xFF001E46)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Shadow system for consistent elevation
class AppShadows {
  const AppShadows();
  
  static const List<BoxShadow> small = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> large = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> extraLarge = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 8),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];
}

/// Border radius system
class AppBorders {
  const AppBorders();
  
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusRound = 999.0;
  
  // Border radius shortcuts
  static const BorderRadius borderXS = BorderRadius.all(Radius.circular(radiusXS));
  static const BorderRadius borderSM = BorderRadius.all(Radius.circular(radiusSM));
  static const BorderRadius borderMD = BorderRadius.all(Radius.circular(radiusMD));
  static const BorderRadius borderLG = BorderRadius.all(Radius.circular(radiusLG));
  static const BorderRadius borderXL = BorderRadius.all(Radius.circular(radiusXL));
  static const BorderRadius borderRound = BorderRadius.all(Radius.circular(radiusRound));
  
  // Border styles
  static const BorderSide borderThin = BorderSide(
    color: AppColors.border,
    width: 1.0,
  );
  
  static const BorderSide borderMedium = BorderSide(
    color: AppColors.border,
    width: 2.0,
  );
  
  static const BorderSide borderThick = BorderSide(
    color: AppColors.border,
    width: 3.0,
  );
}

/// Icon sizes
class AppIconSizes {
  static const double xs = 12.0;
  static const double sm = 16.0;
  static const double md = 20.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

/// Button sizes
class AppButtonSizes {
  static const double heightSmall = 32.0;
  static const double heightMedium = 40.0;
  static const double heightLarge = 48.0;
  static const double heightExtraLarge = 56.0;
  
  static const EdgeInsets paddingSmall = EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0);
  static const EdgeInsets paddingMedium = EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
  static const EdgeInsets paddingLarge = EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0);
  static const EdgeInsets paddingExtraLarge = EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0);
}

/// Input field sizes
class AppInputSizes {
  static const double height = 48.0;
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
  static const BorderRadius borderRadius = AppBorders.borderMD;
}