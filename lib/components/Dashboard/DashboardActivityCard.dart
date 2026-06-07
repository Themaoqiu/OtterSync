import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/components/Common/UserAvatar.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

class DashboardActivityCard extends StatelessWidget {
  const DashboardActivityCard({
    super.key,
    required this.activities,
    required this.onActivityTap,
    required this.userInitials,
  });

  final List<DashboardActivityItem> activities;
  final ValueChanged<DashboardActivityItem> onActivityTap;
  final String userInitials;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('活动流', style: theme.textTheme.titleMedium),
              ),
              Text(
                '近期',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: palette.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  '暂无新活动',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: palette.textSecondary),
                ),
              ),
            )
          else
            ...activities.asMap().entries.map(
                  (entry) => Column(
                    children: [
                      InkWell(
                        onTap: () => onActivityTap(entry.value),
                        borderRadius: BorderRadius.circular(AppSpace.radius),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              UserAvatar(label: userInitials, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.value.text,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(height: 1.4),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          color: palette.textTertiary,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          entry.value.time,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (entry.key != activities.length - 1)
                        Divider(
                            height: 1, color: palette.divider, indent: 44),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
