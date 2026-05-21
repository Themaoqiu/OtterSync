import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/EmptyStateView.dart';
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
                  onPressed: _openMoreActions,
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
            onCreate: _createBacklogItem,
          ),
        ReportTabView(metrics: _metrics),
        SettingsTabView(space: _space!),
      ],
    );
  }

  void _openMoreActions() {
    final palette = AppThemePalette.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit_outlined, color: palette.textPrimary),
              title: const Text('编辑空间名称'),
              onTap: () {
                Navigator.pop(ctx);
                _editSpaceName();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: palette.danger),
              title: Text(
                '删除空间',
                style: TextStyle(color: palette.danger),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteSpace();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editSpaceName() async {
    if (_space == null) return;
    final controller = TextEditingController(text: _space!.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑空间名称'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '空间名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty || !mounted) return;
    try {
      await _api.updateWorkspace(_space!.id, name: result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('空间名称已更新')),
      );
      await _loadSpaceDetails();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新失败：$e')),
      );
    }
  }

  Future<void> _confirmDeleteSpace() async {
    if (_space == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除空间'),
        content: Text('确定要删除「${_space!.name}」吗？该空间下的所有工作项将被一并删除，此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              '删除',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _api.deleteWorkspace(_space!.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('空间已删除')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败：$e')),
      );
    }
  }

  Future<void> _createBacklogItem() async {
    if (_space == null) return;
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('创建待办事项'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '摘要'),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty || !mounted) return;
    try {
      await _api.createBacklogItem(
        workspaceId: _space!.id,
        summary: result,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('待办事项已创建')),
      );
      await _loadSpaceDetails();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建失败：$e')),
      );
    }
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
