import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/components/AllWork/AllWorkToolbar.dart';
import 'package:ottersync/components/AllWork/FilterSheet.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/components/Common/EmptyStateView.dart';
import 'package:ottersync/components/Common/IssueListTile.dart';
import 'package:ottersync/components/Common/PageHeader.dart';
import 'package:ottersync/components/Common/demo_feedback.dart';
import 'package:ottersync/services/app_event_bus.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';
import 'package:ottersync/services/work_item_service.dart';

const _filters = [
  FilterItem(title: '所有工作项', icon: Icons.inventory_2_outlined),
  FilterItem(title: '未处理工作项', icon: Icons.sync_problem_outlined),
  FilterItem(title: '进行中', icon: Icons.timelapse_outlined),
  FilterItem(title: '已完成的工作项', icon: Icons.check_circle_outline_rounded),
  FilterItem(title: '即将到期', icon: Icons.event_outlined),
  FilterItem(title: '最近创建', icon: Icons.add_card_outlined),
];

class AllWorkView extends StatefulWidget {
  const AllWorkView({super.key});

  @override
  State<AllWorkView> createState() => _AllWorkViewState();
}

class _AllWorkViewState extends State<AllWorkView> {
  final WorkItemService _api = WorkItemService();
  FilterItem _selectedFilter = _filters.first;
  AllWorkViewMode _viewMode = AllWorkViewMode.list;
  List<IssueSummary> _workItems = const [];
  bool _loading = true;
  String? _error;
  StreamSubscription<AppEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    _loadWorkItems();
    _eventSub = AppEventBus.instance.on(
      {AppEventType.workItemCreated, AppEventType.workItemUpdated},
      (event) {
        if (mounted) {
          _loadWorkItems();
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
    final theme = Theme.of(context);

    return Column(
      children: [
        PageHeader(
          title: '所有工作',
          actions: [
            HeaderIconButton(
              icon: Icons.search_rounded,
              tooltip: '搜索',
              onPressed: () => context.push('/search?scope=workItems'),
            ),
            HeaderIconButton(
              icon: Icons.add_rounded,
              emphasized: true,
              tooltip: '创建工作项',
              onPressed: _openCreatePage,
            ),
          ],
        ),
        Expanded(
          child: PageFadeSlide(
            child: RefreshIndicator(
              onRefresh: _loadWorkItems,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 112),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  AllWorkToolbar(
                    selectedFilter: _selectedFilter,
                    viewMode: _viewMode,
                    onFilterTap: _openFilterSheet,
                    onViewModeChanged: (mode) =>
                        setState(() => _viewMode = mode),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _selectedFilter.title,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildContent(theme),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return AppSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('加载失败', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 14),
            FilledButton(onPressed: _loadWorkItems, child: const Text('重试')),
          ],
        ),
      );
    }
    final items = _filteredItems;
    if (items.isEmpty) {
      return const SizedBox(
        height: 420,
        child: EmptyStateView(
          icon: Icons.inbox_outlined,
          title: '没有符合条件的工作项',
          description: '换个筛选器，或点击右上角 + 创建工作项。',
        ),
      );
    }
    return _viewMode == AllWorkViewMode.list
        ? _buildList(items)
        : _buildGrid(theme, items);
  }

  Widget _buildList(List<IssueSummary> items) {
    return Column(
      children: items
          .map(
            (item) => IssueListTile(
              title: item.title,
              subtitle: item.key.isEmpty ? 'ID-${item.id}' : item.key,
              status: _statusLabel(item.statusKey),
              done: item.statusKey == WorkItemStatus.done,
              onToggleDone: (value) => _toggleDone(item, value),
              onTap: () => _openItem(item),
            ),
          )
          .toList(),
    );
  }

  Widget _buildGrid(ThemeData theme, List<IssueSummary> items) {
    final palette = AppThemePalette.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final done = item.statusKey == WorkItemStatus.done;
        return AppSurface(
          padding: const EdgeInsets.all(0),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpace.radiusLarge),
            onTap: () => _openItem(item),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GridCheckbox(
                    done: done,
                    onTap: () => _toggleDone(item, !done),
                  ),
                  const Spacer(),
                  Text(
                    item.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      height: 1.3,
                      color: done ? palette.textSecondary : null,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.key.isEmpty ? 'ID-${item.id}' : item.key,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<IssueSummary> get _filteredItems {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_selectedFilter.title) {
      case '未处理工作项':
        return _workItems
            .where((item) => item.statusKey == WorkItemStatus.todo)
            .toList();
      case '进行中':
        return _workItems
            .where((item) => item.statusKey == WorkItemStatus.inProgress)
            .toList();
      case '已完成的工作项':
        return _workItems
            .where((item) => item.statusKey == WorkItemStatus.done)
            .toList();
      case '即将到期':
        return _workItems.where((item) {
          if (item.statusKey == WorkItemStatus.done || item.dueDate == null) {
            return false;
          }
          final dueDay = DateTime(
            item.dueDate!.year,
            item.dueDate!.month,
            item.dueDate!.day,
          );
          final diff = dueDay.difference(today).inDays;
          return diff >= 0 && diff <= 3;
        }).toList();
      case '最近创建':
        return _workItems.where((item) {
          final created = item.createdAt;
          return created != null && now.difference(created).inDays <= 7;
        }).toList();
      default:
        return _workItems;
    }
  }

  String _statusLabel(WorkItemStatus status) {
    switch (status) {
      case WorkItemStatus.done:
        return 'DONE';
      case WorkItemStatus.inProgress:
        return 'IN PROGRESS';
      case WorkItemStatus.todo:
        return 'TODO';
    }
  }

  void _openItem(IssueSummary item) {
    if (item.id == null) return;
    context.push('/work-item/${item.id}', extra: item);
  }

  Future<void> _toggleDone(IssueSummary item, bool done) async {
    if (item.id == null) return;
    final newStatus = done ? WorkItemStatus.done : WorkItemStatus.todo;
    final previous = _workItems;
    setState(() {
      _workItems = _workItems
          .map(
            (i) => i.id == item.id
                ? i.copyWith(
                    statusKey: newStatus,
                    status: workItemStatusLabel(newStatus),
                  )
                : i,
          )
          .toList(growable: false);
    });
    try {
      await _api.updateWorkItemStatus(item.id!, newStatus);
    } catch (error) {
      if (!mounted) return;
      setState(() => _workItems = previous);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('更新失败：$error')));
    }
  }

  Future<void> _openFilterSheet() async {
    final filter = await showModalBottomSheet<FilterItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterSheet(
        recentFilter: _selectedFilter,
        filters: _filters,
        onCreate: () => showDemoFeedback(context, '创建筛选器接口已预留。'),
      ),
    );
    if (filter != null) {
      setState(() => _selectedFilter = filter);
    }
  }

  Future<void> _openCreatePage() async {
    await context.push('/create-work-item');
    if (!mounted) {
      return;
    }
    await _loadWorkItems();
  }

  Future<void> _loadWorkItems() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.listWorkItemSummaries();
      if (!mounted) {
        return;
      }
      setState(() {
        _workItems = items;
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

class _GridCheckbox extends StatelessWidget {
  const _GridCheckbox({required this.done, required this.onTap});

  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: done ? palette.primary : palette.primarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          splashColor: (done ? Colors.white : palette.primary).withValues(
            alpha: 0.22,
          ),
          highlightColor: (done ? Colors.white : palette.primary).withValues(
            alpha: 0.1,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
                child: child,
              ),
              child: Icon(
                done
                    ? Icons.check_rounded
                    : Icons.check_box_outline_blank_rounded,
                key: ValueKey(done),
                color: done ? Colors.white : palette.primary,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
