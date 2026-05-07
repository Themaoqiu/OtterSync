import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

class HomeWorkFilterCard extends StatelessWidget {
  const HomeWorkFilterCard({
    super.key,
    required this.previewItem,
    required this.onTap,
  });

  final IssueSummary? previewItem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpace.radiusLarge),
        child: AppSurface(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8E7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.filter_alt_outlined,
                  color: Color(0xFF0C66E4),
                ),
              ),
              const SizedBox(height: 12),
              Text('我的工作', style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                previewItem == null ? '筛选器' : '筛选器',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
