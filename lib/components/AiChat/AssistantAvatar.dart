import 'package:flutter/material.dart';

/// 渐变圆形 AI 头像，AiChat 各处复用。
class AssistantAvatar extends StatelessWidget {
  const AssistantAvatar({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6E5BFF), Color(0xFF1F8FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }
}
