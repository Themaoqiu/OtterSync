import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

class FilterSheet extends StatelessWidget {
  const FilterSheet({
    super.key,
    required this.recentFilter,
    required this.filters,
    required this.onCreate,
  });

  final FilterItem recentFilter;
  final List<FilterItem> filters;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: AppSpace.pagePadding,
        children: [
          Row(
            children: [
              const BackButton(),
              const SizedBox(width: 6),
              Text('筛选器', style: theme.textTheme.titleLarge),
              const Spacer(),
              TextButton(onPressed: onCreate, child: const Text('创建')),
            ],
          ),
          const SizedBox(height: 18),
          Text('最近的筛选器', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          _FilterTile(filter: recentFilter, selected: true),
          const SizedBox(height: 16),
          Text('默认筛选器', style: theme.textTheme.titleMedium),
          const SizedBox(height: 14),
          AppSurface(
            padding: const EdgeInsets.all(0),
            child: Column(
              children: filters
                  .asMap()
                  .entries
                  .map(
                    (entry) => Column(
                      children: [
                        _FilterTile(
                          filter: entry.value,
                          onTap: () => Navigator.of(context).pop(entry.value),
                        ),
                        if (entry.key != filters.length - 1)
                          Divider(
                            height: 1,
                            color: palette.divider,
                            indent: 78,
                            endIndent: 16,
                          ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  const _FilterTile({required this.filter, this.selected = false, this.onTap});

  final FilterItem filter;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: palette.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(filter.icon, color: palette.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(filter.title, style: theme.textTheme.bodyLarge)),
          Icon(
            Icons.star_border_rounded,
            color: palette.textSecondary,
            size: 22,
          ),
        ],
      ),
    );

    if (selected) {
      return AppSurface(child: content);
    }

    return InkWell(onTap: onTap, child: content);
  }
}
