import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/components/Common/work_type_icon.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

class AssignedIssuesCard extends StatelessWidget {
  const AssignedIssuesCard({
    super.key,
    required this.issues,
    required this.onIssueTap,
    required this.lastSyncedLabel,
    required this.onRefresh,
  });

  final List<IssueSummary> issues;
  final ValueChanged<IssueSummary> onIssueTap;
  final String lastSyncedLabel;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('分配给我', style: theme.textTheme.titleMedium),
              ),
              Text(
                '${issues.length} 项',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: palette.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (issues.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  '当前没有分配给你的工作项',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: palette.textSecondary),
                ),
              ),
            )
          else
            ...issues.asMap().entries.map(
                  (entry) => Column(
                    children: [
                      InkWell(
                        onTap: () => onIssueTap(entry.value),
                        borderRadius: BorderRadius.circular(AppSpace.radius),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              WorkTypeIconBadge(
                                title: entry.value.workTypeTitle,
                                size: 30,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.value.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${entry.value.key} · ${entry.value.status ?? '待办'}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded,
                                  color: palette.textSecondary, size: 20),
                            ],
                          ),
                        ),
                      ),
                      if (entry.key != issues.length - 1)
                        Divider(
                            height: 1, color: palette.divider, indent: 42),
                    ],
                  ),
                ),
          const SizedBox(height: 8),
          _RefreshFooter(
            label: lastSyncedLabel,
            onTap: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _RefreshFooter extends StatefulWidget {
  const _RefreshFooter({required this.label, required this.onTap});

  final String label;
  final Future<void> Function() onTap;

  @override
  State<_RefreshFooter> createState() => _RefreshFooterState();
}

class _RefreshFooterState extends State<_RefreshFooter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _handle() async {
    if (_busy) return;
    setState(() => _busy = true);
    _ctl.repeat();
    try {
      await widget.onTap();
    } finally {
      _ctl.stop();
      _ctl.reset();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        onTap: _handle,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotationTransition(
                turns: _ctl,
                child: Icon(Icons.sync_rounded,
                    color: palette.primary, size: 18),
              ),
              const SizedBox(width: 6),
              Text(
                _busy ? '正在刷新…' : widget.label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: palette.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
