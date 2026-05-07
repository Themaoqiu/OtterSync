import 'package:flutter/material.dart';

enum WorkItemStatus { todo, inProgress, done }

enum WorkItemBucket { backlog, sprint }

class QuickAccessItem {
  const QuickAccessItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.iconTint,
    this.badge,
    this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color? iconTint;
  final String? badge;
  final String? route;
}

class IssueSummary {
  const IssueSummary({
    required this.title,
    required this.key,
    this.subtitle,
    this.status,
    this.assigneeInitials,
    this.icon,
    this.iconBackgroundColor,
    this.iconColor,
    this.statusKey = WorkItemStatus.todo,
    this.bucket = WorkItemBucket.backlog,
    this.workspaceId,
    this.startDate,
    this.dueDate,
  });

  final String title;
  final String key;
  final String? subtitle;
  final String? status;
  final String? assigneeInitials;
  final IconData? icon;
  final Color? iconBackgroundColor;
  final Color? iconColor;
  final WorkItemStatus statusKey;
  final WorkItemBucket bucket;
  final int? workspaceId;
  final DateTime? startDate;
  final DateTime? dueDate;
}

class JiraSpace {
  const JiraSpace({
    this.id = 0,
    required this.name,
    required this.key,
    this.template = '看板',
    this.issueCount = 0,
    this.avatar = const SpaceAvatarSpec(
      gradient: [Color(0xFF563FD6), Color(0xFF7C69EA)],
      icon: Icons.public_rounded,
      iconColor: Colors.white,
    ),
  });

  final int id;
  final String name;
  final String key;
  final String template;
  final int issueCount;
  final SpaceAvatarSpec avatar;
}

class SpaceSummaryMetric {
  const SpaceSummaryMetric({
    required this.headline,
    required this.value,
    required this.icon,
    required this.color,
    required this.emphasis,
  });

  final String headline;
  final String value;
  final IconData icon;
  final Color color;
  final String emphasis;
}

class DashboardActivityItem {
  const DashboardActivityItem({
    required this.text,
    required this.issue,
    required this.time,
  });

  final String text;
  final String issue;
  final String time;
}

class NotificationItem {
  const NotificationItem({
    required this.title,
    required this.description,
    this.route,
  });

  final String title;
  final String description;
  final String? route;
}

class FilterItem {
  const FilterItem({required this.title, required this.icon});

  final String title;
  final IconData icon;
}

class BacklogGroup {
  const BacklogGroup({
    required this.title,
    required this.issueCount,
    required this.todoCount,
    required this.inProgressCount,
    required this.doneCount,
    required this.items,
  });

  final String title;
  final int issueCount;
  final int todoCount;
  final int inProgressCount;
  final int doneCount;
  final List<IssueSummary> items;
}

class SpaceAvatarSpec {
  const SpaceAvatarSpec({
    required this.gradient,
    required this.icon,
    required this.iconColor,
  });

  final List<Color> gradient;
  final IconData icon;
  final Color iconColor;
}

String generateWorkspaceKey(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  final asciiLetters = trimmed.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
  if (asciiLetters.length >= 4) {
    return asciiLetters.substring(0, 4);
  }

  final buffer = StringBuffer(asciiLetters);
  for (final char in trimmed.characters) {
    if (buffer.length >= 4) {
      break;
    }
    if (char.trim().isEmpty) {
      continue;
    }

    if (_isAsciiAlphaNumeric(char)) {
      buffer.write(char.toUpperCase());
      continue;
    }

    buffer.write(_stableAlphaNumericToken(char));
  }

  final generated = buffer.toString();
  if (generated.isEmpty) {
    return '';
  }

  final completed = StringBuffer(generated);
  while (completed.length < 4) {
    completed.write(generated[completed.length % generated.length]);
  }
  return completed.toString().substring(0, 4);
}

SpaceAvatarSpec buildSpaceAvatar(String seed) {
  final normalized = seed.trim().isEmpty ? '0' : seed.trim().toUpperCase();
  final paletteIndex = normalized.runes.fold<int>(0, (value, rune) => value + rune);
  final iconIndex = normalized.runes.fold<int>(0, (value, rune) => value ^ rune);

  const gradients = [
    [Color(0xFF5B4BFF), Color(0xFF8C7BFF)],
    [Color(0xFF0C66E4), Color(0xFF52A6FF)],
    [Color(0xFFEF5DA8), Color(0xFFFF9CC2)],
    [Color(0xFF0F9B8E), Color(0xFF42C7B4)],
    [Color(0xFFFF8B00), Color(0xFFFFC266)],
    [Color(0xFF434343), Color(0xFF767676)],
  ];
  const icons = [
    Icons.space_dashboard_rounded,
    Icons.view_kanban_rounded,
    Icons.auto_awesome_rounded,
    Icons.bolt_rounded,
    Icons.cloud_rounded,
    Icons.rocket_launch_rounded,
  ];

  return SpaceAvatarSpec(
    gradient: gradients[paletteIndex % gradients.length],
    icon: icons[iconIndex % icons.length],
    iconColor: Colors.white,
  );
}

String workItemStatusLabel(WorkItemStatus status) {
  switch (status) {
    case WorkItemStatus.todo:
      return '待办';
    case WorkItemStatus.inProgress:
      return '正在进行';
    case WorkItemStatus.done:
      return '已完成';
  }
}

bool _isAsciiAlphaNumeric(String value) {
  return RegExp(r'^[A-Za-z0-9]$').hasMatch(value);
}

String _stableAlphaNumericToken(String value) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final hash = value.runes.fold<int>(0, (current, rune) => current * 37 + rune);
  return alphabet[hash % alphabet.length];
}
