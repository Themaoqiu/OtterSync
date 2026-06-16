import 'package:flutter/material.dart';
import 'package:ottersync/theme/design_tokens.dart';

class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 8, 12),
      child: Row(
        children: [
          const SizedBox(width: 36),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          trailing ??
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(Icons.close_rounded, color: palette.textSecondary),
                tooltip: '关闭',
              ),
        ],
      ),
    );
  }
}
