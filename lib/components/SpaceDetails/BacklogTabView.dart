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
  });

  final List<BacklogGroup> groups;
  final VoidCallback onCreate;

  @override
  State<BacklogTabView> createState() => _BacklogTabViewState();
}

class _BacklogTabViewState extends State<BacklogTabView> {
  late final Set<String> _expandedGroups;

  @override
  void initState() {
    super.initState();
    _expandedGroups = widget.groups.map((group) => group.title).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpace.pagePaddingWithNav,
      children: widget.groups
          .map(
            (group) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _BacklogGroupCard(
                group: group,
                expanded: _expandedGroups.contains(group.title),
                onToggle: () => _toggleGroup(group.title),
                onCreate: widget.onCreate,
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
    required this.onToggle,
    required this.onCreate,
  });

  final BacklogGroup group;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Row(
              children: [
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: palette.textPrimary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    group.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(Icons.more_vert_rounded, color: palette.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${group.issueCount} 个工作项',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 18),
              _CountBadge(
                text: '${group.todoCount}',
                color: palette.textSecondary.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 8),
              _CountBadge(
                text: '${group.inProgressCount}',
                color: palette.primarySoft,
              ),
              const SizedBox(width: 8),
              _CountBadge(
                text: '${group.doneCount}',
                color: const Color(0xFF5B7F2A),
              ),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: 24),
            ...group.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 6),
                        const SizedBox(
                          width: 40,
                          child: Icon(Icons.check_box_outline_blank_rounded),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 18),
                              Text(
                                item.key,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.drag_handle_rounded,
                          color: palette.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const SizedBox(width: 60),
                        Expanded(
                          child: Text(
                            item.status ?? '待办',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        Text('-', style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(width: 10),
                        UserAvatar(
                          label: item.assigneeInitials ?? 'MT',
                          size: 28,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Divider(color: palette.divider),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.add_rounded, color: palette.primary, size: 34),
                const SizedBox(width: 10),
                InkWell(
                  onTap: onCreate,
                  child: Text(
                    '创建',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: palette.primary,
                        ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.attach_file_rounded,
                  color: palette.primary,
                  size: 34,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(text),
    );
  }
}
