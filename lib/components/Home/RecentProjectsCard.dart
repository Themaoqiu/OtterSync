import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

class RecentProjectsCard extends StatelessWidget {
  const RecentProjectsCard({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  final List<IssueSummary> items;
  final ValueChanged<IssueSummary> onItemTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);

    return AppSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      radius: 14,
      customShadow: AppShadows.cardSoft,
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
                      padding: const EdgeInsets.symmetric(horizontal: 14),
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

  final IssueSummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              _RecentProjectIcon(item: item),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: palette.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),

                    Text(
                      '${item.key} • ${item.subtitle ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: palette.textSecondary,
                        fontSize: 13,
                        height: 1.15,
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

  final IssueSummary item;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final iconColor = item.iconColor ?? palette.primary;
    final backgroundColor =
        item.iconBackgroundColor ?? palette.primarySoft.withValues(alpha: 0.75);

    final iconWidget = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        item.icon ?? Icons.task_alt_rounded,
        color: iconColor,
        size: 26,
      ),
    );

    if (item.id == null) {
      return iconWidget;
    }
    return Hero(
      tag: 'work-item-icon-${item.id}',
      flightShuttleBuilder: (
        flightContext,
        animation,
        direction,
        fromContext,
        toContext,
      ) {
        final hero = (direction == HeroFlightDirection.push
                ? toContext.widget
                : fromContext.widget) as Hero;
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 1.04).animate(curved),
          child: hero.child,
        );
      },
      child: iconWidget,
    );
  }
}
