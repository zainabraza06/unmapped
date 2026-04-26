import 'package:flutter/material.dart';

/// Central design tokens for UNMAPPED.
/// All color, typography, and spacing values live here — never hardcoded elsewhere.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFF8F7F4); // warm off-white
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color border     = Color(0xFFE7E5E4); // stone-200
  static const Color divider    = Color(0xFFF5F5F4); // stone-100

  static const Color textPrimary   = Color(0xFF1C1917); // stone-950
  static const Color textSecondary = Color(0xFF78716C); // stone-500
  static const Color textMuted     = Color(0xFFA8A29E); // stone-400

  // Semantic colours
  static const Color risk       = Color(0xFFDC2626); // red-600
  static const Color riskLight  = Color(0xFFFEE2E2); // red-100
  static const Color stable     = Color(0xFF16A34A); // green-600
  static const Color stableLight= Color(0xFFDCFCE7); // green-100
  static const Color opportunity = Color(0xFF2563EB); // blue-600
  static const Color opportunityLight = Color(0xFFDBEAFE); // blue-100
  static const Color warning    = Color(0xFFD97706); // amber-600
  static const Color warningLight = Color(0xFFFEF3C7); // amber-100
  static const Color neutral    = Color(0xFF57534E); // stone-600
  static const Color neutralLight = Color(0xFFF5F5F4); // stone-100

  static const Color primary    = Color(0xFF0F172A); // dark slate-900
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle displaySmall = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
    height: 1.2,
  );
  static const TextStyle headline = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
    height: 1.3,
  );
  static const TextStyle title = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
    height: 1.5,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
    height: 1.4,
  );
  static const TextStyle label = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary,
    letterSpacing: 0.6,
  );
  static const TextStyle mono = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted,
    fontFamily: 'monospace',
  );
}

class AppSpacing {
  AppSpacing._();
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: AppColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.border,
      titleTextStyle: AppTextStyles.headline,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      labelStyle: AppTextStyles.caption,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: AppTextStyles.title,
        elevation: 0,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.1),
      labelTextStyle: WidgetStateProperty.all(AppTextStyles.caption),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary, size: 22);
        }
        return const IconThemeData(color: AppColors.textMuted, size: 22);
      }),
    ),
    chipTheme: ChipThemeData(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: AppTextStyles.caption,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
