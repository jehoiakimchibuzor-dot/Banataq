import 'package:flutter/material.dart';

/// Hero helpers for shared-element transitions.
///
/// Use [AppHero] instead of a bare `Hero` so tags stay consistent, and
/// [AppHero.tag] to build scoped tags (e.g. `project-<id>`) that prevent
/// collisions across screen types.
class AppHero extends StatelessWidget {
  const AppHero({
    super.key,
    required this.tag,
    required this.child,
    this.transitionOnUserGestures = true,
  });

  final String tag;
  final Widget child;
  final bool transitionOnUserGestures;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      transitionOnUserGestures: transitionOnUserGestures,
      child: child,
    );
  }
}

/// Builds a namespaced hero tag, e.g. `AppHero.tag('project', projectId)`.
String appHeroTag(String prefix, Object id) => '$prefix-$id';
