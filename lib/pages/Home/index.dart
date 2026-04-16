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

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _overviewExpanded = true;
  bool _quickAccessExpanded = true;
  bool _recentProjectsExpanded = true;

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
                  Text('早上好!', style: theme.textTheme.bodyMedium),
                  Text('Themaoqiu', style: theme.textTheme.titleMedium),
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
        const SizedBox(height: 24),
        SectionHeader(
          title: '今日概述',
          action: Icon(
            Icons.more_horiz_rounded,
            color: palette.textSecondary,
            size: 28,
          ),
          expanded: _overviewExpanded,
          onToggle: () => setState(() {
            _overviewExpanded = !_overviewExpanded;
          }),
        ),
        _HomeSectionBody(
          expanded: _overviewExpanded,
          child: Column(
            children: [
              const SizedBox(height: 12),
              HomeOverviewCard(
                onCopy: () => showDemoFeedback(context, '摘要内容复制接口已预留。'),
                onLike: () => showDemoFeedback(context, '反馈提交接口已预留。'),
                onDislike: () => showDemoFeedback(context, '反馈提交接口已预留。'),
                onMore: () => showDemoFeedback(context, '更多动态接口已预留。'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SectionHeader(
          title: '快速访问',
          action: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                '编辑',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: palette.primary,
                ),
              ),
            ),
          ),
          expanded: _quickAccessExpanded,
          onToggle: () => setState(() {
            _quickAccessExpanded = !_quickAccessExpanded;
          }),
        ),
        _HomeSectionBody(
          expanded: _quickAccessExpanded,
          child: Column(
            children: [
              const SizedBox(height: 16),
              QuickAccessSection(
                items: JiraDemoData.homeQuickAccess,
                onItemTap: (item) {
                  if (item.route != null) {
                    context.push(item.route!);
                    return;
                  }
                  showDemoFeedback(context, '${item.title} 交互入口已预留。');
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SectionHeader(
          title: '最近项目',
          action: Icon(
            Icons.more_horiz_rounded,
            color: palette.textSecondary,
            size: 24,
          ),
          expanded: _recentProjectsExpanded,
          onToggle: () => setState(() {
            _recentProjectsExpanded = !_recentProjectsExpanded;
          }),
        ),
        _HomeSectionBody(
          expanded: _recentProjectsExpanded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                '今天',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              RecentProjectsCard(
                items: JiraDemoData.recentProjects,
                onItemTap: (item) =>
                    showDemoFeedback(context, '将打开 ${item.key} 的详情页。'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeSectionBody extends StatelessWidget {
  const _HomeSectionBody({required this.expanded, required this.child});

  final bool expanded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (child, animation) {
        final sizeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        );

        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: sizeAnimation,
            axisAlignment: -1,
            child: child,
          ),
        );
      },
      child: expanded
          ? KeyedSubtree(key: const ValueKey('expanded'), child: child)
          : const SizedBox.shrink(key: ValueKey('collapsed')),
    );
  }
}
