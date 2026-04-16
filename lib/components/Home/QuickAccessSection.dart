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
    final wideItem = items.first;
    final compactItems = items.skip(1).toList();

    return Column(
      children: [
        InkWell(
          onTap: () => onItemTap(wideItem),
          child: AppSurface(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                _FeatureIcon(icon: wideItem.icon, color: wideItem.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wideItem.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        wideItem.subtitle,
                        style: const TextStyle(
                          color: Color(0xFF8E4BC3),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (wideItem.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: wideItem.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      wideItem.badge!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 2.55,
          ),
          itemCount: compactItems.length,
          itemBuilder: (context, index) {
            final item = compactItems[index];
            return InkWell(
              onTap: () => onItemTap(item),
              borderRadius: BorderRadius.circular(AppSpace.radiusLarge),
              child: AppSurface(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    _FeatureIcon(icon: item.icon, color: item.color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  const _FeatureIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 24, color: const Color(0xFF6B3FA0)),
    );
  }
}
