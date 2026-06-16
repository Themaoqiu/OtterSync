import 'package:flutter/material.dart';

class WorkTypeVisual {
  const WorkTypeVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

WorkTypeVisual workTypeVisual(String? title) {
  final t = (title ?? '').toLowerCase().trim();
  if (t.contains('bug') || t.contains('缺陷') || t.contains('问题')) {
    return const WorkTypeVisual(
      icon: Icons.bug_report_rounded,
      color: Color(0xFFE5493A),
    );
  }
  if (t.contains('story') || t.contains('故事') || t.contains('用户故事')) {
    return const WorkTypeVisual(
      icon: Icons.bookmark_rounded,
      color: Color(0xFF65BA43),
    );
  }
  if (t.contains('epic') || t.contains('史诗')) {
    return const WorkTypeVisual(
      icon: Icons.bolt_rounded,
      color: Color(0xFF904EE2),
    );
  }
  if (t.contains('subtask') || t.contains('子任务')) {
    return const WorkTypeVisual(
      icon: Icons.subdirectory_arrow_right_rounded,
      color: Color(0xFF1F8FFF),
    );
  }
  if (t.contains('需求') || t.contains('feature')) {
    return const WorkTypeVisual(
      icon: Icons.flag_rounded,
      color: Color(0xFFE56910),
    );
  }
  if (t.contains('改进') || t.contains('improvement')) {
    return const WorkTypeVisual(
      icon: Icons.trending_up_rounded,
      color: Color(0xFF14B8A6),
    );
  }
  return const WorkTypeVisual(
    icon: Icons.check_box_rounded,
    color: Color(0xFF1F5DBD),
  );
}

class WorkTypeIconBadge extends StatelessWidget {
  const WorkTypeIconBadge({super.key, required this.title, this.size = 26});

  final String? title;
  final double size;

  @override
  Widget build(BuildContext context) {
    final v = workTypeVisual(title);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: v.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Icon(v.icon, color: v.color, size: size * 0.65),
    );
  }
}
