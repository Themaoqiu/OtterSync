import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';
import 'package:ottersync/viewmodels/work_item_models.dart';

class ReportTabView extends StatelessWidget {
  const ReportTabView({
    super.key,
    required this.spaceKey,
    required this.sprints,
    required this.items,
  });

  final String spaceKey;
  final List<Sprint> sprints;
  final List<IssueSummary> items;

  @override
  Widget build(BuildContext context) {
    final activeSprint = sprints.firstWhere(
      (s) => s.status == SprintStatus.active,
      orElse: () => sprints.isNotEmpty
          ? sprints.last
          : const Sprint(
              id: 0,
              workspaceId: 0,
              name: '冲刺 1',
              status: SprintStatus.planned,
            ),
    );

    final sprintItems = activeSprint.id == 0
        ? const <IssueSummary>[]
        : items.where((i) => i.sprintId == activeSprint.id).toList();

    return ListView(
      padding: AppSpace.pagePaddingWithNav,
      children: [
        AppSurface(
          child: _VelocityChart(
            sprintLabel: '$spaceKey 面板 ${activeSprint.name}',
            committed: sprintItems.length,
            completed:
                sprintItems.where((i) => i.statusKey == WorkItemStatus.done).length,
          ),
        ),
        const SizedBox(height: 14),
        AppSurface(
          child: _BurndownChart(
            sprintLabel: '$spaceKey 面板 ${activeSprint.name}',
            sprint: activeSprint,
            sprintItems: sprintItems,
          ),
        ),
        const SizedBox(height: 14),
        AppSurface(
          child: _CumulativeFlowChart(items: items),
        ),
      ],
    );
  }
}

class _VelocityChart extends StatelessWidget {
  const _VelocityChart({
    required this.sprintLabel,
    required this.committed,
    required this.completed,
  });

  final String sprintLabel;
  final int committed;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);
    final maxY = math.max(4, math.max(committed, completed));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('速度', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('故事点（按工作项数量近似）', style: theme.textTheme.bodySmall),
        const SizedBox(height: 14),
        SizedBox(
          height: 220,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _YAxisLabels(maxY: maxY),
              const SizedBox(width: 8),
              Expanded(
                child: CustomPaint(
                  painter: _VelocityPainter(
                    committed: committed.toDouble(),
                    completed: completed.toDouble(),
                    maxY: maxY.toDouble(),
                    gridColor: palette.divider,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            sprintLabel,
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 18),
        _LegendRow(
          color: const Color(0xFF6CA6FF),
          label: '承诺平均值',
          value: '$committed',
        ),
        const SizedBox(height: 8),
        _LegendRow(
          color: const Color(0xFF6EE7B7),
          label: '已完成平均值',
          value: '$completed',
        ),
      ],
    );
  }
}

class _BurndownChart extends StatelessWidget {
  const _BurndownChart({
    required this.sprintLabel,
    required this.sprint,
    required this.sprintItems,
  });

