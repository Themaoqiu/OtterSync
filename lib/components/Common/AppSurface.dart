import 'package:flutter/material.dart';
import 'package:ottersync/theme/design_tokens.dart';

class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color,
    this.border,
    this.customShadow,
    this.radius = AppSpace.radiusLarge,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? customShadow;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: AppDecorations.surface(
        context,
        radius: radius,
        color: color,
        border: border,
        customShadow: customShadow,
      ),
      child: child,
    );
  }
}
