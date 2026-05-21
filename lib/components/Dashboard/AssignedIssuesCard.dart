import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

class AssignedIssuesCard extends StatelessWidget {
  const AssignedIssuesCard({
    super.key,
    required this.issues,
    required this.onIssueTap,
  });

  final List<IssueSummary> issues;
  final ValueChanged<IssueSummary> onIssueTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('分配给我', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Text('事务类型', style: theme.textTheme.bodyMedium)),
              Expanded(child: Text('密钥', style: theme.textTheme.bodyMedium)),
              Expanded(
                child: Text(
                  '摘要',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: palette.divider),
          const SizedBox(height: 14),
          ...issues.map(
            (item) => InkWell(
              onTap: () => onIssueTap(item),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_box_outline_blank_rounded,
                      color: palette.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(item.key, style: theme.textTheme.titleMedium),
                    ),
                    Expanded(
                      child: Text(
                        item.title,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
