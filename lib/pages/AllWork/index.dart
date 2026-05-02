import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/components/AllWork/AllWorkToolbar.dart';
import 'package:ottersync/components/AllWork/FilterSheet.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/components/Common/IssueListTile.dart';
import 'package:ottersync/components/Common/UserAvatar.dart';
import 'package:ottersync/components/Common/demo_feedback.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_demo_data.dart';
import 'package:ottersync/viewmodels/jira_models.dart';
import 'package:ottersync/viewmodels/work_item_api.dart';
import 'package:ottersync/viewmodels/work_item_models.dart';

class AllWorkView extends StatefulWidget {
  const AllWorkView({super.key});

  @override
  State<AllWorkView> createState() => _AllWorkViewState();
}

class _AllWorkViewState extends State<AllWorkView> {
  final WorkItemApi _api = WorkItemApi();
  FilterItem _selectedFilter = JiraDemoData.filters.first;
  AllWorkViewMode _viewMode = AllWorkViewMode.list;
  List<LookupOption> _workItems = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWorkItems();
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
            const SizedBox(width: 16),
            Expanded(
              child: Text('所有工作', style: theme.textTheme.headlineMedium),
            ),
            IconButton(
              onPressed: () => showDemoFeedback(context, '搜索工作项接口已预留。'),
              icon: Icon(
                Icons.search_rounded,
                color: palette.textSecondary,
                size: 30,
              ),
              tooltip: '搜索',
            ),
            IconButton(
              onPressed: _openCreatePage,
              icon: Icon(
                Icons.add_rounded,
                color: palette.primary,
                size: 30,
              ),
              tooltip: '创建工作项',
            ),
          ],
        ),
        const SizedBox(height: 24),
        AllWorkToolbar(
          selectedFilter: _selectedFilter,
          viewMode: _viewMode,
          onFilterTap: _openFilterSheet,
          onViewModeChanged: (mode) => setState(() => _viewMode = mode),
        ),
        const SizedBox(height: 32),
        Text('待办', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('加载失败', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(_error!, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: _loadWorkItems,
                  child: const Text('重试'),
                ),
              ],
            ),
          )
        else if (_workItems.isEmpty)
          AppSurface(
            child: Text(
              '还没有工作项，点击右上角 + 创建。',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else
          _viewMode == AllWorkViewMode.list
              ? Column(
                  children: _workItems
                      .map(
                        (item) => IssueListTile(
                          title: item.title,
                          subtitle: item.subtitle ?? 'ID-${item.id}',
                          status: 'TODO',
                        ),
                      )
                      .toList(),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _workItems.length,
                  itemBuilder: (context, index) {
                    final item = _workItems[index];
                    return AppSurface(
                      padding: const EdgeInsets.all(0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          AppSpace.radiusLarge,
                        ),
                        onTap: () =>
                            showDemoFeedback(context, '将打开 ${item.title}。'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: palette.primarySoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.check_box_outline_blank_rounded,
                                  color: palette.primary,
                                  size: 28,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                item.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.subtitle ?? 'ID-${item.id}',
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
                ),
      ],
    );
  }

  Future<void> _openFilterSheet() async {
    final filter = await showModalBottomSheet<FilterItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterSheet(
        recentFilter: _selectedFilter,
        filters: JiraDemoData.filters,
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
      final items = await _api.listWorkItems();
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
