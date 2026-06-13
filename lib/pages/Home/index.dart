import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/components/Common/EmptyStateView.dart';
import 'package:ottersync/components/Common/PageHeader.dart';
import 'package:ottersync/components/Common/SectionHeader.dart';
import 'package:ottersync/components/Common/demo_feedback.dart';
import 'package:ottersync/components/Home/HomeActivitySwitcher.dart';
import 'package:ottersync/components/Home/HomeAiCreateCard.dart';
import 'package:ottersync/components/Home/HomeOverviewCard.dart';
import 'package:ottersync/components/Home/QuickAccessSection.dart';
import 'package:ottersync/components/Home/RecentProjectsCard.dart';
import 'package:ottersync/services/app_event_bus.dart';
import 'package:ottersync/state/shell_scope.dart';
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
  bool _isLiked = false;
  bool _isDisliked = false;
  StreamSubscription<AppEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    _api = widget._api ?? WorkItemApi();
    _loadHomeData();
    _eventSub = AppEventBus.instance.on({
      AppEventType.workItemCreated,
      AppEventType.workItemUpdated,
    }, (event) {
      if (mounted) {
        _loadHomeData();
      }
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        PageHeader(
          actions: [
            HeaderIconButton(
              icon: Icons.add_rounded,
              emphasized: true,
              tooltip: '创建工作项目',
              onPressed: () => context.push('/create-work-item'),
            ),
          ],
        ),
        Expanded(
          child: PageFadeSlide(
            child: RefreshIndicator(
              onRefresh: _loadHomeData,
              child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 112),
            physics: const AlwaysScrollableScrollPhysics(),
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
                              isLiked: _isLiked,
                              isDisliked: _isDisliked,
                              onCopy: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: overviewDesc),
                                );
                                if (context.mounted) {
                                  showDemoFeedback(context, '已复制到剪贴板');
                                }
                              },
                              onLike: () => _submitFeedback('like'),
                              onDislike: () => _submitFeedback('dislike'),
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
                        if (_error != null)
                          _buildErrorState()
                        else
                          Column(
                            children: [
                              HomeAiCreateCard(
                                onTap: () => context.push('/ai-chat'),
                              ),
                              const SizedBox(height: 14),
                              QuickAccessSection(
                                items: _buildQuickAccessItems(),
                                onItemTap: (item) {
                                  if (item.route != null) {
                                    navigateOrSwitchTab(context, item.route!);
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
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      _buildErrorState()
                    else if (_viewedItems.isEmpty)
                      const SizedBox(
                        height: 360,
                        child: EmptyStateView(
                          icon: Icons.history_outlined,
                          title: '还没有已查看工作项',
                          description: '查看真实工作项后，这里会显示最近查看记录。',
                        ),
                      )
                    else
                      ..._buildViewedSections(theme, palette),
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
                        height: 360,
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
                            context.push('/work-item/${item.id}', extra: item);
                          }
                        },
                      ),
                  ],
                ],
              ),
            ),
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
      final feedbackStatus = await _api.getFeedbackStatus(
        targetType: 'overview',
        targetId: 'daily',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _quickAccessItems = quickAccess;
        _viewedItems = viewedItems;
        _dynamicItems = dynamicItems;
        _isLiked = feedbackStatus == 'like';
        _isDisliked = feedbackStatus == 'dislike';
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

  Future<void> _submitFeedback(String type) async {
    try {
      await _api.submitFeedback(
        targetType: 'overview',
        targetId: 'daily',
        type: type,
      );
      if (!mounted) return;
      final status = await _api.getFeedbackStatus(
        targetType: 'overview',
        targetId: 'daily',
      );
      if (!mounted) return;
      setState(() {
        _isLiked = status == 'like';
        _isDisliked = status == 'dislike';
      });
    } catch (e) {
      if (!mounted) return;
      showDemoFeedback(context, '反馈提交失败：$e');
    }
  }

  List<QuickAccessItem> _buildQuickAccessItems() {
    return <QuickAccessItem>[
      const QuickAccessItem(
        title: '我的待处理工作项',
        subtitle: '筛选器',
        icon: Icons.inbox_rounded,
        color: Color(0xFFD8E7FF),
        iconTint: Color(0xFF0C66E4),
        route: '/all-work',
      ),
      ..._quickAccessItems,
    ];
  }

  List<Widget> _buildViewedSections(ThemeData theme, AppPalette palette) {
    const filter = IssueSummary(
      title: '我的待处理工作项',
      key: 'FILTER',
      subtitle: '筛选器 · 已查看',
      icon: Icons.inbox_rounded,
      iconBackgroundColor: Color(0xFFD8E7FF),
      iconColor: Color(0xFF0C66E4),
    );

    DateTime? viewedTime(IssueSummary i) => i.lastViewedAt ?? i.createdAt;

    final sorted = [..._viewedItems]..sort((a, b) {
        final ta = viewedTime(a);
        final tb = viewedTime(b);
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta);
      });

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    final groups = <String, List<IssueSummary>>{};
    final order = <String>[];
    void put(String label, IssueSummary item) {
      if (!groups.containsKey(label)) {
        groups[label] = [];
        order.add(label);
      }
      groups[label]!.add(item);
    }

    String monthLabel(DateTime d) {
      const names = [
        '一月', '二月', '三月', '四月', '五月', '六月',
        '七月', '八月', '九月', '十月', '十一月', '十二月',
      ];
      final m = names[d.month - 1];
      return d.year == now.year ? m : '${d.year} 年 $m';
    }

    for (final item in sorted) {
      final t = viewedTime(item);
      if (t == null) {
        put('更早', item);
        continue;
      }
      final day = DateTime(t.year, t.month, t.day);
      if (day == today) {
        put('今天', item);
      } else if (day == today.subtract(const Duration(days: 1))) {
        put('昨天', item);
      } else if (!day.isBefore(weekStart)) {
        put('本周', item);
      } else {
        put(monthLabel(t), item);
      }
    }

    final widgets = <Widget>[];
    void appendCard(List<IssueSummary> items) {
      final mapped = items
          .map(
            (item) => item.copyWith(
              subtitle: item.subtitle == null
                  ? '已查看'
                  : '${item.subtitle} · 已查看',
            ),
          )
          .toList(growable: false);
      widgets.add(
        RecentProjectsCard(
          items: mapped,
          onItemTap: (item) {
            if (item.id != null) {
              context.push('/work-item/${item.id}', extra: item);
            }
          },
        ),
      );
    }

    bool firstSection = true;
    for (final label in order) {
      if (!firstSection) widgets.add(const SizedBox(height: 18));
      firstSection = false;
      widgets.add(Text(
        label,
        style: theme.textTheme.titleMedium?.copyWith(color: palette.textPrimary),
      ));
      widgets.add(const SizedBox(height: 10));
      if (label == order.first) {
        appendCard([filter, ...groups[label]!]);
      } else {
        appendCard(groups[label]!);
      }
    }

    return widgets;
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
