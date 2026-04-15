import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/components/Common/SectionHeader.dart';
import 'package:ottersync/components/Common/UserAvatar.dart';
import 'package:ottersync/components/Common/demo_feedback.dart';
import 'package:ottersync/components/Spaces/SpaceCard.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_demo_data.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

class SpacesView extends StatelessWidget {
  const SpacesView({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: AppSpace.pagePaddingWithNav,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => context.push('/account'),
              borderRadius: BorderRadius.circular(999),
              child: const UserAvatar(label: 'MT'),
            ),
            const Spacer(),
            Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: palette.surface,
                shape: BoxShape.circle,
                border: isDark ? Border.all(color: palette.border) : null,
                boxShadow: isDark ? null : AppShadows.cardSoft,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => showDemoFeedback(context, '搜索空间接口已预留。'),
                icon: Icon(
                  Icons.search_rounded,
                  color: palette.textSecondary,
                  size: 26,
                ),
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: palette.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => showDemoFeedback(context, '创建空间接口已预留。'),
                icon: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('空间', style: theme.textTheme.headlineLarge),
        const SizedBox(height: 32),
        const SectionHeader(
          title: '最近查看',
          action: Icon(Icons.more_horiz_rounded),
        ),
        const SizedBox(height: 16),
        SpaceCard(
          space: const JiraSpace(name: 'ottersync', key: 'OS'),
          onTap: () => context.push('/space-details'),
        ),
        const SizedBox(height: 36),
        const SectionHeader(
          title: '所有空间',
          action: Icon(Icons.more_horiz_rounded),
        ),
        const SizedBox(height: 16),
        ...JiraDemoData.spaces.map(
          (space) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SpaceCard(
              space: space,
              onTap: () => context.push('/space-details'),
            ),
          ),
        ),
        const SizedBox(height: 24),
        AppSurface(
          color: palette.surfaceInset,
          border: Border.all(color: Colors.transparent),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: palette.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '空间页在两种主题下都保持相同布局，只切换颜色层级和高级对比度。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
