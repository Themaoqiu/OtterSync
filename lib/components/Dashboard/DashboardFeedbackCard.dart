import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/theme/design_tokens.dart';

class DashboardFeedbackCard extends StatelessWidget {
  const DashboardFeedbackCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('您似乎缺少某些小工具', style: theme.textTheme.titleLarge),
          const SizedBox(height: 18),
          Text(
            '我们正在为移动设备上的仪表板构建更多小工具。请告诉我们您需要哪些小工具。',
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
          ),
          const SizedBox(height: 18),
          InkWell(
            onTap: onTap,
            child: Text(
              '发送反馈',
              style: theme.textTheme.labelLarge?.copyWith(
                color: palette.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
