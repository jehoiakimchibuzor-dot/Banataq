import 'package:flutter/material.dart';
import '../../tokens/durations.dart';

/// Page transition helpers for consistent, calm navigation.
///
/// Screen changes use a subtle cross-fade with light parallax — never
/// slide/push like a messaging app.
abstract final class AppPageTransitions {
  /// Cross-fade with a gentle upward drift. Default page transition.
  static Route<T> fade<T>(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: AppDurations.normal,
      reverseTransitionDuration: AppDurations.fast,
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.02), end: Offset.zero)
                .animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Slide in from the bottom — for sheets and modals.
  static Route<T> fromBottom<T>(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: AppDurations.medium,
      reverseTransitionDuration: AppDurations.fast,
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: Tween(begin: 0.0, end: 1.0).animate(curved),
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.06), end: Offset.zero)
                .animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Slide in from the right — for drill-in detail screens.
  static Route<T> fromRight<T>(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: AppDurations.normal,
      reverseTransitionDuration: AppDurations.fast,
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: Tween(begin: 0.6, end: 1.0).animate(curved),
          child: SlideTransition(
            position: Tween(begin: const Offset(0.04, 0), end: Offset.zero)
                .animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Scale pop — for cards opening into detail surfaces.
  static Route<T> scale<T>(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: AppDurations.medium,
      reverseTransitionDuration: AppDurations.fast,
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: Tween(begin: 0.0, end: 1.0).animate(curved),
          child: ScaleTransition(
            scale: Tween(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static Future<T?> pushFade<T>(BuildContext context, Widget page) =>
      Navigator.of(context).push(fade<T>(page));

  static Future<T?> pushFromBottom<T>(BuildContext context, Widget page) =>
      Navigator.of(context).push(fromBottom<T>(page));

  static Future<T?> pushFromRight<T>(BuildContext context, Widget page) =>
      Navigator.of(context).push(fromRight<T>(page));

  static Future<T?> pushScale<T>(BuildContext context, Widget page) =>
      Navigator.of(context).push(scale<T>(page));
}
