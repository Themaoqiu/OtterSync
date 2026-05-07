import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/components/Common/EmptyStateView.dart';
import 'package:ottersync/components/Common/UserAvatar.dart';
import 'package:ottersync/components/Common/demo_feedback.dart';
import 'package:ottersync/components/Dashboard/AssignedIssuesCard.dart';
import 'package:ottersync/components/Dashboard/DashboardActivityCard.dart';
import 'package:ottersync/components/Dashboard/DashboardFeedbackCard.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';
import 'package:ottersync/viewmodels/work_item_api.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key, WorkItemApi? api}) : _api = api;

  final WorkItemApi? _api;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late final WorkItemApi _api;
  List<IssueSummary> _issues = const [];
  List<DashboardActivityItem> _activities = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = widget._api ?? WorkItemApi();
    _loadDashboardData();
  }

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
        Text('仪表板', style: theme.textTheme.headlineMedium),
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
                    child: Text('默认仪表板', style: theme.textTheme.titleLarge),
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
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          AppSurface(child: Text(_error!, style: theme.textTheme.bodyMedium))
        else if (_issues.isEmpty && _activities.isEmpty)
          const SizedBox(
            height: 480,
            child: EmptyStateView(
              icon: Icons.dashboard_outlined,
              title: '还没有仪表板数据',
              description: '当数据库里有真实任务活动后，这里会展示分配给我和活动流。',
            ),
          )
        else ...[
          if (_issues.isNotEmpty)
            AssignedIssuesCard(
              issues: _issues,
              onIssueTap: (item) => showDemoFeedback(context, '将打开 ${item.key}。'),
            ),
          if (_issues.isNotEmpty) const SizedBox(height: 24),
          if (_activities.isNotEmpty)
            DashboardActivityCard(
              activities: _activities,
              onActivityTap: (item) =>
                  showDemoFeedback(context, '将打开 ${item.issue} 的活动详情。'),
            ),
        ],
        const SizedBox(height: 24),
        DashboardFeedbackCard(
          onTap: () => showDemoFeedback(context, '反馈提交接口已预留。'),
        ),
      ],
    );
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final issues = await _api.loadAssignedIssues();
      final activities = await _api.loadDashboardActivities();
      if (!mounted) {
        return;
      }
      setState(() {
        _issues = issues;
        _activities = activities;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }
}
