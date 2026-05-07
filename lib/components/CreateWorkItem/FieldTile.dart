import 'package:flutter/material.dart';
import 'package:ottersync/theme/design_tokens.dart';

class FieldTile extends StatelessWidget {
  const FieldTile({
    required this.title,
    required this.value,
    required this.leading,
    required this.onTap,
    this.helper,
    this.showDivider = true,
    super.key,
  });

  final String title;
  final String value;
  final String? helper;
  final Widget leading;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);
    final isPlaceholder =
        value == '无' || value == '请选择' || value == '选择空间' || value == '选择类型';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpace.radius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: palette.divider))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: palette.surfaceInset,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: IconTheme(
                  data: IconThemeData(color: palette.textSecondary),
                  child: leading,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isPlaceholder ? palette.textTertiary : palette.textPrimary,
                    ),
                  ),
                  if (helper != null && helper!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      helper!,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: palette.textTertiary),
          ],
        ),
      ),
    );
  }
}
