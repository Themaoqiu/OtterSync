import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/components/Common/EmptyStateView.dart';
import 'package:ottersync/components/Common/PageHeader.dart';
import 'package:ottersync/components/Notifications/NotificationListTile.dart';
import 'package:ottersync/components/Notifications/WorkspaceInvitesSection.dart';
import 'package:ottersync/viewmodels/jira_models.dart';
import 'package:ottersync/viewmodels/work_item_api.dart';
import 'package:ottersync/viewmodels/work_item_models.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key, WorkItemApi? api}) : _api = api;

  final WorkItemApi? _api;

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  late final WorkItemApi _api;
  late final Stream<List<NotificationItem>> _notificationStream;
  List<WorkspaceInvite> _invites = const [];
  bool _loadingInvites = true;
  String? _processingInviteId;

  @override
  void initState() {
    super.initState();
    _api = widget._api ?? WorkItemApi();
    _notificationStream = _api.watchNotifications();
    _loadInvites();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const PageHeader(title: '通知'),
        Expanded(
          child: PageFadeSlide(
            child: StreamBuilder<List<NotificationItem>>(
              stream: _notificationStream,
              builder: (context, snapshot) {
                final notifications = snapshot.data ?? const <NotificationItem>[];
                final waiting =
                    snapshot.connectionState == ConnectionState.waiting;

                return RefreshIndicator(
                  onRefresh: _loadInvites,
                  child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 112),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    if (snapshot.hasError)
                      AppSurface(
                        child: Text('${snapshot.error}',
                            style: theme.textTheme.bodyMedium),
                      )
                    else if (waiting && _loadingInvites)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (notifications.isEmpty && _invites.isEmpty)
                      const SizedBox(
                        height: 560,
                        child: EmptyStateView(
                          icon: Icons.notifications_none_rounded,
                          title: '还没有通知',
                          description: '任务活动和工作空间邀请会显示在这里。',
                        ),
                      )
                    else ...[
                      WorkspaceInvitesSection(
                        invites: _invites,
                        processingInviteId: _processingInviteId,
                        onAccept: _acceptInvite,
                        onDecline: _declineInvite,
                      ),
                      ...notifications.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: NotificationListTile(
                            item: item,
                            onTap: item.workItemId == null
                                ? null
                                : () =>
                                    context.push('/work-item/${item.workItemId}'),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadInvites() async {
    try {
      final invites = await _api.listPendingWorkspaceInvites();
      if (!mounted) {
        return;
      }
      setState(() {
        _invites = invites;
        _loadingInvites = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _loadingInvites = false);
    }
  }

  Future<void> _acceptInvite(WorkspaceInvite invite) async {
    setState(() => _processingInviteId = invite.id);
    try {
      await _api.acceptWorkspaceInvite(invite.id);
      if (!mounted) return;
      setState(() {
        _invites = _invites.where((item) => item.id != invite.id).toList();
        _processingInviteId = null;
      });
      context.push('/space-details/${invite.workspaceId}');
    } catch (error) {
      if (!mounted) return;
      setState(() => _processingInviteId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  Future<void> _declineInvite(WorkspaceInvite invite) async {
    setState(() => _processingInviteId = invite.id);
    try {
      await _api.declineWorkspaceInvite(invite.id);
      if (!mounted) return;
      setState(() {
        _invites = _invites.where((item) => item.id != invite.id).toList();
        _processingInviteId = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _processingInviteId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }
}
