import 'package:material_ui/material_ui.dart';

/// Stegoland brand palette — taken from the logo: deep-space navy,
/// rocket red, astronaut white, flame yellow and porthole sky blue.
abstract final class StegoColors {
  static const navy = Color(0xFF0F2C7E);
  static const navyDeep = Color(0xFF0A1F5C);
  static const navySoft = Color(0xFF2448A8);
  static const rocket = Color(0xFFE53935);
  static const flame = Color(0xFFFFC93C);
  static const sky = Color(0xFF4FB3F6);
  static const skyTint = Color(0xFFE6F2FF);
  static const mint = Color(0xFF12A579);
  static const ink = Color(0xFF17213D);
  static const muted = Color(0xFF6B7591);
  static const line = Color(0xFFE5EAF3);
  static const surface = Color(0xFFF4F7FC);

  /// Jasmine Cafe sub-brand accent (warm jasmine green).
  static const jasmine = Color(0xFF2E7D5B);
  static const jasmineTint = Color(0xFFE7F5EE);
}

abstract final class StegoTheme {
  static const display = 'Fredoka';
  static const body = 'Nunito';

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: StegoColors.navy,
      primary: StegoColors.navy,
      secondary: StegoColors.flame,
      tertiary: StegoColors.rocket,
      surface: Colors.white,
      error: StegoColors.rocket,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: body,
      scaffoldBackgroundColor: StegoColors.surface,
    );

    final text = base.textTheme.apply(bodyColor: StegoColors.ink, displayColor: StegoColors.ink);

    TextStyle? d(TextStyle? s, FontWeight w) => s?.copyWith(fontFamily: display, fontWeight: w, letterSpacing: 0);

    return base.copyWith(
      textTheme: text.copyWith(
        displaySmall: d(text.displaySmall, FontWeight.w700),
        headlineLarge: d(text.headlineLarge, FontWeight.w700),
        headlineMedium: d(text.headlineMedium, FontWeight.w700),
        headlineSmall: d(text.headlineSmall, FontWeight.w600),
        titleLarge: d(text.titleLarge, FontWeight.w600),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        bodyMedium: text.bodyMedium?.copyWith(height: 1.4),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: StegoColors.surface,
        foregroundColor: StegoColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: display,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: StegoColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: StegoColors.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontFamily: body, fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 50),
          side: const BorderSide(color: StegoColors.line, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontFamily: body, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: StegoColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: StegoColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: StegoColors.navy, width: 2),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: const BorderSide(color: StegoColors.line),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontFamily: body),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: StegoColors.flame.withValues(alpha: 0.35),
        height: 70,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontFamily: body,
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
            color: s.contains(WidgetState.selected) ? StegoColors.navy : StegoColors.muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? StegoColors.navy : StegoColors.muted),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: StegoColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(color: StegoColors.line, space: 1),
    );
  }
}