  final String sprintLabel;
  final Sprint sprint;
  final List<IssueSummary> sprintItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);
    final remaining = sprintItems
        .where((i) => i.statusKey != WorkItemStatus.done)
        .length;
    final total = sprintItems.length;
    final maxY = math.max(4, total);

    final start = sprint.startDate ?? DateTime.now().subtract(const Duration(days: 9));
    final end = sprint.endDate ?? DateTime.now().add(const Duration(days: 9));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('燃尽图', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(sprintLabel, style: theme.textTheme.bodySmall),
        const SizedBox(height: 14),
        SizedBox(
          height: 240,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _YAxisLabels(maxY: maxY),
              const SizedBox(width: 8),
              Expanded(
                child: CustomPaint(
                  painter: _BurndownPainter(
                    total: total.toDouble(),
                    remaining: remaining.toDouble(),
                    maxY: maxY.toDouble(),
                    gridColor: palette.divider,
                    lineColor: const Color(0xFFEF4444),
                    idealColor: palette.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_dateLabel(start), style: theme.textTheme.bodySmall),
              Text(_dateLabel(_midPoint(start, end)),
                  style: theme.textTheme.bodySmall),
              Text(_dateLabel(end), style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _LegendRow(
          color: const Color(0xFFEF4444),
          label: '剩余工作',
          value: '$remaining',
        ),
        const SizedBox(height: 8),
        _LegendRow(
          color: palette.textTertiary,
          label: '理想燃烧率',
          value: '',
        ),
      ],
    );
  }

  static DateTime _midPoint(DateTime a, DateTime b) {
    final ms = (a.millisecondsSinceEpoch + b.millisecondsSinceEpoch) ~/ 2;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static String _dateLabel(DateTime d) => '${d.month}月${d.day}日';
}

class _CumulativeFlowChart extends StatelessWidget {
  const _CumulativeFlowChart({required this.items});

  final List<IssueSummary> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);
    final todo =
        items.where((i) => i.statusKey == WorkItemStatus.todo).length;
    final inProgress = items
        .where((i) => i.statusKey == WorkItemStatus.inProgress)
        .length;
    final done =
        items.where((i) => i.statusKey == WorkItemStatus.done).length;
    final total = todo + inProgress + done;
    final maxY = math.max(6, total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('累积流程图', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('所有时间 · 计数', style: theme.textTheme.bodySmall),
        const SizedBox(height: 14),
        SizedBox(
          height: 220,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _YAxisLabels(maxY: maxY),
              const SizedBox(width: 8),
              Expanded(
                child: CustomPaint(
                  painter: _CumulativeFlowPainter(
                    todo: todo,
                    inProgress: inProgress,
                    done: done,
                    maxY: maxY.toDouble(),
                    gridColor: palette.divider,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _LegendRow(
          color: const Color(0xFFCFD6E4),
          label: '待办',
          value: '$todo',
        ),
        const SizedBox(height: 8),
        _LegendRow(
          color: const Color(0xFF7FB0FF),
          label: '进行中',
          value: '$inProgress',
        ),
        const SizedBox(height: 8),
        _LegendRow(
          color: const Color(0xFF6EE7B7),
          label: '已完成',
          value: '$done',
        ),
      ],
    );
  }
}

class _YAxisLabels extends StatelessWidget {
  const _YAxisLabels({required this.maxY});

  final int maxY;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = 4;
    final step = (maxY / steps).ceil();
    final labels = List<int>.generate(steps + 1, (i) => step * (steps - i));
    return SizedBox(
      width: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: labels
            .map((v) => Text('$v', style: theme.textTheme.bodySmall))
            .toList(),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _VelocityPainter extends CustomPainter {
  _VelocityPainter({
    required this.committed,
    required this.completed,
    required this.maxY,
    required this.gridColor,
  });

  final double committed;
  final double completed;
  final double maxY;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final barWidth = 28.0;
    final groupCenter = size.width / 2;
    double yFor(double v) => size.height - (v / maxY) * size.height;

    final committedPaint = Paint()..color = const Color(0xFF6CA6FF);
    final completedPaint = Paint()..color = const Color(0xFF6EE7B7);

    canvas.drawRect(
      Rect.fromLTWH(
        groupCenter - barWidth - 4,
        yFor(committed),
        barWidth,
        size.height - yFor(committed),
      ),
      committedPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        groupCenter + 4,
        yFor(completed),
        barWidth,
        size.height - yFor(completed),
      ),
      completedPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _VelocityPainter oldDelegate) =>
      oldDelegate.committed != committed ||
      oldDelegate.completed != completed ||
      oldDelegate.maxY != maxY;
}

class _BurndownPainter extends CustomPainter {
  _BurndownPainter({
    required this.total,
    required this.remaining,
    required this.maxY,
    required this.gridColor,
    required this.lineColor,
    required this.idealColor,
  });

  final double total;
  final double remaining;
  final double maxY;
  final Color gridColor;
  final Color lineColor;
  final Color idealColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    double yFor(double v) => size.height - (v / maxY) * size.height;

    final idealPaint = Paint()
      ..color = idealColor
      ..strokeWidth = 1.4;
    final dashWidth = 5.0;
    final dashGap = 4.0;
    final start = Offset(0, yFor(total));
    final end = Offset(size.width, yFor(0));
    final length = (end - start).distance;
    final direction = (end - start) / length;
    double drawn = 0;
    while (drawn < length) {
      final p1 = start + direction * drawn;
      final p2 = start + direction * math.min(drawn + dashWidth, length);
      canvas.drawLine(p1, p2, idealPaint);
      drawn += dashWidth + dashGap;
    }

    final remainingPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, yFor(total))
      ..lineTo(size.width * 0.5, yFor(remaining));
    canvas.drawPath(path, remainingPaint);
    canvas.drawCircle(
      Offset(size.width * 0.5, yFor(remaining)),
      4,
      Paint()..color = lineColor,
    );
  }

  @override
  bool shouldRepaint(covariant _BurndownPainter oldDelegate) =>
      oldDelegate.total != total ||
      oldDelegate.remaining != remaining ||
      oldDelegate.maxY != maxY;
}

class _CumulativeFlowPainter extends CustomPainter {
  _CumulativeFlowPainter({
    required this.todo,
    required this.inProgress,
    required this.done,
    required this.maxY,
    required this.gridColor,
  });

  final int todo;
  final int inProgress;
  final int done;
  final double maxY;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    double yFor(double v) => size.height - (v / maxY) * size.height;

    // simple stacked area: from left to right grows from 0 to total at right edge
    final cTodo = const Color(0xFFCFD6E4);
    final cInProg = const Color(0xFF7FB0FF);
    final cDone = const Color(0xFF6EE7B7);

    void drawStack(double level, Color color) {
      final path = Path()
        ..moveTo(0, size.height)
        ..lineTo(0, size.height)
        ..lineTo(size.width, yFor(level))
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    final total = todo + inProgress + done;
    if (total == 0) return;

    drawStack(total.toDouble(), cTodo);
    drawStack((inProgress + done).toDouble(), cInProg);
    drawStack(done.toDouble(), cDone);
  }

  @override
  bool shouldRepaint(covariant _CumulativeFlowPainter oldDelegate) =>
      oldDelegate.todo != todo ||
      oldDelegate.inProgress != inProgress ||
      oldDelegate.done != done ||
      oldDelegate.maxY != maxY;
}
