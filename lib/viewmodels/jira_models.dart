import 'package:flutter/material.dart';

class QuickAccessItem {
  const QuickAccessItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.badge,
    this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
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
  });

  final String title;
  final String key;
  final String? subtitle;
  final String? status;
  final String? assigneeInitials;
  final IconData? icon;
  final Color? iconBackgroundColor;
  final Color? iconColor;
}

class JiraSpace {
  const JiraSpace({required this.name, required this.key});

  final String name;
  final String key;
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
  const NotificationItem({required this.title, required this.description});

  final String title;
  final String description;
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
