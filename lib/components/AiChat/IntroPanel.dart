import 'package:flutter/material.dart';
import 'package:ottersync/theme/design_tokens.dart';

/// 空对话时的欢迎页：渐变 logo + 大标题 + 三条建议。
class IntroPanel extends StatelessWidget {
  const IntroPanel({
    super.key,
    required this.configured,
    required this.onSuggestionTap,
  });

  final bool configured;
  final ValueChanged<String> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    const suggestions = [
      ('帮我建一个任务', '在 OT 空间下周三之前完成 H5 登录页面'),
      ('记录一个 Bug', 'iOS 看板拖拽闪退，优先级最高'),
      ('安排冲刺工作', '后天创建故事「冲刺周报模板」并分配给我'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
      children: [
        const SizedBox(height: 30),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6E5BFF), Color(0xFF1F8FFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '今天想做点什么？',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (!configured) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: palette.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: palette.danger.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: palette.danger, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '未检测到 OPENAI_API_KEY，请在 .env 中填写后重启应用。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.danger,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 36),
        for (final s in suggestions) ...[
          _SuggestionChip(
            title: s.$1,
            subtitle: s.$2,
            onTap: () => onSuggestionTap(s.$2),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.divider),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.north_east_rounded,
                color: palette.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}
