import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Brand Palette ─────────────────────────────────────────────────────────
  static const Color primaryColor     = Color(0xFF6C63FF); // electric violet
  static const Color primaryDark      = Color(0xFF4A42D6);
  static const Color primaryLight     = Color(0xFF9D97FF);

  static const Color accentColor      = Color(0xFFF5A623); // gold
  static const Color accentDark       = Color(0xFFD4891A);

  static const Color navyDeep         = Color(0xFF0A0E27); // deepest bg
  static const Color navyMid          = Color(0xFF111530); // scaffold bg
  static const Color navySurface      = Color(0xFF1A1F3A); // card surface
  static const Color navyElevated     = Color(0xFF222847); // elevated card

  // ─── Semantic ──────────────────────────────────────────────────────────────
  static const Color secondaryColor   = Color(0xFF10B981); // emerald green
  static const Color successColor     = Color(0xFF10B981);
  static const Color errorColor       = Color(0xFFEF4444);
  static const Color warningColor     = Color(0xFFF59E0B);
  static const Color infoColor        = Color(0xFF6C63FF);

  // ─── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary      = Color(0xFFFFFFFF);
  static const Color textSecondary    = Color(0xFF94A3B8);
  static const Color textHint         = Color(0xFF4A5568);

  // ─── Misc ──────────────────────────────────────────────────────────────────
  static const Color backgroundColor  = navyMid;
  static const Color surfaceColor     = navySurface;
  static const Color dividerColor     = Color(0xFF2A2F52);

  // ─── Gradients (static helpers) ────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF4A42D6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF5A623), Color(0xFFD4891A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A), Color(0xFF222847)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1F3A), Color(0xFF222847)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Shadow helpers ────────────────────────────────────────────────────────
  static List<BoxShadow> glowShadow(Color color, {double blur = 20, double spread = 0}) => [
    BoxShadow(color: color.withAlpha(80), blurRadius: blur, spreadRadius: spread),
  ];

  static List<BoxShadow> get cardShadow => [
    const BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 6)),
  ];

  // ─── Theme ─────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme => _buildTheme();
  static ThemeData get darkTheme  => _buildTheme(); // alias — same dark theme

  static ThemeData _buildTheme() {
    final base = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: navyMid,

      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: navySurface,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),

      // ── Typography ──
      textTheme: base.copyWith(
        displayLarge: base.displayLarge?.copyWith(
            color: textPrimary, fontWeight: FontWeight.w800),
        displayMedium: base.displayMedium?.copyWith(
            color: textPrimary, fontWeight: FontWeight.w700),
        headlineLarge: base.headlineLarge?.copyWith(
            color: textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: base.headlineMedium?.copyWith(
            color: textPrimary, fontWeight: FontWeight.w600),
        titleLarge: base.titleLarge?.copyWith(
            color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: base.titleMedium?.copyWith(
            color: textPrimary, fontWeight: FontWeight.w500),
        bodyLarge: base.bodyLarge?.copyWith(color: textPrimary),
        bodyMedium: base.bodyMedium?.copyWith(color: textSecondary),
        bodySmall: base.bodySmall?.copyWith(color: textSecondary),
        labelLarge: base.labelLarge?.copyWith(
            color: textPrimary, fontWeight: FontWeight.w600),
      ),

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: navyDeep,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        elevation: 0,
        color: navySurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: dividerColor.withAlpha(100), width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),

      // ── Elevated Buttons ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // ── Outlined Buttons ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          side: const BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      // ── Text Buttons ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),

      // ── Inputs ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: navyElevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: dividerColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: dividerColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textHint),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),

      // ── Chips ──
      chipTheme: ChipThemeData(
        backgroundColor: navyElevated,
        selectedColor: primaryColor.withAlpha(60),
        labelStyle: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w500, color: textPrimary),
        side: BorderSide(color: dividerColor, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── Bottom Nav ──
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: navyDeep,
        selectedItemColor: accentColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 11),
      ),

      // ── FAB ──
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
      ),

      // ── Divider ──
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        backgroundColor: navySurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
        contentTextStyle:
            GoogleFonts.inter(fontSize: 14, color: textSecondary),
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: navyElevated,
        contentTextStyle: GoogleFonts.inter(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      // ── ListTile ──
      listTileTheme: const ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        tileColor: Colors.transparent,
      ),

      // ── Switch ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? accentColor : textSecondary),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? accentColor.withAlpha(80)
                : navyElevated),
      ),
    );
  }
}