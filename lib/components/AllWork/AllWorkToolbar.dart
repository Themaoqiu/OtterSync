import 'package:flutter/material.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

enum AllWorkViewMode { list, grid }

class AllWorkToolbar extends StatelessWidget {
  const AllWorkToolbar({
    super.key,
    required this.selectedFilter,
    required this.viewMode,
    required this.onFilterTap,
    required this.onViewModeChanged,
  });

  final FilterItem selectedFilter;
  final AllWorkViewMode viewMode;
  final VoidCallback onFilterTap;
  final ValueChanged<AllWorkViewMode> onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: InkWell(
            onTap: onFilterTap,
            borderRadius: BorderRadius.circular(AppSpace.radiusLarge),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(AppSpace.radiusLarge),
                border: Border.all(
                  color: isDark ? palette.border : Colors.transparent,
                ),
                boxShadow: isDark ? null : AppShadows.cardSoft,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: palette.primarySoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      selectedFilter.icon,
                      color: palette.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedFilter.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: palette.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _ViewModeButton(
          icon: Icons.view_headline_rounded,
          selected: viewMode == AllWorkViewMode.list,
          onTap: () => onViewModeChanged(AllWorkViewMode.list),
        ),
        const SizedBox(width: 8),
        _ViewModeButton(
          icon: Icons.grid_view_rounded,
          selected: viewMode == AllWorkViewMode.grid,
          onTap: () => onViewModeChanged(AllWorkViewMode.grid),
        ),
      ],
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  const _ViewModeButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppSpace.radiusLarge);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: selected ? palette.primarySoft : palette.surface,
        borderRadius: radius,
        border: Border.all(
          color: isDark && !selected ? palette.border : Colors.transparent,
        ),
        boxShadow: isDark || selected ? null : AppShadows.cardSoft,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: palette.primary.withValues(alpha: 0.18),
          highlightColor: palette.primary.withValues(alpha: 0.08),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Icon(
                icon,
                key: ValueKey(selected),
                color: selected ? palette.primary : palette.textSecondary,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
