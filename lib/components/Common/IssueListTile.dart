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
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final String? status;
  final String? avatar;
  final Widget? trailing;
  final bool compact;

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
          onTap: () {}, // Adds ripple effect
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading ?? _IssueCheckbox(color: palette.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
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
          fontWeight: FontWeight.w700,
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
