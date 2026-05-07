import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

class SpaceCard extends StatelessWidget {
  const SpaceCard({super.key, required this.space, required this.onTap});

  final JiraSpace space;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AppSurface(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        radius: 14,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: space.avatar.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                space.avatar.icon,
                color: space.avatar.iconColor,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(space.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(space.key, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            Icon(
              Icons.star_border_rounded,
              color: palette.textSecondary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
