import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/components/Common/UserAvatar.dart';
import 'package:ottersync/theme/design_tokens.dart';

class AccountProfileCard extends StatelessWidget {
  const AccountProfileCard({
    super.key,
    required this.onAddSite,
    required this.displayName,
    required this.email,
  });

  final VoidCallback onAddSite;
  final String displayName;
  final String email;

  String _avatarLabel(String name) {
    if (name.isEmpty) return '?';
    final chars = name.trim().toUpperCase();
    if (chars.length >= 2) return chars.substring(0, 2);
    return chars;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);

    return AppSurface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(label: _avatarLabel(displayName), size: 60),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  email,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: onAddSite,
                  child: Text(
                    '添加网站',
                    style: TextStyle(color: palette.primary, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
