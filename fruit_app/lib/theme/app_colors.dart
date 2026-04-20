import 'package:flutter/material.dart';

import '../models/fruit_prediction.dart';

/// Light palette — mirrors Expo colors.light exactly
class AppColors {
  static const background       = Color(0xFFF7FAF8); // "#F7FAF8"
  static const foreground       = Color(0xFF111827); // "#111827"
  static const card             = Color(0xFFFFFFFF); // "#FFFFFF"
  static const cardForeground   = Color(0xFF111827);
  static const primary          = Color(0xFF2D9B5A); // "#2D9B5A"
  static const primaryForeground= Color(0xFFFFFFFF);
  static const secondary        = Color(0xFFE6F4EC); // "#E6F4EC"
  static const secondaryForeground = Color(0xFF1A5C34);
  static const muted            = Color(0xFFEEF2EE); // "#EEF2EE"
  static const mutedForeground  = Color(0xFF6B7280);
  static const accent           = Color(0xFFF0C830); // "#F0C830"
  static const accentForeground = Color(0xFF1A1A00);
  static const destructive      = Color(0xFFEF4444); // "#EF4444"
  static const destructiveForeground = Color(0xFFFFFFFF);
  static const border           = Color(0xFFE2EBE6); // "#E2EBE6"
  static const input            = Color(0xFFE2EBE6);
  static const warning          = Color(0xFFF97316); // "#F97316"
  static const fresh            = Color(0xFF2D9B5A);
  static const ripening         = Color(0xFFF0C830);
  static const nearExpiry       = Color(0xFFF97316);
  static const spoiled          = Color(0xFFEF4444);
  static const double radius    = 16.0;

  static Color statusColor(FruitStatus status) {
    switch (status) {
      case FruitStatus.fresh:      return fresh;
      case FruitStatus.ripening:   return ripening;
      case FruitStatus.nearExpiry: return nearExpiry;
      case FruitStatus.spoiled:    return spoiled;
    }
  }
}

/// Dark palette — mirrors Expo colors.dark exactly
class AppDarkColors {
  static const background       = Color(0xFF0D1A12); // "#0D1A12"
  static const foreground       = Color(0xFFF0FAF4); // "#F0FAF4"
  static const card             = Color(0xFF142019); // "#142019"
  static const cardForeground   = Color(0xFFF0FAF4);
  static const primary          = Color(0xFF4AC97A); // "#4AC97A"
  static const primaryForeground= Color(0xFF0D1A12);
  static const secondary        = Color(0xFF1C3327); // "#1C3327"
  static const secondaryForeground = Color(0xFFA7DFC0);
  static const muted            = Color(0xFF1A2E21); // "#1A2E21"
  static const mutedForeground  = Color(0xFF9CA3AF);
  static const accent           = Color(0xFFF0C830); // "#F0C830"
  static const accentForeground = Color(0xFF1A1A00);
  static const destructive      = Color(0xFFEF4444); // "#EF4444"
  static const destructiveForeground = Color(0xFFFFFFFF);
  static const border           = Color(0xFF243B2C); // "#243B2C"
  static const input            = Color(0xFF243B2C);
  static const warning          = Color(0xFFF97316); // "#F97316"
  static const fresh            = Color(0xFF4AC97A); // "#4AC97A"
  static const ripening         = Color(0xFFF0C830);
  static const nearExpiry       = Color(0xFFF97316);
  static const spoiled          = Color(0xFFEF4444);

  static Color statusColor(FruitStatus status) {
    switch (status) {
      case FruitStatus.fresh:      return fresh;
      case FruitStatus.ripening:   return ripening;
      case FruitStatus.nearExpiry: return nearExpiry;
      case FruitStatus.spoiled:    return spoiled;
    }
  }
}

class AppTheme {
  // ── Light ──────────────────────────────────────────────────────────────────
  static ThemeData get light => _build(
    scheme: const ColorScheme.light(
      primary:                  AppColors.primary,
      onPrimary:                AppColors.primaryForeground,
      secondary:                AppColors.secondary,
      onSecondary:              AppColors.secondaryForeground,
      surface:                  AppColors.background,
      onSurface:                AppColors.foreground,
      surfaceContainer:         AppColors.card,
      surfaceContainerLow:      AppColors.card,
      surfaceContainerHigh:     AppColors.card,
      surfaceContainerHighest:  AppColors.card,
      surfaceTint:              Colors.transparent,
      error:                    AppColors.destructive,
      onError:                  AppColors.destructiveForeground,
      outline:                  AppColors.border,
      outlineVariant:           AppColors.border,
    ),
    scaffoldBg:     AppColors.background,
    cardColor:      AppColors.card,
    borderColor:    AppColors.border,
    mutedColor:     AppColors.muted,
    mutedFg:        AppColors.mutedForeground,
    primaryColor:   AppColors.primary,
    brightness:     Brightness.light,
  );

  // ── Dark ───────────────────────────────────────────────────────────────────
  static ThemeData get dark => _build(
    scheme: const ColorScheme.dark(
      primary:                  AppDarkColors.primary,
      onPrimary:                AppDarkColors.primaryForeground,
      secondary:                AppDarkColors.secondary,
      onSecondary:              AppDarkColors.secondaryForeground,
      surface:                  AppDarkColors.background,
      onSurface:                AppDarkColors.foreground,
      surfaceContainer:         AppDarkColors.card,
      surfaceContainerLow:      AppDarkColors.card,
      surfaceContainerHigh:     AppDarkColors.card,
      surfaceContainerHighest:  AppDarkColors.card,
      surfaceTint:              Colors.transparent,
      error:                    AppDarkColors.destructive,
      onError:                  AppDarkColors.destructiveForeground,
      outline:                  AppDarkColors.border,
      outlineVariant:           AppDarkColors.border,
    ),
    scaffoldBg:     AppDarkColors.background,
    cardColor:      AppDarkColors.card,
    borderColor:    AppDarkColors.border,
    mutedColor:     AppDarkColors.muted,
    mutedFg:        AppDarkColors.mutedForeground,
    primaryColor:   AppDarkColors.primary,
    brightness:     Brightness.dark,
  );

  // ── Shared builder ─────────────────────────────────────────────────────────
  static ThemeData _build({
    required ColorScheme scheme,
    required Color scaffoldBg,
    required Color cardColor,
    required Color borderColor,
    required Color mutedColor,
    required Color mutedFg,
    required Color primaryColor,
    required Brightness brightness,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius:
              const BorderRadius.all(Radius.circular(AppColors.radius)),
          side: BorderSide(color: borderColor),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: scheme.onSurface,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: mutedColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        hintStyle: TextStyle(color: mutedFg),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
