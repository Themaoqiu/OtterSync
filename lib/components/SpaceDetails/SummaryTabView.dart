import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

class SummaryTabView extends StatelessWidget {
  const SummaryTabView({
    super.key,
    required this.metrics,
    required this.statusCounts,
    required this.priorityCounts,
    required this.onMetricTap,
    required this.onStatusTap,
    required this.onPriorityTap,
  });

  final List<SpaceSummaryMetric> metrics;
  final Map<WorkItemStatus, int> statusCounts;
  final Map<String, int> priorityCounts;
  final void Function(int index) onMetricTap;
  final ValueChanged<WorkItemStatus> onStatusTap;
  final ValueChanged<String> onPriorityTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpace.pagePaddingWithNav,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.16,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, index) {
            final item = metrics[index];
            return InkWell(
              onTap: () => onMetricTap(index),
              borderRadius: BorderRadius.circular(AppSpace.radiusLarge),
              child: AppSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: Colors.white, size: 28),
                    ),
                    const Spacer(),
                    Text(
                      item.headline,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${item.value} ${item.emphasis}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        AppSurface(
          child: _StatusOverview(
            statusCounts: statusCounts,
            onStatusTap: onStatusTap,
          ),
        ),
        const SizedBox(height: 18),
        AppSurface(
          child: _PriorityBreakdown(
            priorityCounts: priorityCounts,
            onPriorityTap: onPriorityTap,
          ),
        ),
      ],
    );
  }
}

class _StatusOverview extends StatelessWidget {
  const _StatusOverview({
    required this.statusCounts,
    required this.onStatusTap,
  });

  final Map<WorkItemStatus, int> statusCounts;
  final ValueChanged<WorkItemStatus> onStatusTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final todo = statusCounts[WorkItemStatus.todo] ?? 0;
    final inProgress = statusCounts[WorkItemStatus.inProgress] ?? 0;
    final done = statusCounts[WorkItemStatus.done] ?? 0;
    final total = todo + inProgress + done;
    final items = <(WorkItemStatus, String, Color, int)>[
      (WorkItemStatus.todo, '待办', const Color(0xFFCFD6E4), todo),
      (WorkItemStatus.inProgress, '正在进行', const Color(0xFF7FB0FF), inProgress),
      (WorkItemStatus.done, '已完成', const Color(0xFF6EE7B7), done),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('状态概述', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text('当前空间所有工作项', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 18),
        SizedBox(
          height: 220,
          child: _DonutChart(
            todo: todo,
            inProgress: inProgress,
            done: done,
            total: total,
          ),
        ),
        const SizedBox(height: 14),
        ...items.map(
          (item) => InkWell(
            onTap: () => onStatusTap(item.$1),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: item.$3,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Text(
                    '${item.$4}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: palette.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({
    required this.todo,
    required this.inProgress,
    required this.done,
    required this.total,
  });

  final int todo;
  final int inProgress;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    return CustomPaint(
      painter: _DonutPainter(
        todo: todo,
        inProgress: inProgress,
        done: done,
        total: total,
        emptyColor: palette.divider,
        centerColor: palette.surface,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$total',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text('工作项总数', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.todo,
    required this.inProgress,
    required this.done,
    required this.total,
    required this.emptyColor,
    required this.centerColor,
  });

  final int todo;
  final int inProgress;
  final int done;
  final int total;
  final Color emptyColor;
  final Color centerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 8;

    if (total == 0) {
      final ring = Paint()
        ..color = emptyColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30;
      canvas.drawCircle(center, radius, ring);
      return;
    }

    final segments = <(int, Color)>[
      (todo, const Color(0xFFCFD6E4)),
      (inProgress, const Color(0xFF7FB0FF)),
      (done, const Color(0xFF6EE7B7)),
    ];

    double start = -math.pi / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (final seg in segments) {
      if (seg.$1 == 0) continue;
      final sweep = (seg.$1 / total) * math.pi * 2;
      final paint = Paint()
        ..color = seg.$2
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.todo != todo ||
        oldDelegate.inProgress != inProgress ||
        oldDelegate.done != done ||
        oldDelegate.total != total;
  }
}

class _PriorityBreakdown extends StatelessWidget {
  const _PriorityBreakdown({
    required this.priorityCounts,
    required this.onPriorityTap,
  });

  final Map<String, int> priorityCounts;
  final ValueChanged<String> onPriorityTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final entries = <_PriorityEntry>[
      _PriorityEntry('Highest', Icons.keyboard_double_arrow_up_rounded,
          const Color(0xFFFF6B5F), priorityCounts['Highest'] ?? 0),
      _PriorityEntry('High', Icons.keyboard_arrow_up_rounded,
          const Color(0xFFFF8B6B), priorityCounts['High'] ?? 0),
      _PriorityEntry('Medium', Icons.drag_handle_rounded,
          const Color(0xFFFF8B00), priorityCounts['Medium'] ?? 0),
      _PriorityEntry('Low', Icons.keyboard_arrow_down_rounded,
          const Color(0xFF6CA6FF), priorityCounts['Low'] ?? 0),
      _PriorityEntry('Lowest', Icons.keyboard_double_arrow_down_rounded,
          const Color(0xFF4C84FF), priorityCounts['Lowest'] ?? 0),
    ];
    final maxCount = entries.fold<int>(0, (m, e) => math.max(m, e.count));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('优先级细分', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text('当前空间所有工作项', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 18),
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: entries
                .map(
                  (item) => Expanded(
                    child: GestureDetector(
                      onTap: () => onPriorityTap(item.label),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: 36,
                                height: maxCount == 0
                                    ? 4
                                    : (item.count / maxCount) * 110 + 4,
                                decoration: BoxDecoration(
                                  color: item.color,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${item.count}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Icon(item.icon, color: item.color, size: 20),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 4),
        Divider(color: palette.divider),
        const SizedBox(height: 8),
        Wrap(
          spacing: 18,
          runSpacing: 10,
          children: entries
              .map(
                (item) => InkWell(
                  onTap: () => onPriorityTap(item.label),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, color: item.color, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _PriorityEntry {
  const _PriorityEntry(this.label, this.icon, this.color, this.count);

  final String label;
  final IconData icon;
  final Color color;
  final int count;
}
