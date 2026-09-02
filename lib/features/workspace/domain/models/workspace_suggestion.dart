import 'package:flutter/material.dart';

/// A proactive AI suggestion inside a workspace.
class WorkspaceSuggestion {
  const WorkspaceSuggestion({
    required this.id,
    required this.title,
    required this.description,
    this.icon = Icons.auto_awesome_rounded,
    this.actionLabel = 'Do this',
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String actionLabel;
}
