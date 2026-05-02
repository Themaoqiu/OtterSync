import 'package:flutter/material.dart';
import 'package:ottersync/theme/design_tokens.dart';

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    required this.icon,
    this.onTap,
    this.filled = false,
    this.busy = false,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpace.radiusFull),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: filled ? theme.colorScheme.primary : palette.surface,
          shape: BoxShape.circle,
          border: Border.all(color: palette.border),
        ),
        child: Center(
          child: busy
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: filled ? Colors.white : palette.primary,
                  ),
                )
              : Icon(
                  icon,
                  color: onTap == null
                      ? palette.textTertiary
                      : (filled ? Colors.white : palette.textPrimary),
                  size: 28,
                ),
        ),
      ),
    );
  }
}
