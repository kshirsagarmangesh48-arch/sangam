import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class FamilyThemeExtension extends ThemeExtension<FamilyThemeExtension> {
  final LinearGradient adminGradient;
  final LinearGradient memberGradient;
  final LinearGradient splashGradient;
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;

  const FamilyThemeExtension({
    required this.adminGradient,
    required this.memberGradient,
    required this.splashGradient,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
  });

  @override
  FamilyThemeExtension copyWith({
    LinearGradient? adminGradient,
    LinearGradient? memberGradient,
    LinearGradient? splashGradient,
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
  }) {
    return FamilyThemeExtension(
      adminGradient: adminGradient ?? this.adminGradient,
      memberGradient: memberGradient ?? this.memberGradient,
      splashGradient: splashGradient ?? this.splashGradient,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
    );
  }

  @override
  FamilyThemeExtension lerp(ThemeExtension<FamilyThemeExtension>? other, double t) {
    if (other is! FamilyThemeExtension) return this;
    return FamilyThemeExtension(
      adminGradient: LinearGradient.lerp(adminGradient, other.adminGradient, t)!,
      memberGradient: LinearGradient.lerp(memberGradient, other.memberGradient, t)!,
      splashGradient: LinearGradient.lerp(splashGradient, other.splashGradient, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

class AppTheme {
  static const Color primary = Color(0xFF1E3A8A); // Deep Indigo
  static const Color primaryContainer = Color(0xFFDBEAFE);
  static const Color onPrimaryContainer = Color(0xFF1E3A8A);

  static const Color secondary = Color(0xFF0F766E); // Teal
  static const Color secondaryContainer = Color(0xFFCCFBF1);
  static const Color onSecondaryContainer = Color(0xFF115E59);

  static const Color tertiary = Color(0xFFD97706); // Amber
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color outline = Color(0xFFCBD5E1);
  static const Color outlineVariant = Color(0xFFE2E8F0);

  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  static const FamilyThemeExtension familyExtension = FamilyThemeExtension(
    adminGradient: LinearGradient(
      colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    memberGradient: LinearGradient(
      colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    splashGradient: LinearGradient(
      colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    success: Color(0xFF10B981),
    successContainer: Color(0xFFD1FAE5),
    onSuccessContainer: Color(0xFF065F46),
    warning: Color(0xFFF59E0B),
  );

  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;
    final textTheme = GoogleFonts.interTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: textSecondary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        color: textSecondary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );

    final colorScheme = const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: outline,
      outlineVariant: outlineVariant,
      error: error,
      onError: Colors.white,
      errorContainer: errorContainer,
      onErrorContainer: error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      extensions: const [familyExtension],
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primaryContainer,
        side: const BorderSide(color: outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        labelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: outlineVariant,
        thickness: 1,
        space: 24,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: textTheme.bodyMedium,
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textSecondary,
          textStyle: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  TextTheme get text => theme.textTheme;
  FamilyThemeExtension get familyTheme =>
      theme.extension<FamilyThemeExtension>() ?? AppTheme.familyExtension;
}
