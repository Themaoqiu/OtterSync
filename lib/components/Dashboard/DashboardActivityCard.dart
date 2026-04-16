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
  });

  final List<DashboardActivityItem> activities;
  final ValueChanged<DashboardActivityItem> onActivityTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('活动流', style: theme.textTheme.titleLarge),
          const SizedBox(height: 18),
          Text('今天', style: theme.textTheme.titleLarge),
          const SizedBox(height: 18),
          ...activities.asMap().entries.map(
            (entry) => Column(
              children: [
                InkWell(
                  onTap: () => onActivityTap(entry.value),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const UserAvatar(label: 'MT'),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: palette.textPrimary,
                                  height: 1.45,
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'maoqiu The ',
                                    style: TextStyle(),
                                  ),
                                  TextSpan(
                                    text: entry.value.text.replaceFirst(
                                      'maoqiu The ',
                                      '',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              entry.value.issue,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.task_alt_rounded,
                                  color: palette.primary,
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  entry.value.time,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (entry.key != activities.length - 1) ...[
                  const SizedBox(height: 18),
                  Divider(color: palette.divider, indent: 66),
                  const SizedBox(height: 18),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.sync_rounded, color: palette.primary),
              const SizedBox(width: 8),
              Text('刚刚', style: theme.textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}
