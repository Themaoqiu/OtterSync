import 'package:flutter/material.dart';
import 'package:ottersync/components/AiChat/AssistantAvatar.dart';
import 'package:ottersync/theme/design_tokens.dart';

class TypingRow extends StatefulWidget {
  const TypingRow({super.key});

  @override
  State<TypingRow> createState() => _TypingRowState();
}

class _TypingRowState extends State<TypingRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssistantAvatar(),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _ctl,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final t = (_ctl.value * 3 - i).clamp(0.0, 1.0);
                  final scale =
                      0.6 + (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0) * 0.5;
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: 7 * scale,
                    height: 7 * scale,
                    decoration: BoxDecoration(
                      color: palette.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
