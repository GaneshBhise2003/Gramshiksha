import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

class ResponsiveTheme {
  static ThemeData getLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      fontFamily: 'Roboto',

      // Enhanced scaffold background for better readability
      scaffoldBackgroundColor: const Color(0xFFFAFBFC),

      // Responsive app bar theme
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF1F2937),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
        toolbarHeight: 64, // Slightly taller for better touch targets
      ),

      // Enhanced card theme for responsive layouts
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        color: Colors.white,
      ),

      // Enhanced input decoration for better responsive forms
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        isDense: false,
      ),

      // Enhanced button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          minimumSize: const Size(120, 48), // Better touch targets
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          minimumSize: const Size(120, 48),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // Enhanced FAB theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        sizeConstraints: const BoxConstraints.tightFor(width: 56, height: 56),
      ),

      // Enhanced list tile theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minVerticalPadding: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),

      // Enhanced divider theme
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 1,
      ),

      // Enhanced chip theme
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: const Color(0xFF6366F1).withOpacity(0.1),
        disabledColor: Colors.grey.shade50,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Enhanced navigation themes
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedItemColor: Color(0xFF6366F1),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        selectedIconTheme: const IconThemeData(
          color: Color(0xFF6366F1),
          size: 28,
        ),
        unselectedIconTheme: IconThemeData(
          color: Colors.grey.shade600,
          size: 24,
        ),
        selectedLabelTextStyle: const TextStyle(
          color: Color(0xFF6366F1),
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.normal,
        ),
      ),

      // Enhanced drawer theme
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        elevation: 16,
        width: 280,
      ),

      // Enhanced dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(color: Colors.grey.shade700, fontSize: 16),
      ),

      // Enhanced snack bar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1F2937),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      // Enhanced progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF6366F1),
        linearTrackColor: Color(0xFFE5E7EB),
        circularTrackColor: Color(0xFFE5E7EB),
      ),
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      fontFamily: 'Roboto',

      scaffoldBackgroundColor: const Color(0xFF111827),

      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Color(0xFFF9FAFB),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF9FAFB),
        ),
        toolbarHeight: 64,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade800, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        color: const Color(0xFF1F2937),
      ),

      // Add other dark theme properties similar to light theme
      // ... (abbreviated for brevity, but would include all the same enhancements)
    );
  }

  // Responsive text styles
  static TextTheme getResponsiveTextTheme(BuildContext context) {
    final scale = ResponsiveHelper.responsiveValue<double>(
      context: context,
      mobile: 0.9,
      tablet: 1.0,
      desktop: 1.1,
      largeDesktop: 1.2,
    );

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57 * scale,
        fontWeight: FontWeight.w400,
      ),
      displayMedium: TextStyle(
        fontSize: 45 * scale,
        fontWeight: FontWeight.w400,
      ),
      displaySmall: TextStyle(
        fontSize: 36 * scale,
        fontWeight: FontWeight.w400,
      ),
      headlineLarge: TextStyle(
        fontSize: 32 * scale,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        fontSize: 28 * scale,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        fontSize: 24 * scale,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(fontSize: 22 * scale, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(fontSize: 12 * scale, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(fontSize: 12 * scale, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(fontSize: 11 * scale, fontWeight: FontWeight.w600),
    );
  }

  // Responsive spacing helper
  static EdgeInsets getResponsivePadding(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    final padding = ResponsiveHelper.responsiveValue<double>(
      context: context,
      mobile: mobile ?? 16,
      tablet: tablet ?? 20,
      desktop: desktop ?? 24,
      largeDesktop: largeDesktop ?? 32,
    );
    return EdgeInsets.all(padding);
  }

  static EdgeInsets getResponsiveHorizontalPadding(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    final padding = ResponsiveHelper.responsiveValue<double>(
      context: context,
      mobile: mobile ?? 16,
      tablet: tablet ?? 24,
      desktop: desktop ?? 32,
      largeDesktop: largeDesktop ?? 48,
    );
    return EdgeInsets.symmetric(horizontal: padding);
  }

  static EdgeInsets getResponsiveVerticalPadding(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    final padding = ResponsiveHelper.responsiveValue<double>(
      context: context,
      mobile: mobile ?? 12,
      tablet: tablet ?? 16,
      desktop: desktop ?? 20,
      largeDesktop: largeDesktop ?? 24,
    );
    return EdgeInsets.symmetric(vertical: padding);
  }
}
