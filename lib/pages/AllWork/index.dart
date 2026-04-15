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

class AllWorkView extends StatefulWidget {
  const AllWorkView({super.key});

  @override
  State<AllWorkView> createState() => _AllWorkViewState();
}

class _AllWorkViewState extends State<AllWorkView> {
  FilterItem _selectedFilter = JiraDemoData.filters.first;
  AllWorkViewMode _viewMode = AllWorkViewMode.list;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);
    final issues = JiraDemoData.recentProjects.take(2).toList();

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
            Expanded(child: Text('所有工作', style: theme.textTheme.headlineLarge)),
            Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: palette.surface,
                shape: BoxShape.circle,
                boxShadow: AppShadows.cardSoft,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => showDemoFeedback(context, '搜索工作项接口已预留。'),
                icon: Icon(
                  Icons.search_rounded,
                  color: palette.textSecondary,
                  size: 26,
                ),
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
        AllWorkToolbar(
          selectedFilter: _selectedFilter,
          viewMode: _viewMode,
          onFilterTap: _openFilterSheet,
          onViewModeChanged: (mode) => setState(() => _viewMode = mode),
        ),
        const SizedBox(height: 32),
        Text('待办', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 16),
        _viewMode == AllWorkViewMode.list
            ? Column(
                children: issues
                    .map(
                      (item) => IssueListTile(
                        title: item.title,
                        subtitle: item.key,
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
                itemCount: issues.length,
                itemBuilder: (context, index) {
                  final item = issues[index];
                  return AppSurface(
                    padding: const EdgeInsets.all(0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppSpace.radiusLarge),
                      onTap: () =>
                          showDemoFeedback(context, '将打开 ${item.key}。'),
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
                              item.key,
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
}
