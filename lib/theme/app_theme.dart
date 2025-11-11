import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGreen = Color.fromRGBO(76, 175, 80, 1);
  static const Color secondaryGreen = Color.fromRGBO(129, 199, 132, 1);
  static const Color darkGreen = Color.fromRGBO(56, 142, 60, 1);

  static const Color backgroundBlack = Colors.black;
  static const Color cardDark = Color.fromRGBO(18, 18, 18, 1);
  static const Color cardMedium = Color.fromRGBO(30, 30, 30, 1);
  static const Color cardLight = Color.fromRGBO(40, 40, 40, 1);

  static const Color borderDark = Color.fromRGBO(50, 50, 50, 1);
  static const Color borderMedium = Color.fromRGBO(80, 80, 80, 1);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color.fromRGBO(158, 158, 158, 1);
  static const Color textTertiary = Color.fromRGBO(117, 117, 117, 1);
  static const Color textDisabled = Color.fromRGBO(80, 80, 80, 1);

  static const Color errorRed = Color.fromRGBO(244, 67, 54, 1);
  static const Color warningOrange = Color.fromRGBO(255, 152, 0, 1);
  static const Color infoBlue = Color.fromRGBO(33, 150, 243, 1);

  static const Color greenTransparent20 = Color.fromRGBO(76, 175, 80, 0.2);
  static const Color redTransparent20 = Color.fromRGBO(244, 67, 54, 0.2);
  static const Color greenTransparent10 = Color.fromRGBO(76, 175, 80, 0.1);
  static const Color redTransparent10 = Color.fromRGBO(244, 67, 54, 0.1);

  static const Color appBarColor = Color(0xFF0f0f0f);
  static const Color accentGreen = Color(0xFF16a34a);
  static const Color backgroundColor = Color(0xFF111418);
  static const Color inputBackground = Color(0xFF22282F);
  static const Color warningYellow = Color(0xFFF59E0B);
  static const Color successGreen = Color(0xFF10B981);

  static BoxShadow cardShadow = const BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.3),
    blurRadius: 10,
    offset: Offset(0, 4),
  );

  static BoxShadow cardShadowStrong = const BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.5),
    blurRadius: 20,
    offset: Offset(0, 10),
  );

  static BorderRadius defaultRadius = BorderRadius.circular(12);
  static BorderRadius largeRadius = BorderRadius.circular(16);
  static BorderRadius smallRadius = BorderRadius.circular(8);
  static BorderRadius tinyRadius = BorderRadius.circular(4);
  static BorderRadius extraLargeRadius = BorderRadius.circular(20);

  static const double paddingSmall = 8;
  static const double paddingMedium = 16;
  static const double paddingLarge = 24;
  static const double paddingXLarge = 32;

  static const double gapSmall = 8;
  static const double gapMedium = 12;
  static const double gapLarge = 16;
  static const double gapXLarge = 24;

  static TextStyle get heading1 => const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      );

  static TextStyle get heading2 => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      );

  static TextStyle get heading3 => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontSize: 16,
        color: textPrimary,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontSize: 14,
        color: textPrimary,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontSize: 12,
        color: textSecondary,
      );

  static TextStyle get caption => const TextStyle(
        fontSize: 12,
        color: textSecondary,
      );

  static TextStyle get buttonText => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: textPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: defaultRadius),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      );

  static ButtonStyle get secondaryButton => OutlinedButton.styleFrom(
        foregroundColor: primaryGreen,
        side: const BorderSide(color: primaryGreen, width: 2),
        shape: RoundedRectangleBorder(borderRadius: defaultRadius),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      );

  static InputDecoration inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        filled: true,
        fillColor: cardMedium,
        border: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: const BorderSide(color: borderDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        errorStyle: const TextStyle(
          color: errorRed,
          fontSize: 12,
        ),
      );

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Cores primárias
      primaryColor: accentGreen,
      scaffoldBackgroundColor: backgroundColor,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: appBarColor,
        surfaceTintColor:
            Colors.transparent, // Remove efeito de tint do Material 3
        scrolledUnderElevation: 0, // Remove mudança de cor ao scrollar
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: inputBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorRed, width: 2),
        ),
        hintStyle: TextStyle(
          color: Color(0xFFAAAAAA), // Mais claro que textSecondary
          fontSize: 16, // Maior
        ),
        labelStyle: TextStyle(
          color: Colors.white, // Branco em vez de cinza
          fontSize: 16,
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGreen,
          foregroundColor: textPrimary,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentGreen,
          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: appBarColor,
        selectedItemColor: accentGreen,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Drawer
      drawerTheme: DrawerThemeData(backgroundColor: backgroundColor),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: inputBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Icon
      iconTheme: IconThemeData(color: textPrimary),

      // Text
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
        labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: textSecondary),
        labelSmall: TextStyle(color: textSecondary),
      ),

      // Divider
      dividerTheme: DividerThemeData(color: inputBackground, thickness: 1),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: inputBackground,
        selectedColor: accentGreen,
        labelStyle: TextStyle(color: textPrimary),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: inputBackground,
        contentTextStyle: TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      colorScheme: ColorScheme.dark(
        primary: accentGreen,
        secondary: accentGreen,
        surface: inputBackground,
        background: backgroundColor,
        error: errorRed,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: textPrimary,
      ),
    );
  }
}
