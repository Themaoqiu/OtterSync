import 'package:flutter/material.dart';
import 'package:ottersync/theme/design_tokens.dart';

enum HomeActivityMode { viewed, dynamic }

class HomeActivitySwitcher extends StatelessWidget {
  const HomeActivitySwitcher({
    super.key,
    required this.mode,
    required this.onModeChanged,
  });

  final HomeActivityMode mode;
  final ValueChanged<HomeActivityMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);

    return Column(
      children: [
        Container(
          height: 42,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ModeButton(
                  label: '已查看',
                  selected: mode == HomeActivityMode.viewed,
                  onTap: () => onModeChanged(HomeActivityMode.viewed),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ModeButton(
                  label: '动态',
                  selected: mode == HomeActivityMode.dynamic,
                  onTap: () => onModeChanged(HomeActivityMode.dynamic),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? palette.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.transparent),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.visible,
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: selected ? palette.primary : palette.textSecondary,
                    height: 1.0,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
