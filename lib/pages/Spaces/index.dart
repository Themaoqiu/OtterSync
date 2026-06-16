import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/components/Common/EmptyStateView.dart';
import 'package:ottersync/components/Common/PageHeader.dart';
import 'package:ottersync/components/Common/SectionHeader.dart';
import 'package:ottersync/components/Spaces/CreateSpaceDialog.dart';
import 'package:ottersync/components/Spaces/SpaceCard.dart';
import 'package:ottersync/services/app_event_bus.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';
import 'package:ottersync/services/work_item_service.dart';
import 'package:ottersync/viewmodels/work_item_models.dart';

class SpacesView extends StatefulWidget {
  const SpacesView({super.key, WorkItemService? api}) : _api = api;

  final WorkItemService? _api;

  @override
  State<SpacesView> createState() => _SpacesViewState();
}

class _SpacesViewState extends State<SpacesView> {
  late final WorkItemService _api;
  List<JiraSpace> _spaces = const [];
  bool _loading = true;
  String? _error;
  StreamSubscription<AppEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    _api = widget._api ?? WorkItemService();
    _loadSpaces();
    _eventSub = AppEventBus.instance.on(
      {
        AppEventType.workItemCreated,
        AppEventType.workspaceCreated,
        AppEventType.workspaceMembershipChanged,
      },
      (event) {
        if (mounted) {
          _loadSpaces();
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
    final palette = AppThemePalette.of(context);

    return Scaffold(
      backgroundColor: palette.scaffold,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
              title: '空间',
              actions: [
                HeaderIconButton(
                  icon: Icons.search_rounded,
                  tooltip: '搜索',
                  onPressed: () => context.push('/search?scope=spaces'),
                ),
                HeaderIconButton(
                  icon: Icons.add_rounded,
                  emphasized: true,
                  tooltip: '创建空间',
                  onPressed: _openCreateSpaceDialog,
                ),
              ],
            ),
            Expanded(
              child: PageFadeSlide(
                child: RefreshIndicator(
                  onRefresh: _loadSpaces,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 112),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 8),
                      const SectionHeader(
                        title: '最近查看',
                        action: Icon(Icons.more_horiz_rounded),
                      ),
                      const SizedBox(height: 16),
                      ..._buildRecentSection(context),
                      const SizedBox(height: 36),
                      const SectionHeader(
                        title: '所有空间',
                        action: Icon(Icons.more_horiz_rounded),
                      ),
                      const SizedBox(height: 16),
                      ..._buildAllSpacesSection(context),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecentSection(BuildContext context) {
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_error != null) {
      return [_buildErrorCard(context, title: '空间加载失败')];
    }

    if (_spaces.isEmpty) {
      return const [
        SizedBox(
          height: 420,
          child: EmptyStateView(
            icon: Icons.public_outlined,
            title: '还没有空间',
            description: '创建一个真实数据库空间后，这里会显示所有空间列表。',
          ),
        ),
      ];
    }

    return [
      SpaceCard(
        space: _spaces.first,
        onTap: () => context.push('/space-details/${_spaces.first.id}'),
      ),
    ];
  }

  List<Widget> _buildAllSpacesSection(BuildContext context) {
    if (_loading || _error != null || _spaces.isEmpty) {
      return const [];
    }

    return _spaces
        .map(
          (space) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SpaceCard(
              space: space,
              onTap: () => context.push('/space-details/${space.id}'),
            ),
          ),
        )
        .toList(growable: false);
  }

  Widget _buildErrorCard(BuildContext context, {required String title}) {
    final theme = Theme.of(context);
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_error!, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 14),
          FilledButton(onPressed: _loadSpaces, child: const Text('重试')),
        ],
      ),
    );
  }

  Future<void> _loadSpaces() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final spaces = await _api.listSpaces();
      if (!mounted) {
        return;
      }
      setState(() {
        _spaces = spaces;
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

  Future<void> _openCreateSpaceDialog() async {
    final result = await showModalBottomSheet<WorkspaceCreateDialogResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const CreateSpaceDialog(),
    );
    if (result == null) {
      return;
    }

    try {
      await _api.createWorkspace(
        WorkspaceCreateRequest(
          name: result.name,
          key: result.key,
          template: result.template,
        ),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('空间已创建')));
      await _loadSpaces();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}
