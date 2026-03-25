import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Brand Palette (Variables kept same name for compatibility, but changed to LIGHT) ───
  static const Color primaryColor = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);

  static const Color accentColor = Color(0xFF10B981); // Emerald
  static const Color accentDark = Color(0xFF059669);

  static const Color navyDeep = Color(0xFFF8FAFC); // background (Slate 50)
  static const Color navyMid = Color(0xFFF1F5F9); // scaffold bg (Slate 100)
  static const Color navySurface = Color(0xFFFFFFFF); // card surface (White)
  static const Color navyElevated = Color(0xFFFFFFFF); // elevated card (White)

  // ─── Semantic ──────────────────────────────────────────────────────────────
  static const Color secondaryColor = Color(0xFF10B981);
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color infoColor = Color(0xFF6366F1);

  // ─── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textHint = Color(0xFF94A3B8); // Slate 400

  // ─── Misc ──────────────────────────────────────────────────────────────────
  static const Color backgroundColor = navyMid;
  static const Color surfaceColor = navySurface;
  static const Color dividerColor = Color(0xFFE2E8F0); // Slate 200

  // ─── Gradients (static helpers) ────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF818CF8), Color(0xFF6366F1)], // Light Indigo to Indigo
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF10B981)], // Emerald gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF), Color(0xFFF8FAFC)], // Indigo 50-100 down to Slate 50
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)], // Pure white dropping down
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Shadow helpers ────────────────────────────────────────────────────────
  static List<BoxShadow> glowShadow(Color color,
          {double blur = 20, double spread = 0}) =>
      [
        BoxShadow(
            color: color.withAlpha(40), blurRadius: blur, spreadRadius: spread),
      ];

  static List<BoxShadow> get cardShadow => [
        const BoxShadow(
            color: Color(0x0C000000), blurRadius: 12, offset: Offset(0, 4)),
      ];

  // ─── Theme ─────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme => _buildTheme();
  static ThemeData get darkTheme => _buildTheme(); // alias — same dark theme

  static ThemeData _buildTheme() {
    final base = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: navyMid,

      colorScheme: const ColorScheme.light(
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
        displayLarge: base.displayLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.w800),
        displayMedium: base.displayMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.w700),
        headlineLarge: base.headlineLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: base.headlineMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
        titleLarge: base.titleLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: base.titleMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.w500),
        bodyLarge: base.bodyLarge?.copyWith(color: textPrimary),
        bodyMedium: base.bodyMedium?.copyWith(color: textSecondary),
        bodySmall: base.bodySmall?.copyWith(color: textSecondary),
        labelLarge: base.labelLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
      ),

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: navyDeep,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        elevation: 0,
        color: navySurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: dividerColor, width: 1),
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
          borderSide: const BorderSide(color: dividerColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: dividerColor, width: 1),
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
        side: const BorderSide(color: dividerColor, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── Bottom Nav ──
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: navySurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle:
            TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle:
            TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
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
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: textSecondary),
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
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
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.white : textSecondary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? primaryColor
                : dividerColor),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}
