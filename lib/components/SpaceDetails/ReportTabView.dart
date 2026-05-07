import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

class ReportTabView extends StatelessWidget {
  const ReportTabView({
    super.key,
    required this.metrics,
  });

  final List<SpaceSummaryMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: AppSpace.pagePaddingWithNav,
      children: [
        AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('报告', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('基于当前空间的真实工作项统计汇总。', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...metrics.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppSurface(
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: item.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.headline, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Text(
                          '${item.value} ${item.emphasis}',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
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
