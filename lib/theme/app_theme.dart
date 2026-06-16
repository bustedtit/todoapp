// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// 🌿 Bingo Colors – Premium Palette (Low‑end friendly)
// ============================================================
class BingoColors {
  // Gradients – kept for compatibility (lightweight, no performance hit)
static const LinearGradient forestMist = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF1A4731), Color(0xFF2D6A4F)],
);

static const LinearGradient darkGarden = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0A1F14), Color(0xFF0D2B1A)],
);
  // Primary Forest Greens (rich but calm)
  static const Color forestGreen = Color(0xFF1A4731);   // darkest
  static const Color emeraldGreen = Color(0xFF2D6A4F);
  static const Color leafGreen = Color(0xFF40916C);
  static const Color midGreen = Color(0xFF52B788);
  static const Color mintGreen = Color(0xFF74C69D);
  static const Color softMint = Color(0xFF95D5B2);
  static const Color paleGreen = Color(0xFFB7E4C7);
  static const Color mistGreen = Color(0xFFD8F3DC);

  // Warm accents (used sparingly)
  static const Color goldenHour = Color(0xFFF4A261);
  static const Color softAmber = Color(0xFFFDCB6E);
  static const Color roseBlush = Color(0xFFE8A4A0);

  // Dark mode (true dark, low contrast)
  static const Color darkForest = Color(0xFF0A1F14);
  static const Color darkCanopy = Color(0xFF0D2B1A);
  static const Color darkMoss = Color(0xFF122B1E);
  static const Color darkFern = Color(0xFF1A3C28);
  static const Color glowGreen = Color(0xFF52B788);

  // Neutrals (soft, elegant)
  static const Color cream = Color(0xFFF8F5EE);
  static const Color fog = Color(0xFFF0EDE6);
  static const Color bark = Color(0xFF6B5B45);
  static const Color stone = Color(0xFF9E9485);
  static const Color pebble = Color(0xFFD4CFC5);

  // Semantic (strong but not neon)
  static const Color priorityHigh = Color(0xFFE55A4E);
  static const Color priorityMed = Color(0xFFF4A261);
  static const Color priorityLow = Color(0xFF74C69D);
  static const Color success = Color(0xFF52B788);
  static const Color warning = Color(0xFFFDCB6E);

  // Gradients – only one kept for hero elements (lightweight)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D6A4F), Color(0xFF40916C)],
  );
}

// ============================================================
// ✍️ Typography – Premium, readable, system‑font fallback
// ============================================================
class BingoTextStyles {
  // Display (serif) – Cormorant or fallback to serif
  static TextStyle get displayLarge => GoogleFonts.cormorantGaramond(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        height: 1.1,
      );

  static TextStyle get displayMedium => GoogleFonts.cormorantGaramond(
        fontSize: 40,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.8,
        height: 1.15,
      );

  static TextStyle get displaySmall => GoogleFonts.cormorantGaramond(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.2,
      );

  // Body (sans) – DM Sans or fallback to sans
  static TextStyle get headlineLarge => GoogleFonts.dmSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.3,
      );

  static TextStyle get headlineMedium => GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.35,
      );

  static TextStyle get headlineSmall => GoogleFonts.dmSans(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.4,
      );

  static TextStyle get bodyLarge => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.55,
      );

  static TextStyle get bodyMedium => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.45,
      );

  static TextStyle get labelLarge => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle get labelSmall => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      );

  static TextStyle get tagline => GoogleFonts.cormorantGaramond(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.2,
        fontStyle: FontStyle.italic,
      );
}

