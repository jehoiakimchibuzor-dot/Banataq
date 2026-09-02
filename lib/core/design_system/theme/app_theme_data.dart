import 'package:flutter/material.dart';
import '../tokens/borders.dart';
import '../tokens/radius.dart';
import 'app_color_scheme.dart';
import 'app_theme_extensions.dart';

/// Builds the full Banataq [ThemeData] for light and dark.
///
/// Every component theme is defined here so widgets stay thin and no value
/// is hardcoded at the call site.
abstract final class AppThemeData {
  static ThemeData light() => _build(AppColorScheme.light, Brightness.light);
  static ThemeData dark() => _build(AppColorScheme.dark, Brightness.dark);
  static ThemeData fromScheme(ColorScheme scheme, Brightness b) => _build(scheme, b);
  static ThemeData fromMode(ThemeMode mode) => switch (mode) {
        ThemeMode.light => light(),
        ThemeMode.dark => dark(),
        ThemeMode.system => light(),
      };

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final surfaceMuted = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : scheme.surfaceContainerHighest;

    final textTheme = _textTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      fontFamily: 'Arial',
      textTheme: textTheme,
      extensions: AppThemeExtensions.all(brightness),

      // ---- Buttons ----
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          backgroundColor: Colors.transparent,
          side: BorderSide(color: scheme.outlineVariant, width: AppBorders.hairline),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xs)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          highlightColor: scheme.primary.withValues(alpha: 0.10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: AppElevationTheme(brightness: brightness).md,
        focusElevation: AppElevationTheme(brightness: brightness).lg,
        hoverElevation: AppElevationTheme(brightness: brightness).sm,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        extendedTextStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),

      // ---- Surfaces ----
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: isDark ? 0.55 : 0.8),
        thickness: AppBorders.hairline,
        space: 1,
      ),

      // ---- Inputs ----
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMuted,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.75), fontWeight: FontWeight.w400),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        helperStyle: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        errorStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.outlineVariant, width: AppBorders.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.outlineVariant, width: AppBorders.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: AppBorders.regular),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.error, width: AppBorders.hairline),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.error, width: AppBorders.regular),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4), width: AppBorders.hairline),
        ),
      ),

      // ---- Chips ----
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primaryContainer,
        disabledColor: scheme.surfaceContainerHighest,
        side: BorderSide(color: scheme.outlineVariant, width: AppBorders.hairline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xs)),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        iconTheme: IconThemeData(size: 18, color: scheme.onSurfaceVariant),
        checkmarkColor: scheme.primary,
        brightness: brightness,
      ),

      // ---- Feedback ----
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface, fontWeight: FontWeight.w600, fontSize: 14),
        elevation: AppElevationTheme(brightness: brightness).md,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        insetPadding: const EdgeInsets.all(16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        elevation: AppElevationTheme(brightness: brightness).xl,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        contentTextStyle: TextStyle(fontSize: 14, height: 1.5, color: scheme.onSurfaceVariant),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        modalBackgroundColor: scheme.surfaceContainerLow,
        elevation: AppElevationTheme(brightness: brightness).lg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        modalBarrierColor: Colors.black.withValues(alpha: 0.55),
      ),

      // ---- Navigation ----
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: scheme.onSurface,
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelTextStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
        useIndicator: true,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
      ),

      // ---- Progress ----
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        textStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 12),
        waitDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  static TextTheme _textTheme() {
    return const TextTheme(
      displayLarge: TextStyle(fontSize: 40, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -1),
      displayMedium: TextStyle(fontSize: 36, height: 1.12, fontWeight: FontWeight.w900, letterSpacing: -0.5),
      displaySmall: TextStyle(fontSize: 32, height: 1.15, fontWeight: FontWeight.w800),
      headlineLarge: TextStyle(fontSize: 28, height: 1.2, fontWeight: FontWeight.w800),
      headlineMedium: TextStyle(fontSize: 24, height: 1.25, fontWeight: FontWeight.w800),
      headlineSmall: TextStyle(fontSize: 20, height: 1.3, fontWeight: FontWeight.w800),
      titleLarge: TextStyle(fontSize: 18, height: 1.3, fontWeight: FontWeight.w800),
      titleMedium: TextStyle(fontSize: 16, height: 1.35, fontWeight: FontWeight.w700),
      titleSmall: TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(fontSize: 12, height: 1.45, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w700),
      labelMedium: TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(fontSize: 11, height: 1.4, fontWeight: FontWeight.w600),
    );
  }
}
