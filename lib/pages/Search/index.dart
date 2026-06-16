import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/components/Common/EmptyStateView.dart';
import 'package:ottersync/components/Common/IssueListTile.dart';
import 'package:ottersync/components/Spaces/SpaceCard.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';
import 'package:ottersync/services/work_item_service.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key, this.scope = 'workItems'});

  final String scope;

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _api = WorkItemService();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  bool _loading = false;
  List<IssueSummary> _workItemResults = const [];
  List<JiraSpace> _spaceResults = const [];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _workItemResults = const [];
        _spaceResults = const [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(query));
  }

  Future<void> _search(String query) async {
    try {
      if (widget.scope == 'spaces') {
        final results = await _api.searchSpaces(query);
        if (!mounted) return;
        setState(() {
          _spaceResults = results;
          _workItemResults = const [];
          _loading = false;
        });
      } else {
        final results = await _api.searchWorkItems(query);
        if (!mounted) return;
        setState(() {
          _workItemResults = results;
          _spaceResults = const [];
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onQueryChanged,
          decoration: InputDecoration(
            hintText: widget.scope == 'spaces' ? '搜索空间...' : '搜索工作项...',
            border: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
          style: theme.textTheme.bodyLarge,
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('取消', style: TextStyle(color: palette.primary)),
          ),
        ],
      ),
      body: _buildBody(theme, palette),
    );
  }

  Widget _buildBody(ThemeData theme, AppPalette palette) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final query = _controller.text.trim();
    if (query.isEmpty) {
      return const Center(
        child: EmptyStateView(
          icon: Icons.search_rounded,
          title: '输入关键词开始搜索',
          description: '支持按标题、关键字、描述搜索。',
        ),
      );
    }

    if (widget.scope == 'spaces') {
      if (_spaceResults.isEmpty) {
        return const Center(
          child: EmptyStateView(
            icon: Icons.search_off_rounded,
            title: '没有找到匹配的空间',
            description: '尝试其他关键词。',
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
        itemCount: _spaceResults.length,
        itemBuilder: (context, index) {
          final space = _spaceResults[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SpaceCard(
              space: space,
              onTap: () => context.push('/space-details/${space.id}'),
            ),
          );
        },
      );
    }

    if (_workItemResults.isEmpty) {
      return const Center(
        child: EmptyStateView(
          icon: Icons.search_off_rounded,
          title: '没有找到匹配的工作项',
          description: '尝试其他关键词。',
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
      itemCount: _workItemResults.length,
      itemBuilder: (context, index) {
        final item = _workItemResults[index];
        return IssueListTile(
          title: item.title,
          subtitle: item.key,
          status: item.status,
          onTap: () {
            if (item.id != null) {
              context.push('/work-item/${item.id}');
            }
          },
        );
      },
    );
  }
}
