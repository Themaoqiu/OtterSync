import 'package:flutter/material.dart';
import 'package:ottersync/components/AiChat/AssistantAvatar.dart';
import 'package:ottersync/theme/design_tokens.dart';

/// 用户消息：右对齐胶囊气泡，使用 surfaceInset，深浅模式自适应。
class UserBubble extends StatelessWidget {
  const UserBubble({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: palette.surfaceInset,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.divider),
            ),
            child: SelectableText(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: palette.textPrimary,
                height: 1.45,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// AI 消息：左侧 logo + 全宽行文，参考 ChatGPT 信件流。
class AssistantRow extends StatelessWidget {
  const AssistantRow({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssistantAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: palette.textPrimary,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
