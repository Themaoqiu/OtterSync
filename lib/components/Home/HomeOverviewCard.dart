import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/theme/design_tokens.dart';

class HomeOverviewCard extends StatelessWidget {
  const HomeOverviewCard({
    super.key,
    required this.title,
    required this.description,
    required this.onCopy,
    required this.onLike,
    required this.onDislike,
    required this.onMore,
  });

  final String title;
  final String description;
  final VoidCallback onCopy;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);

    return AppSurface(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              height: 1.3,
              fontSize: 18,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: palette.textPrimary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.surfaceInset,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Beta',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.info_outline_rounded,
                color: palette.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '使用人工智能。验证结果。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onCopy,
                    icon: Icon(
                      Icons.content_copy_outlined,
                      color: palette.textPrimary,
                    ),
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  IconButton(
                    onPressed: onLike,
                    icon: Icon(
                      Icons.thumb_up_alt_outlined,
                      color: palette.textPrimary,
                    ),
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  IconButton(
                    onPressed: onDislike,
                    icon: Icon(
                      Icons.thumb_down_alt_outlined,
                      color: palette.textPrimary,
                    ),
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
