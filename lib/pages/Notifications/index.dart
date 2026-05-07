import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/components/Common/EmptyStateView.dart';
import 'package:ottersync/components/Common/UserAvatar.dart';
import 'package:ottersync/components/Common/demo_feedback.dart';
import 'package:ottersync/state/theme_controller.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';
import 'package:ottersync/viewmodels/work_item_api.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key, WorkItemApi? api}) : _api = api;

  final WorkItemApi? _api;

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  late final WorkItemApi _api;
  List<NotificationItem> _notifications = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = widget._api ?? WorkItemApi();
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);
    final themeController = ThemeControllerScope.of(context);

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
            Expanded(child: Text('通知', style: theme.textTheme.headlineMedium)),
            Switch(
              value: themeController.isDarkMode,
              onChanged: (_) => themeController.toggle(),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          AppSurface(child: Text(_error!, style: theme.textTheme.bodyMedium))
        else if (_notifications.isEmpty)
          const SizedBox(
            height: 560,
            child: EmptyStateView(
              icon: Icons.notifications_none_rounded,
              title: '还没有通知',
              description: '当数据库里有真实任务活动后，这里会显示最新通知。',
            ),
          )
        else
          ..._notifications.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: AppSurface(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: palette.primarySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.notifications_active_outlined,
                        color: palette.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            showDemoFeedback(context, '${item.title} 已保留详情入口。'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: theme.textTheme.titleMedium),
                            const SizedBox(height: 6),
                            Text(
                              item.description,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        AppSurface(
          color: palette.surfaceInset,
          child: Text(
            themeController.isDarkMode
                ? '当前为深色模式。切换开关后，所有页面会同步切换到浅色模式。'
                : '当前为浅色模式。切换开关后，所有页面会同步切换到深色模式。',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notifications = await _api.loadNotifications();
      if (!mounted) {
        return;
      }
      setState(() {
        _notifications = notifications;
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
