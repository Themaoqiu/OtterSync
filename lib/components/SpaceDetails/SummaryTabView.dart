import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

class SummaryTabView extends StatelessWidget {
  const SummaryTabView({
    super.key,
    required this.metrics,
    required this.onStatusTap,
  });

  final List<SpaceSummaryMetric> metrics;
  final ValueChanged<String> onStatusTap;

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
            return AppSurface(
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
            );
          },
        ),
        const SizedBox(height: 18),
        AppSurface(child: _StatusOverview(onStatusTap: onStatusTap)),
        const SizedBox(height: 18),
        const AppSurface(child: _PriorityBreakdown()),
      ],
    );
  }
}

class _StatusOverview extends StatelessWidget {
  const _StatusOverview({required this.onStatusTap});

  final ValueChanged<String> onStatusTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final items = const [
      ('待办', Color(0xFFE7E9EF), '2'),
      ('正在进行', Color(0xFF7FB0FF), '0'),
      ('已完成', Color(0xFF6EE7B7), '0'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('状态概述', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text('在过去 14 天内', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 18),
        const SizedBox(height: 280, child: _DonutChart()),
        const SizedBox(height: 10),
        ...items.map(
          (item) => InkWell(
            onTap: () => onStatusTap(item.$1),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: item.$2,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.$1,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Text(
                    item.$3,
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
  const _DonutChart();

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    return CustomPaint(
      painter: _DonutPainter(
        ringColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFE7E9EF)
            : const Color(0xFFCFD6E4),
        centerColor: palette.surface,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '2',
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
  const _DonutPainter({required this.ringColor, required this.centerColor});

  final Color ringColor;
  final Color centerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final ring = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 36;
    final fill = Paint()
      ..color = centerColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, ring);
    canvas.drawCircle(center, radius - 26, fill);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.ringColor != ringColor ||
        oldDelegate.centerColor != centerColor;
  }
}

class _PriorityBreakdown extends StatelessWidget {
  const _PriorityBreakdown();

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final labels = const [
      ('Highest', '⏫', Color(0xFFFF6B5F), 0.0),
      ('High', '⌃', Color(0xFFFF6B5F), 0.0),
      ('Medium', '=', Color(0xFFFF8B00), 1.0),
      ('Low', '⌄', Color(0xFF6CA6FF), 0.0),
      ('Lowest', '⌄⌄', Color(0xFF4C84FF), 0.0),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('优先级细分', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text('在过去 14 天内', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 18),
        SizedBox(
          height: 220,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: labels
                .map(
                  (item) => Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 44,
                              height: item.$4 * 126,
                              color: item.$3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.$2,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: item.$3,
                              ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Divider(color: palette.divider),
        const SizedBox(height: 8),
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: labels
              .map(
                (item) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.$2,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: item.$3,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.$1,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
