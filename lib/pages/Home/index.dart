import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/components/Common/SectionHeader.dart';
import 'package:ottersync/components/Common/UserAvatar.dart';
import 'package:ottersync/components/Common/demo_feedback.dart';
import 'package:ottersync/components/Home/HomeOverviewCard.dart';
import 'package:ottersync/components/Home/QuickAccessSection.dart';
import 'package:ottersync/components/Home/RecentProjectsCard.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_demo_data.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

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
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '早上好!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Themaoqiu',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
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
                onPressed: () => showDemoFeedback(context, '创建工作项接口已预留。'),
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
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: palette.shadow.withValues(alpha: isDark ? 0.0 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.search_rounded,
                color: palette.textSecondary,
                size: 24,
              ),
              hintText: '搜索工作区、事务名称...',
              fillColor: palette.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpace.radiusXLarge),
                borderSide: BorderSide(
                  color: isDark ? palette.border : Colors.transparent,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpace.radiusXLarge),
                borderSide: BorderSide(
                  color: isDark ? palette.border : Colors.transparent,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpace.radiusXLarge),
                borderSide: BorderSide(color: palette.primary, width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        SectionHeader(
          title: '今日概述',
          action: Icon(
            Icons.more_horiz_rounded,
            color: palette.textSecondary,
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        HomeOverviewCard(
          onCopy: () => showDemoFeedback(context, '摘要内容复制接口已预留。'),
          onLike: () => showDemoFeedback(context, '反馈提交接口已预留。'),
          onDislike: () => showDemoFeedback(context, '反馈提交接口已预留。'),
          onMore: () => showDemoFeedback(context, '更多动态接口已预留。'),
        ),
        const SizedBox(height: 32),
        SectionHeader(
          title: '快速访问',
          action: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                '编辑',
                style: TextStyle(
                  color: palette.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        QuickAccessSection(
          items: JiraDemoData.homeQuickAccess,
          onItemTap: (item) {
            // Ripple added automatically inside item component
            if (item.route != null) {
              context.push(item.route!);
              return;
            }
            showDemoFeedback(context, '${item.title} 交互入口已预留。');
          },
        ),
        const SizedBox(height: 32),
        SectionHeader(
          title: '最近项目',
          action: Icon(
            Icons.more_horiz_rounded,
            color: palette.textSecondary,
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '今天',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: palette.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        RecentProjectsCard(
          items: JiraDemoData.recentProjects,
          onItemTap: (item) =>
              showDemoFeedback(context, '将打开 ${item.key} 的详情页。'),
        ),
      ],
    );
  }
}
