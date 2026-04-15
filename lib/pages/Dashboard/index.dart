import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/components/Common/UserAvatar.dart';
import 'package:ottersync/components/Common/demo_feedback.dart';
import 'package:ottersync/components/Dashboard/AssignedIssuesCard.dart';
import 'package:ottersync/components/Dashboard/DashboardActivityCard.dart';
import 'package:ottersync/components/Dashboard/DashboardFeedbackCard.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_demo_data.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

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
          ],
        ),
        const SizedBox(height: 24),
        Text('仪表板', style: theme.textTheme.headlineLarge),
        const SizedBox(height: 24),
        AppSurface(
          padding: const EdgeInsets.all(0),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpace.radiusLarge),
            onTap: () => showDemoFeedback(context, '仪表板切换接口已预留。'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '默认仪表板',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: palette.surfaceInset,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: palette.textSecondary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        AssignedIssuesCard(
          issues: JiraDemoData.assignedIssues,
          onIssueTap: (item) => showDemoFeedback(context, '将打开 ${item.key}。'),
        ),
        const SizedBox(height: 24),
        DashboardActivityCard(
          activities: JiraDemoData.dashboardActivities,
          onActivityTap: (item) =>
              showDemoFeedback(context, '将打开 ${item.issue} 的活动详情。'),
        ),
        const SizedBox(height: 24),
        DashboardFeedbackCard(
          onTap: () => showDemoFeedback(context, '反馈提交接口已预留。'),
        ),
      ],
    );
  }
}
