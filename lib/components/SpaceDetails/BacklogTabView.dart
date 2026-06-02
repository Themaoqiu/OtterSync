import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/components/Common/UserAvatar.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

class BacklogTabView extends StatefulWidget {
  const BacklogTabView({
    super.key,
    required this.groups,
    required this.onCreate,
    required this.onItemTap,
    required this.onToggleDone,
  });

  final List<BacklogGroup> groups;
  final Future<void> Function(BacklogGroup group, String summary) onCreate;
  final void Function(IssueSummary item) onItemTap;
  final Future<void> Function(IssueSummary item, bool done) onToggleDone;

  @override
  State<BacklogTabView> createState() => _BacklogTabViewState();
}

class _BacklogTabViewState extends State<BacklogTabView> {
  final Set<String> _expandedGroups = <String>{};
  String? _composingGroup;

  @override
  void initState() {
    super.initState();
    _expandedGroups.addAll(widget.groups.map((g) => g.title));
  }

  @override
  void didUpdateWidget(covariant BacklogTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final titles = widget.groups.map((g) => g.title).toSet();
    _expandedGroups.removeWhere((t) => !titles.contains(t));
    for (final t in titles) {
      _expandedGroups.add(t);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpace.pagePaddingWithNav,
      children: widget.groups
          .map(
            (group) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _BacklogGroupCard(
                group: group,
                expanded: _expandedGroups.contains(group.title),
                composing: _composingGroup == group.title,
                onToggle: () => _toggleGroup(group.title),
                onStartCompose: () => setState(() {
                  _composingGroup = group.title;
                  _expandedGroups.add(group.title);
                }),
                onCancelCompose: () =>
                    setState(() => _composingGroup = null),
                onSubmitCompose: (summary) async {
                  setState(() => _composingGroup = null);
                  if (summary.trim().isEmpty) return;
                  await widget.onCreate(group, summary.trim());
                },
                onItemTap: widget.onItemTap,
                onToggleDone: widget.onToggleDone,
              ),
            ),
          )
          .toList(),
    );
  }

  void _toggleGroup(String title) {
    setState(() {
      if (_expandedGroups.contains(title)) {
        _expandedGroups.remove(title);
      } else {
        _expandedGroups.add(title);
      }
    });
  }
}

class _BacklogGroupCard extends StatelessWidget {
  const _BacklogGroupCard({
    required this.group,
    required this.expanded,
    required this.composing,
    required this.onToggle,
    required this.onStartCompose,
    required this.onCancelCompose,
    required this.onSubmitCompose,
    required this.onItemTap,
    required this.onToggleDone,
  });

  final BacklogGroup group;
  final bool expanded;
  final bool composing;
  final VoidCallback onToggle;
  final VoidCallback onStartCompose;
  final VoidCallback onCancelCompose;
  final ValueChanged<String> onSubmitCompose;
  final void Function(IssueSummary item) onItemTap;
  final Future<void> Function(IssueSummary item, bool done) onToggleDone;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: expanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      group.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${group.issueCount} 项',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _CountBadge(
                text: '${group.todoCount}',
                color: palette.textSecondary.withValues(alpha: 0.18),
                fg: palette.textPrimary,
              ),
              const SizedBox(width: 8),
              _CountBadge(
                text: '${group.inProgressCount}',
                color: palette.primarySoft,
                fg: palette.primary,
              ),
              const SizedBox(width: 8),
              _CountBadge(
                text: '${group.doneCount}',
                color: const Color(0xFFCDEBC5),
                fg: const Color(0xFF1F7A1F),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: !expanded
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      ...group.items.map(
                        (item) => _BacklogItemRow(
                          item: item,
                          onTap: () => onItemTap(item),
                          onToggleDone: (done) => onToggleDone(item, done),
                        ),
                      ),
                      if (composing)
                        _InlineComposeRow(
                          onSubmit: onSubmitCompose,
                          onCancel: onCancelCompose,
                        )
                      else
                        InkWell(
                          onTap: onStartCompose,
                          borderRadius:
                              BorderRadius.circular(AppSpace.radius),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Icon(Icons.add_rounded,
                                    color: palette.primary, size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  '创建工作项',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(color: palette.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _BacklogItemRow extends StatelessWidget {
  const _BacklogItemRow({
    required this.item,
    required this.onTap,
    required this.onToggleDone,
  });

  final IssueSummary item;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleDone;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);
    final done = item.statusKey == WorkItemStatus.done;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpace.radius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onToggleDone(!done),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: done ? palette.primary : Colors.transparent,
                  border: Border.all(
                    color: done ? palette.primary : palette.textSecondary,
                    width: 1.6,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: done
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 16)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? palette.textTertiary : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.key} · ${item.status ?? '待办'}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            UserAvatar(
              label: item.assigneeInitials ?? 'MT',
              size: 26,
            ),
            Icon(Icons.chevron_right_rounded, color: palette.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _InlineComposeRow extends StatefulWidget {
  const _InlineComposeRow({
    required this.onSubmit,
    required this.onCancel,
  });

  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;

  @override
  State<_InlineComposeRow> createState() => _InlineComposeRowState();
}

class _InlineComposeRowState extends State<_InlineComposeRow> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              border: Border.all(color: palette.textSecondary, width: 1.6),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: const InputDecoration(
                hintText: '输入新工作项后回车',
                isDense: true,
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (value) {
                if (value.trim().isEmpty) {
                  widget.onCancel();
                } else {
                  widget.onSubmit(value);
                }
              },
              onEditingComplete: () {
                final v = _controller.text;
                if (v.trim().isEmpty) {
                  widget.onCancel();
                } else {
                  widget.onSubmit(v);
                }
              },
            ),
          ),
          IconButton(
            onPressed: widget.onCancel,
            icon: Icon(Icons.close_rounded, color: palette.textSecondary),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.text,
    required this.color,
    required this.fg,
  });

  final String text;
  final Color color;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 26,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
