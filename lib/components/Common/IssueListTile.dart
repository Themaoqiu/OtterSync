import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/UserAvatar.dart';
import 'package:ottersync/theme/design_tokens.dart';

class IssueListTile extends StatelessWidget {
  const IssueListTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.status,
    this.avatar,
    this.trailing,
    this.compact = false,
    this.onTap,
    this.done,
    this.onToggleDone,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final String? status;
  final String? avatar;
  final Widget? trailing;
  final bool compact;
  final VoidCallback? onTap;

  final bool? done;
  final ValueChanged<bool>? onToggleDone;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);

    return Container(
      decoration: AppDecorations.surface(
        context,
        border: Border.all(color: Colors.transparent),
        customShadow: AppShadows.cardSoft,
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpace.radiusLarge),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading ??
                    (done != null
                        ? _IssueToggleCheckbox(
                            done: done!,
                            color: palette.primary,
                            onToggle: onToggleDone,
                          )
                        : _IssueCheckbox(color: palette.primary)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: done == true
                              ? palette.textSecondary
                              : palette.textPrimary,
                          height: 1.2,
                          decoration: done == true
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: palette.textSecondary,
                          height: 1.3,
                        ),
                      ),
                      if (!compact && (status != null || avatar != null)) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            if (status != null) _StatusBadge(status: status!),
                            if (status != null && avatar != null)
                              const SizedBox(width: 10),
                            if (avatar != null)
                              UserAvatar(label: avatar!, size: 24),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);

    // Simple status color mapping logic
    Color bgColor = palette.surfaceInset;
    Color textColor = palette.textSecondary;

    final s = status.toUpperCase();
    if (s.contains('DONE') || s.contains('RESOLVED')) {
      bgColor = palette.success.withValues(alpha: 0.15);
      textColor = palette.success;
    } else if (s.contains('PROGRESS') || s.contains('REVIEW')) {
      bgColor = palette.primarySoft;
      textColor = palette.primaryStrong;
    } else if (s.contains('TODO') || s.contains('OPEN')) {
      bgColor = palette.surfaceInset;
      textColor = palette.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpace.radiusSmall),
      ),
      child: Text(
        status.toUpperCase(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor,
          letterSpacing: 0.5,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _IssueCheckbox extends StatelessWidget {
  const _IssueCheckbox({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Icon(Icons.check_rounded, color: color, size: 18),
    );
  }
}

class _IssueToggleCheckbox extends StatelessWidget {
  const _IssueToggleCheckbox({
    required this.done,
    required this.color,
    this.onToggle,
  });

  final bool done;
  final Color color;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: done ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: done ? 1 : 0.5),
            width: 1.5,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onToggle == null ? null : () => onToggle!(!done),
            splashColor: (done ? Colors.white : color).withValues(alpha: 0.22),
            highlightColor: (done ? Colors.white : color).withValues(
              alpha: 0.1,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
                child: child,
              ),
              child: done
                  ? const Icon(
                      Icons.check_rounded,
                      key: ValueKey(true),
                      color: Colors.white,
                      size: 18,
                    )
                  : const SizedBox.shrink(key: ValueKey(false)),
            ),
          ),
        ),
      ),
    );
  }
}
