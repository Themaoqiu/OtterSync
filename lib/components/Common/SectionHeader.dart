import 'package:flutter/material.dart';
import 'package:ottersync/theme/design_tokens.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.expanded,
    this.onToggle,
    this.compact = false,
  });

  final String title;
  final Widget? action;
  final bool? expanded;
  final VoidCallback? onToggle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: compact
                ? theme.textTheme.titleMedium
                : theme.textTheme.titleLarge,
          ),
        ),
        if (action != null) ...[action!, const SizedBox(width: 6)],
        if (onToggle != null && expanded != null)
          _SectionChevron(expanded: expanded!, onTap: onToggle!),
      ],
    );
  }
}

class _SectionChevron extends StatelessWidget {
  const _SectionChevron({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpace.radiusFull),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpace.radiusFull),
            color: expanded
                ? palette.surface.withValues(alpha: 0.72)
                : Colors.transparent,
          ),
          child: AnimatedRotation(
            turns: expanded ? 0 : -0.25,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: Icon(
              Icons.expand_more_rounded,
              color: palette.textPrimary,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}
