import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/components/Common/EmptyStateView.dart';
import 'package:ottersync/components/Common/SectionHeader.dart';
import 'package:ottersync/components/Common/UserAvatar.dart';
import 'package:ottersync/components/Spaces/CreateSpaceDialog.dart';
import 'package:ottersync/components/Spaces/SpaceCard.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';
import 'package:ottersync/viewmodels/work_item_api.dart';
import 'package:ottersync/viewmodels/work_item_models.dart';

class SpacesView extends StatefulWidget {
  const SpacesView({super.key, WorkItemApi? api}) : _api = api;

  final WorkItemApi? _api;

  @override
  State<SpacesView> createState() => _SpacesViewState();
}

class _SpacesViewState extends State<SpacesView> {
  late final WorkItemApi _api;
  List<JiraSpace> _spaces = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = widget._api ?? WorkItemApi();
    _loadSpaces();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: palette.scaffold,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: AppSpace.pagePadding,
              child: Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => context.push('/account'),
                        borderRadius: BorderRadius.circular(999),
                        child: const UserAvatar(label: 'MT'),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => context.push('/search?scope=spaces'),
                        icon: Icon(
                          Icons.search_rounded,
                          color: palette.textSecondary,
                          size: 30,
                        ),
                        tooltip: '搜索',
                      ),
                      IconButton(
                        onPressed: _openCreateSpaceDialog,
                        icon: Icon(
                          Icons.add_rounded,
                          color: palette.primary,
                          size: 30,
                        ),
                        tooltip: '创建空间',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('空间', style: theme.textTheme.headlineMedium),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 112),
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
                  const SizedBox(height: 24),
                  AppSurface(
                    color: palette.surfaceInset,
                    border: Border.all(color: Colors.transparent),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: palette.textSecondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '这里展示的空间全部来自 Firestore，创建后会立即出现在列表中。',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: palette.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
      return [
        _buildErrorCard(context, title: '空间加载失败'),
      ];
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
