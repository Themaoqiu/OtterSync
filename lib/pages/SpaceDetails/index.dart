import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/EmptyStateView.dart';
import 'package:ottersync/components/Common/demo_feedback.dart';
import 'package:ottersync/components/SpaceDetails/BacklogTabView.dart';
import 'package:ottersync/components/SpaceDetails/BoardTabView.dart';
import 'package:ottersync/components/SpaceDetails/CalendarTabView.dart';
import 'package:ottersync/components/SpaceDetails/ReportTabView.dart';
import 'package:ottersync/components/SpaceDetails/SettingsTabView.dart';
import 'package:ottersync/components/SpaceDetails/SummaryTabView.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';
import 'package:ottersync/viewmodels/work_item_api.dart';

class SpaceDetailsView extends StatefulWidget {
  const SpaceDetailsView({super.key, this.spaceId, WorkItemApi? api})
    : _api = api;

  final int? spaceId;
  final WorkItemApi? _api;

  @override
  State<SpaceDetailsView> createState() => _SpaceDetailsViewState();
}

class _SpaceDetailsViewState extends State<SpaceDetailsView> {
  late final WorkItemApi _api;
  JiraSpace? _space;
  List<SpaceSummaryMetric> _metrics = const [];
  List<BacklogGroup> _groups = const [];
  List<IssueSummary> _boardItems = const [];
  List<IssueSummary> _calendarItems = const [];
  final List<String> _calendarFilters = const ['状态', '经办人', '优先级', '类型'];
  WorkItemStatus? _statusFilter;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = widget._api ?? WorkItemApi();
    _loadSpaceDetails();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);

    return DefaultTabController(
      length: 6,
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              leading: const BackButton(),
              titleSpacing: 0,
              title: Row(
                children: [
                  Text(
                    _space?.name ?? '空间详情',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: palette.textSecondary,
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: _openStatusFilter,
                  icon: Icon(
                    _statusFilter != null
                        ? Icons.filter_alt
                        : Icons.filter_alt_outlined,
                  ),
                ),
                IconButton(
                  onPressed: () => showDemoFeedback(context, '更多空间操作接口已预留。'),
                  icon: const Icon(Icons.more_vert_rounded),
                ),
              ],
              bottom: TabBar(
                isScrollable: true,
                dividerColor: palette.divider,
                labelColor: palette.primary,
                unselectedLabelColor: palette.textSecondary,
                indicatorColor: palette.primary,
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(text: '摘要'),
                  Tab(text: '面板'),
                  Tab(text: '日历'),
                  Tab(text: '待办事项列表'),
                  Tab(text: '报告'),
                  Tab(text: '设置'),
                ],
              ),
            ),
            body: _buildBody(context),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_space == null) {
      return const EmptyStateView(
        icon: Icons.public_off_outlined,
        title: '还没有这个空间',
        description: '请选择一个真实数据库空间后再查看详情。',
      );
    }

    final filteredGroups = _statusFilter == null
        ? _groups
        : _groups.map((group) {
            final filtered = group.items
                .where((item) => item.statusKey == _statusFilter)
                .toList(growable: false);
            return BacklogGroup(
              title: group.title,
              issueCount: filtered.length,
              todoCount: filtered.where((i) => i.statusKey == WorkItemStatus.todo).length,
              inProgressCount: filtered.where((i) => i.statusKey == WorkItemStatus.inProgress).length,
              doneCount: filtered.where((i) => i.statusKey == WorkItemStatus.done).length,
              items: filtered,
            );
          }).where((g) => g.issueCount > 0).toList(growable: false);

    final filteredBoardItems = _statusFilter == null
        ? _boardItems
        : _boardItems.where((item) => item.statusKey == _statusFilter).toList(growable: false);

    return TabBarView(
      children: [
        SummaryTabView(
          metrics: _metrics,
          onStatusTap: (status) {
            final match = WorkItemStatus.values.where((s) => workItemStatusLabel(s) == status);
            if (match.isNotEmpty) {
              setState(() => _statusFilter = match.first);
            }
          },
        ),
        BoardTabView(
          itemCount: filteredBoardItems.length,
          items: filteredBoardItems,
          onOpenBacklog: () => DefaultTabController.of(context).animateTo(4),
        ),
        CalendarTabView(filters: _calendarFilters, items: _calendarItems),
        if (filteredGroups.isEmpty)
          EmptyStateView(
            icon: Icons.view_list_outlined,
            title: _statusFilter != null ? '没有匹配的工作项' : '还没有待办事项',
            description: _statusFilter != null ? '该状态下没有工作项。' : '当这个空间下有真实数据库任务后，会显示在这里。',
          )
        else
          BacklogTabView(
            groups: filteredGroups,
            onCreate: () => showDemoFeedback(context, '创建待办事项接口已预留。'),
          ),
        ReportTabView(metrics: _metrics),
        SettingsTabView(space: _space!),
      ],
    );
  }

  void _openStatusFilter() {
    final palette = AppThemePalette.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('全部'),
              leading: Icon(Icons.list_rounded, color: palette.primary),
              trailing: _statusFilter == null
                  ? Icon(Icons.check_rounded, color: palette.primary)
                  : null,
              onTap: () {
                setState(() => _statusFilter = null);
                Navigator.pop(ctx);
              },
            ),
            ...WorkItemStatus.values.map(
              (status) => ListTile(
                title: Text(workItemStatusLabel(status)),
                leading: Icon(
                  status == WorkItemStatus.done
                      ? Icons.check_circle_outline_rounded
                      : status == WorkItemStatus.inProgress
                          ? Icons.play_circle_outline_rounded
                          : Icons.circle_outlined,
                  color: palette.primary,
                ),
                trailing: _statusFilter == status
                    ? Icon(Icons.check_rounded, color: palette.primary)
                    : null,
                onTap: () {
                  setState(() => _statusFilter = status);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSpaceDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final spaceId = widget.spaceId;
      if (spaceId == null) {
        final spaces = await _api.listSpaces();
        if (spaces.isEmpty) {
          if (!mounted) {
            return;
          }
          setState(() {
            _space = null;
            _metrics = const [];
            _groups = const [];
            _boardItems = const [];
            _calendarItems = const [];
            _loading = false;
          });
          return;
        }
        _space = spaces.first;
      } else {
        _space = await _api.getWorkspaceById(spaceId);
      }

      if (_space == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _loading = false;
        });
        return;
      }

      final metrics = await _api.loadSpaceSummaryMetrics(_space!.id);
      final groups = await _api.loadBacklogGroups(_space!.id);
      final boardItems = await _api.loadBoardItems(_space!.id);
      final calendarItems = await _api.loadCalendarItems(_space!.id);

      if (!mounted) {
        return;
      }
      setState(() {
        _metrics = metrics;
        _groups = groups;
        _boardItems = boardItems;
        _calendarItems = calendarItems;
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
