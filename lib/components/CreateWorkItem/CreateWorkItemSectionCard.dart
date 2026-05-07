import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/theme/design_tokens.dart';

class CreateWorkItemSectionCard extends StatelessWidget {
  const CreateWorkItemSectionCard({
    required this.title,
    required this.child,
    this.collapsible = false,
    this.expanded = true,
    this.onToggle,
    super.key,
  });

  final String title;
  final Widget child;
  final bool collapsible;
  final bool expanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    return AppSurface(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      radius: AppSpace.radiusXLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (collapsible)
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(AppSpace.radius),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeInOutCubicEmphasized,
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          if (!collapsible)
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            reverseDuration: const Duration(milliseconds: 220),
            curve: Curves.easeInOutCubicEmphasized,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              reverseDuration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1,
                    child: child,
                  ),
                );
              },
              child: expanded
                  ? Padding(
                      key: ValueKey<String>('section-$title-open'),
                      padding: const EdgeInsets.only(top: 18),
                      child: child,
                    )
                  : const SizedBox.shrink(
                      key: ValueKey<String>('section-closed'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
