import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/components/Common/UserAvatar.dart';
import 'package:ottersync/theme/design_tokens.dart';

class AccountProfileCard extends StatelessWidget {
  const AccountProfileCard({super.key, required this.onAddSite});

  final VoidCallback onAddSite;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);

    return AppSurface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const UserAvatar(label: 'MT', size: 60),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('maoqiu The', style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'themaoqiu@gmail.com',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  children: [
                    Text(
                      'Themaoqiu',
                      style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
                    ),
                    InkWell(
                      onTap: onAddSite,
                      child: Text(
                        '添加网站',
                        style: TextStyle(color: palette.primary, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
