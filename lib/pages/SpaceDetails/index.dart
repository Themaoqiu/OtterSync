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
  int _boardItemCount = 0;
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
                  onPressed: () => showDemoFeedback(context, '空间筛选接口已预留。'),
                  icon: const Icon(Icons.filter_alt_outlined),
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

    return TabBarView(
      children: [
        SummaryTabView(
          metrics: _metrics,
          onStatusTap: (status) => showDemoFeedback(context, '将按$status筛选工作项。'),
        ),
        BoardTabView(
          itemCount: _boardItemCount,
          items: _boardItems,
          onOpenBacklog: () => DefaultTabController.of(context).animateTo(4),
        ),
        CalendarTabView(filters: _calendarFilters, items: _calendarItems),
        if (_groups.isEmpty)
          const EmptyStateView(
            icon: Icons.view_list_outlined,
            title: '还没有待办事项',
            description: '当这个空间下有真实数据库任务后，会显示在这里。',
          )
        else
          BacklogTabView(
            groups: _groups,
            onCreate: () => showDemoFeedback(context, '创建待办事项接口已预留。'),
          ),
        ReportTabView(metrics: _metrics),
        SettingsTabView(space: _space!),
      ],
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
            _boardItemCount = 0;
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
      final boardCount = await _api.loadBoardItemCount(_space!.id);
      final boardItems = await _api.loadBoardItems(_space!.id);
      final calendarItems = await _api.loadCalendarItems(_space!.id);

      if (!mounted) {
        return;
      }
      setState(() {
        _metrics = metrics;
        _groups = groups;
        _boardItemCount = boardCount;
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
