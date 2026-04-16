import 'package:flutter/material.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

class RecentProjectsCard extends StatelessWidget {
  const RecentProjectsCard({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  final List<JiraIssueSummary> items;
  final ValueChanged<JiraIssueSummary> onItemTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: AppDecorations.surface(
        context,
        radius: 28,
        customShadow: AppShadows.dialog,
      ),
      child: Column(
        children: items
            .asMap()
            .entries
            .map(
              (entry) => Column(
                children: [
                  _RecentProjectRow(
                    item: entry.value,
                    onTap: () => onItemTap(entry.value),
                  ),
                  if (entry.key != items.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 14,
                      ),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: palette.divider,
                      ),
                    ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _RecentProjectRow extends StatelessWidget {
  const _RecentProjectRow({required this.item, required this.onTap});

  final JiraIssueSummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
          decoration: BoxDecoration(
            color: palette.surfaceRaised.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            children: [
              _RecentProjectIcon(item: item),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${item.key} • ${item.subtitle ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: palette.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentProjectIcon extends StatelessWidget {
  const _RecentProjectIcon({required this.item});

  final JiraIssueSummary item;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final iconColor = item.iconColor ?? palette.primary;
    final backgroundColor =
        item.iconBackgroundColor ?? palette.primarySoft.withValues(alpha: 0.75);

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        item.icon ?? Icons.task_alt_rounded,
        color: iconColor,
        size: 32,
      ),
    );
  }
}
