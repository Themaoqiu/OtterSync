import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/components/Common/EmptyStateView.dart';
import 'package:ottersync/components/Common/SectionHeader.dart';
import 'package:ottersync/components/Common/UserAvatar.dart';
import 'package:ottersync/components/Common/demo_feedback.dart';
import 'package:ottersync/components/Home/HomeActivitySwitcher.dart';
import 'package:ottersync/components/Home/HomeAiCreateCard.dart';
import 'package:ottersync/components/Home/HomeOverviewCard.dart';
import 'package:ottersync/components/Home/QuickAccessSection.dart';
import 'package:ottersync/components/Home/RecentProjectsCard.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';
import 'package:ottersync/viewmodels/work_item_api.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, WorkItemApi? api}) : _api = api;

  final WorkItemApi? _api;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final WorkItemApi _api;
  bool _overviewExpanded = true;
  bool _quickAccessExpanded = true;
  bool _loading = true;
  String? _error;
  HomeActivityMode _activityMode = HomeActivityMode.viewed;
  List<QuickAccessItem> _quickAccessItems = const [];
  List<IssueSummary> _viewedItems = const [];
  List<IssueSummary> _dynamicItems = const [];

  @override
  void initState() {
    super.initState();
    _api = widget._api ?? WorkItemApi();
    _loadHomeData();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => context.push('/account'),
                    borderRadius: BorderRadius.circular(999),
                    child: const UserAvatar(label: 'MT'),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: SizedBox.shrink(),
                  ),
                  IconButton(
                    onPressed: () => context.push('/create-work-item'),
                    icon: Icon(
                      Icons.add_rounded,
                      color: palette.primary,
                      size: 30,
                    ),
                    tooltip: '创建工作项目',
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 112),
            children: [
                  SectionHeader(
                    title: '今日概述',
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
                        Builder(
                          builder: (context) {
                            final overviewDesc = '使用人工智能。验证结果。';
                            return HomeOverviewCard(
                              title: _dynamicItems.isEmpty
                                  ? 'No recent work activities found in the last 4 days.'
                                  : '${_dynamicItems.length} recent work activities found in the last 4 days.',
                              description: overviewDesc,
                              onCopy: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: overviewDesc),
                                );
                                if (context.mounted) {
                                  showDemoFeedback(context, '已复制到剪贴板');
                                }
                              },
                              onLike: () =>
                                  showDemoFeedback(context, '反馈提交接口已预留。'),
                              onDislike: () =>
                                  showDemoFeedback(context, '反馈提交接口已预留。'),
                              onMore: () => setState(() {
                                _overviewExpanded = !_overviewExpanded;
                              }),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_error != null)
                          _buildErrorState()
                        else if (_quickAccessItems.isEmpty)
                          const SizedBox(
                            height: 380,
                            child: EmptyStateView(
                              icon: Icons.bolt_outlined,
                              title: '还没有快速访问内容',
                              description: '创建真实空间或任务后，这里会自动生成快捷入口。',
                            ),
                          )
                        else
                          Column(
                            children: [
                              HomeAiCreateCard(
                                onTap: () => showDemoFeedback(context, 'AI 创建工作项入口已恢复，上传图像流程待接入。'),
                              ),
                              const SizedBox(height: 14),
                              QuickAccessSection(
                                items: _buildQuickAccessItems(),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  HomeActivitySwitcher(
                    mode: _activityMode,
                    onModeChanged: (mode) => setState(() => _activityMode = mode),
                  ),
                  if (_activityMode == HomeActivityMode.viewed) ...[
                    const SizedBox(height: 18),
                    Text(
                      '今天',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      _buildErrorState()
                    else if (_viewedItems.isEmpty)
                      const SizedBox(
                        height: 220,
                        child: EmptyStateView(
                          icon: Icons.history_outlined,
                          title: '还没有已查看工作项',
                          description: '查看真实工作项后，这里会显示最近查看记录。',
                        ),
                      )
                    else
                      RecentProjectsCard(
                        items: _buildViewedDisplayItems().take(2).toList(growable: false),
                        onItemTap: (item) {
                          if (item.id != null) {
                            context.push('/work-item/${item.id}');
                          }
                        },
                      ),
                    const SizedBox(height: 18),
                    Text(
                      '四月',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_viewedItems.length > 2)
                      RecentProjectsCard(
                        items: _buildViewedDisplayItems().skip(2).take(4).toList(growable: false),
                        onItemTap: (item) {
                          if (item.id != null) {
                            context.push('/work-item/${item.id}');
                          }
                        },
                      ),
                  ] else ...[
                    const SizedBox(height: 18),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      _buildErrorState()
                    else if (_dynamicItems.isEmpty)
                      const SizedBox(
                        height: 220,
                        child: EmptyStateView(
                          icon: Icons.bolt_outlined,
                          title: '最近两三天还没有新动态',
                          description: '当最近创建了新的真实工作项后，这里会显示工作动态。',
                        ),
                      )
                    else
                      RecentProjectsCard(
                        items: _dynamicItems,
                        onItemTap: (item) {
                          if (item.id != null) {
                            context.push('/work-item/${item.id}');
                          }
                        },
                      ),
                  ],
                ],
              ),
            ),
          ],
        );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        _error ?? '',
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final quickAccess = await _api.loadHomeQuickAccess();
      final viewedItems = await _api.loadViewedItems();
      final dynamicItems = await _api.loadRecentDynamicItems();
      if (!mounted) {
        return;
      }
      setState(() {
        _quickAccessItems = quickAccess;
        _viewedItems = viewedItems;
        _dynamicItems = dynamicItems;
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

  List<QuickAccessItem> _buildQuickAccessItems() {
    final items = <QuickAccessItem>[
      ..._quickAccessItems,
      const QuickAccessItem(
        title: '我的工作',
        subtitle: '筛选器',
        icon: Icons.filter_alt_outlined,
        color: Color(0xFFD8E7FF),
        iconTint: Color(0xFF0C66E4),
        route: '/all-work',
      ),
    ];

    if (items.length <= 1) {
      return items;
    }

    final wideItem = items.first;
    final compactItems = items.skip(1).toList(growable: true);
    compactItems.sort((left, right) {
      if (left.title == '我的工作') {
        return -1;
      }
      if (right.title == '我的工作') {
        return 1;
      }
      return 0;
    });
    return [wideItem, ...compactItems];
  }

  List<IssueSummary> _buildViewedDisplayItems() {
    final items = <IssueSummary>[
      const IssueSummary(
        title: '我的打开事务',
        key: 'FILTER',
        subtitle: '筛选器 · 已查看',
        icon: Icons.filter_alt_outlined,
        iconBackgroundColor: Color(0xFFD8E7FF),
        iconColor: Color(0xFF0C66E4),
      ),
      ..._viewedItems.map(
        (item) => IssueSummary(
          id: item.id,
          title: item.title,
          key: item.key,
          subtitle: item.subtitle == null
              ? '已查看'
              : '${item.subtitle} · 已查看',
          status: item.status,
          assigneeInitials: item.assigneeInitials,
          icon: item.icon,
          iconBackgroundColor: item.iconBackgroundColor,
          iconColor: item.iconColor,
          statusKey: item.statusKey,
          bucket: item.bucket,
          workspaceId: item.workspaceId,
          startDate: item.startDate,
          dueDate: item.dueDate,
        ),
      ),
    ];
    return items;
  }
}

class _HomeSectionBody extends StatelessWidget {
  const _HomeSectionBody({required this.expanded, required this.child});

  final bool expanded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 400),
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
