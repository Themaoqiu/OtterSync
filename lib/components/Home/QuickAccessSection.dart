import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

class QuickAccessSection extends StatelessWidget {
  const QuickAccessSection({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  final List<QuickAccessItem> items;
  final ValueChanged<QuickAccessItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);

    return Column(
      children: [
        for (int i = 0; i < items.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _compactCard(context, palette, items[i])),
              const SizedBox(width: 14),
              if (i + 1 < items.length)
                Expanded(child: _compactCard(context, palette, items[i + 1]))
              else
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _compactCard(
    BuildContext context,
    AppPalette palette,
    QuickAccessItem item,
  ) {
    return InkWell(
      onTap: () => onItemTap(item),
      borderRadius: BorderRadius.circular(AppSpace.radiusLarge),
      child: AppSurface(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _FeatureIcon(
              icon: item.icon,
              color: item.color,
              iconTint: item.iconTint,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: palette.textPrimary,
                      fontSize: 17,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  const _FeatureIcon({required this.icon, required this.color, this.iconTint});

  final IconData icon;
  final Color color;
  final Color? iconTint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 24, color: iconTint ?? const Color(0xFF6B3FA0)),
    );
  }
}