// ============================================================
// 🎨 Light & Dark Themes – High contrast, minimal overhead
// ============================================================
class BingoTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: BingoColors.cream,
      colorScheme: const ColorScheme.light(
        primary: BingoColors.emeraldGreen,
        secondary: BingoColors.mintGreen,
        surface: BingoColors.cream,
        background: BingoColors.fog,
        error: BingoColors.priorityHigh,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: BingoColors.forestGreen,
      ),
      textTheme: TextTheme(
        displayLarge: BingoTextStyles.displayLarge.copyWith(color: BingoColors.forestGreen),
        displayMedium: BingoTextStyles.displayMedium.copyWith(color: BingoColors.forestGreen),
        displaySmall: BingoTextStyles.displaySmall.copyWith(color: BingoColors.forestGreen),
        headlineLarge: BingoTextStyles.headlineLarge.copyWith(color: BingoColors.forestGreen),
        headlineMedium: BingoTextStyles.headlineMedium.copyWith(color: BingoColors.forestGreen),
        headlineSmall: BingoTextStyles.headlineSmall.copyWith(color: BingoColors.emeraldGreen),
        bodyLarge: BingoTextStyles.bodyLarge.copyWith(color: BingoColors.bark),
        bodyMedium: BingoTextStyles.bodyMedium.copyWith(color: BingoColors.bark),
        bodySmall: BingoTextStyles.bodySmall.copyWith(color: BingoColors.stone),
        labelLarge: BingoTextStyles.labelLarge.copyWith(color: BingoColors.emeraldGreen),
        labelSmall: BingoTextStyles.labelSmall.copyWith(color: BingoColors.stone),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
cardTheme: const CardThemeData(
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(24)),
  ),
),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: BingoColors.cream,
        selectedItemColor: BingoColors.emeraldGreen,
        unselectedItemColor: BingoColors.stone,
        type: BottomNavigationBarType.fixed,
        elevation: 2,
        landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: BingoColors.pebble.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: BingoColors.emeraldGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: BingoColors.darkForest,
      colorScheme: const ColorScheme.dark(
        primary: BingoColors.glowGreen,
        secondary: BingoColors.mintGreen,
        surface: BingoColors.darkCanopy,
        background: BingoColors.darkForest,
        error: BingoColors.priorityHigh,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: BingoTextStyles.displayLarge.copyWith(color: BingoColors.paleGreen),
        displayMedium: BingoTextStyles.displayMedium.copyWith(color: BingoColors.paleGreen),
        displaySmall: BingoTextStyles.displaySmall.copyWith(color: BingoColors.softMint),
        headlineLarge: BingoTextStyles.headlineLarge.copyWith(color: BingoColors.paleGreen),
        headlineMedium: BingoTextStyles.headlineMedium.copyWith(color: BingoColors.softMint),
        headlineSmall: BingoTextStyles.headlineSmall.copyWith(color: BingoColors.mintGreen),
        bodyLarge: BingoTextStyles.bodyLarge.copyWith(color: BingoColors.paleGreen.withOpacity(0.85)),
        bodyMedium: BingoTextStyles.bodyMedium.copyWith(color: BingoColors.softMint.withOpacity(0.75)),
        bodySmall: BingoTextStyles.bodySmall.copyWith(color: BingoColors.mintGreen.withOpacity(0.6)),
        labelLarge: BingoTextStyles.labelLarge.copyWith(color: BingoColors.mintGreen),
        labelSmall: BingoTextStyles.labelSmall.copyWith(color: BingoColors.mintGreen),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
cardTheme: const CardThemeData(
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(24)),
  ),
),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: BingoColors.darkForest,
        selectedItemColor: BingoColors.glowGreen,
        unselectedItemColor: BingoColors.stone,
        type: BottomNavigationBarType.fixed,
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BingoColors.darkFern,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: BingoColors.mintGreen.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: BingoColors.glowGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}

// ============================================================
// 🧩 Decorations – Premium, low‑overhead shadows & cards
// ============================================================
class BingoDecorations {
  // Light, premium card with subtle border & low blur shadow
  static BoxDecoration solidCard({
    Color? color,
    double radius = 24,
    bool isDark = false,
  }) {
    return BoxDecoration(
      color: color ??
          (isDark ? BingoColors.darkCanopy : Colors.white),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark
            ? BingoColors.darkFern
            : BingoColors.pebble.withOpacity(0.2),
        width: 0.8,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.2)
              : BingoColors.forestGreen.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Glassmorphism alternative – very light, only for special cards
  static BoxDecoration glassCard({
    Color? borderColor,
    double radius = 24,
    bool isDark = false,
  }) {
    return BoxDecoration(
      color: isDark
          ? BingoColors.darkCanopy.withOpacity(0.7)
          : Colors.white.withOpacity(0.75),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ??
            (isDark
                ? BingoColors.glowGreen.withOpacity(0.15)
                : BingoColors.mistGreen.withOpacity(0.6)),
        width: 0.8,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.15)
              : BingoColors.forestGreen.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}