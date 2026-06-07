import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/components/Common/EmptyStateView.dart';
import 'package:ottersync/components/Common/PageHeader.dart';
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

    return Column(
      children: [
        const PageHeader(title: '通知'),
        Expanded(
          child: PageFadeSlide(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 112),
              children: [
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
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: palette.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.notifications_active_outlined,
                        color: palette.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (item.workItemId != null) {
                            context.push('/work-item/${item.workItemId}');
                          }
                        },
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
              ],
            ),
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
