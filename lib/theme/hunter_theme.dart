import 'package:flutter/material.dart';

/// Hunter System — Design Theme (Solo Leveling Aesthetic)
class HunterTheme {
  HunterTheme._();

  // Core Colors
  static const Color bgDark = Color(0xFF070913);
  static const Color bgCard = Color(0xFF0d1117);
  static const Color bgCardLight = Color(0xFF161b22);
  static const Color bgSurface = Color(0xFF1a1f2e);
  static const Color borderDim = Color(0xFF21262d);
  static const Color borderLight = Color(0xFF30363d);

  // Accent Colors
  static const Color cyan = Color(0xFF06b6d4);
  static const Color cyanLight = Color(0xFF67e8f9);
  static const Color purple = Color(0xFF8b5cf6);
  static const Color pink = Color(0xFFec4899);
  static const Color amber = Color(0xFFf59e0b);
  static const Color emerald = Color(0xFF10b981);
  static const Color red = Color(0xFFef4444);
  static const Color blue = Color(0xFF3b82f6);
  static const Color rose = Color(0xFFf43f5e);
  static const Color slate300 = Color(0xFFcbd5e1);
  static const Color slate400 = Color(0xFF94a3b8);
  static const Color slate500 = Color(0xFF64748b);
  static const Color slate600 = Color(0xFF475569);

  // Text Colors
  static const Color textPrimary = Color(0xFFf8fafc);
  static const Color textSecondary = Color(0xFF94a3b8);
  static const Color textMuted = Color(0xFF64748b);

  // Stat Colors
  static const Color strColor = Color(0xFFef4444);
  static const Color agiColor = Color(0xFF06b6d4);
  static const Color vitColor = Color(0xFF10b981);
  static const Color intColor = Color(0xFF8b5cf6);
  static const Color percColor = Color(0xFFf59e0b);

  // HP / MP
  static const Color hpColor = Color(0xFFf43f5e);
  static const Color mpColor = Color(0xFF3b82f6);

  // Gradients
  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF06b6d4), Color(0xFF3b82f6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF8b5cf6), Color(0xFFec4899)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient hpGradient = LinearGradient(
    colors: [Color(0xFFef4444), Color(0xFFf43f5e)],
  );

  static const LinearGradient mpGradient = LinearGradient(
    colors: [Color(0xFF3b82f6), Color(0xFF06b6d4)],
  );

  static const LinearGradient xpGradient = LinearGradient(
    colors: [Color(0xFF06b6d4), Color(0xFF8b5cf6), Color(0xFFec4899)],
  );

  // Card Decoration
  static BoxDecoration cardDecoration({
    Color? borderColor,
    double borderWidth = 1,
    double radius = 12,
  }) {
    return BoxDecoration(
      color: bgCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? borderDim,
        width: borderWidth,
      ),
    );
  }

  static BoxDecoration glowCardDecoration({
    required Color glowColor,
    double radius = 12,
  }) {
    return BoxDecoration(
      color: bgCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: glowColor.withValues(alpha: 0.4)),
      boxShadow: [
        BoxShadow(
          color: glowColor.withValues(alpha: 0.15),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }

  // Button Styles
  static ButtonStyle primaryButtonStyle({Color? color}) {
    final c = color ?? cyan;
    return ElevatedButton.styleFrom(
      backgroundColor: c.withValues(alpha: 0.15),
      foregroundColor: c,
      side: BorderSide(color: c.withValues(alpha: 0.5)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 0,
      textStyle: const TextStyle(
        fontFamily: 'Orbitron',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }

  static ButtonStyle secondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: slate400,
      side: const BorderSide(color: borderLight),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        fontFamily: 'Rajdhani',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }

  // ThemeData
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: cyan,
        secondary: purple,
        surface: bgCard,
        error: red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgCard,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 2,
        ),
        iconTheme: IconThemeData(color: cyan),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderDim),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: cyan, width: 1.5),
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Rajdhani',
          color: slate500,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Rajdhani',
          color: slate400,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgCard,
        selectedItemColor: cyan,
        unselectedItemColor: slate500,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
