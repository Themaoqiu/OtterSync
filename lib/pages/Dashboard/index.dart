import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/components/Common/EmptyStateView.dart';
import 'package:ottersync/components/Common/PageHeader.dart';
import 'package:ottersync/components/Dashboard/AssignedIssuesCard.dart';
import 'package:ottersync/components/Dashboard/DashboardActivityCard.dart';
import 'package:ottersync/components/Dashboard/StatsGrid.dart';
import 'package:ottersync/services/app_event_bus.dart';
import 'package:ottersync/services/dashboard_stats_service.dart';
import 'package:ottersync/state/auth_controller.dart';
import 'package:ottersync/viewmodels/jira_models.dart';
import 'package:ottersync/services/work_item_service.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key, WorkItemService? api}) : _api = api;

  final WorkItemService? _api;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late final WorkItemService _api;
  List<IssueSummary> _issues = const [];
  List<DashboardActivityItem> _activities = const [];
  List<IssueSummary> _allItems = const [];
  bool _loading = true;
  String? _error;
  DateTime? _lastSyncedAt;
  List<DashboardStat> _stats = const [];
  StreamSubscription<AppEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    _api = widget._api ?? WorkItemService();
    _loadDashboardData();
    _eventSub = AppEventBus.instance.on(
      {AppEventType.workItemCreated, AppEventType.workItemUpdated},
      (_) {
        if (mounted) {
          _loadDashboardData();
        }
      },
    );
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PageHeader(title: '仪表板'),
        Expanded(
          child: PageFadeSlide(
            child: RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: _buildBody(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 80),
        children: const [Center(child: CircularProgressIndicator())],
      );
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 112),
        children: [
          EmptyStateView(
            icon: Icons.cloud_off_rounded,
            title: '加载失败',
            description: _error!,
          ),
        ],
      );
    }
    if (_issues.isEmpty && _activities.isEmpty && _allItems.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 112),
        children: const [
          SizedBox(
            height: 480,
            child: EmptyStateView(
              icon: Icons.dashboard_outlined,
              title: '还没有仪表板数据',
              description: '当数据库里有真实任务活动后，这里会展示概览与活动流。',
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 112),
      children: [
        StatsGrid(stats: _stats),
        const SizedBox(height: 16),
        AssignedIssuesCard(
          issues: _issues,
          onIssueTap: (item) {
            if (item.id != null) {
              context.push('/work-item/${item.id}', extra: item);
            }
          },
          lastSyncedLabel: _relativeLabel(_lastSyncedAt),
          onRefresh: _loadDashboardData,
        ),
        const SizedBox(height: 16),
        DashboardActivityCard(
          activities: _activities,
          userInitials: _userInitials(),
          onActivityTap: (item) {
            final id = _activityWorkItemId(item);
            if (id != null) {
              context.push('/work-item/$id');
            }
          },
        ),
      ],
    );
  }

  List<DashboardStat> _statsFrom(DashboardStatsResult result) {
    return [
      DashboardStat(
        label: '分配给我',
        value: result.assigned,
        icon: Icons.assignment_ind_rounded,
        color: const Color(0xFF1F5DBD),
      ),
      DashboardStat(
        label: '进行中',
        value: result.inProgress,
        icon: Icons.timelapse_rounded,
        color: const Color(0xFF8E4BC3),
      ),
      DashboardStat(
        label: '即将到期',
        value: result.dueSoon,
        icon: Icons.event_rounded,
        color: const Color(0xFFE56910),
      ),
      DashboardStat(
        label: '本周已完成',
        value: result.completedThisWeek,
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF1F8B4C),
      ),
    ];
  }

  int? _activityWorkItemId(DashboardActivityItem item) {
    final match = _allItems.firstWhere(
      (e) => e.key == item.issue,
      orElse: () => const IssueSummary(title: '', key: ''),
    );
    return match.id;
  }

  String _userInitials() {
    final auth = AuthScope.of(context);
    final name = auth.displayName.isEmpty ? 'MT' : auth.displayName;
    final initials = name.characters.take(2).toString().toUpperCase();
    return initials.isEmpty ? 'MT' : initials;
  }

  String _relativeLabel(DateTime? value) {
    if (value == null) return '点击刷新';
    final diff = DateTime.now().difference(value);
    if (diff.inSeconds < 30) return '刚刚同步';
    if (diff.inMinutes < 1) return '${diff.inSeconds} 秒前';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
    if (diff.inDays < 1) return '${diff.inHours} 小时前';
    return '${diff.inDays} 天前';
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _loading = _lastSyncedAt == null;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.loadAssignedIssues(),
        _api.loadDashboardActivities(),
        _api.listWorkItemSummaries(),
      ]);
      if (!mounted) return;
      final issues = results[0] as List<IssueSummary>;
      final allItems = results[2] as List<IssueSummary>;
      final statsResult = await const DashboardStatsService().computeStats(
        assignedCount: issues.length,
        allItems: allItems,
      );
      if (!mounted) return;
      setState(() {
        _issues = issues;
        _activities = results[1] as List<DashboardActivityItem>;
        _allItems = allItems;
        _stats = _statsFrom(statsResult);
        _loading = false;
        _lastSyncedAt = DateTime.now();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }
}
