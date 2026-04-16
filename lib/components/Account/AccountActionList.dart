import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/theme/design_tokens.dart';

class AccountActionItem {
  const AccountActionItem({required this.title, required this.icon});

  final String title;
  final IconData icon;
}

class AccountActionList extends StatelessWidget {
  const AccountActionList({
    super.key,
    required this.items,
    required this.onTap,
  });

  final List<AccountActionItem> items;
  final ValueChanged<AccountActionItem> onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);

    return AppSurface(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: items
            .asMap()
            .entries
            .map(
              (entry) => Column(
                children: [
                  ListTile(
                    onTap: () => onTap(entry.value),
                    minLeadingWidth: 26,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    leading: Icon(
                      entry.value.icon,
                      color: palette.textSecondary,
                      size: 34,
                    ),
                    title: Text(
                      entry.value.title,
                      style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18),
                    ),
                  ),
                  if (entry.key != items.length - 1)
                    Divider(
                      height: 1,
                      color: palette.divider,
                      indent: 72,
                      endIndent: 16,
                    ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
