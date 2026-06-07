import 'package:flutter/material.dart';
import 'package:ottersync/theme/design_tokens.dart';

/// 底部胶囊状输入框 + 发送按钮。
/// 关键点：用 Container.border 自绘外框，并通过 InputDecoration 把
/// TextField 自身的所有 border 都置为 none，避免聚焦时跑出第二条 Material 蓝线。
class Composer extends StatelessWidget {
  const Composer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.canSend,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final bool canSend;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final isFocused = focusNode.hasFocus;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
          decoration: BoxDecoration(
            color: palette.surfaceRaised,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isFocused ? palette.primary : palette.divider,
              width: isFocused ? 1.4 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 6,
                  cursorColor: palette.primary,
                  style: TextStyle(
                    color: palette.textPrimary,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: '描述你想做的事…',
                    hintStyle: TextStyle(color: palette.textTertiary),
                    isDense: true,
                    filled: false,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                  textInputAction: TextInputAction.newline,
                ),
              ),
              const SizedBox(width: 6),
              _SendButton(
                enabled: canSend && !sending,
                sending: sending,
                onTap: onSend,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.enabled,
    required this.sending,
    required this.onTap,
  });

  final bool enabled;
  final bool sending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final color = enabled ? palette.textPrimary : palette.surfaceInset;
    final fg = enabled ? palette.surface : palette.textTertiary;
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: sending
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fg,
                    ),
                  )
                : Icon(Icons.arrow_upward_rounded, color: fg, size: 20),
          ),
        ),
      ),
    );
  }
}
