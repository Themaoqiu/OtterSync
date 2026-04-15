import 'package:flutter/material.dart';
import 'package:ottersync/theme/design_tokens.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.label,
    this.size = 48,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? palette.avatar,
        shape: BoxShape.circle,
        border: Border.all(
          color: palette.surface, // White border to make overlapping look good
          width: size > 32 ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label.length > 2
            ? label.substring(0, 2).toUpperCase()
            : label.toUpperCase(),
        style: TextStyle(
          color: foregroundColor ?? const Color(0xFF09326C),
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}
