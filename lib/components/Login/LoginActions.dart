import 'package:flutter/material.dart';

/// 登录页底部一对圆角条状按钮：白色填充"登录" + 蓝底白边描边"注册"。
class LoginActions extends StatelessWidget {
  const LoginActions({
    super.key,
    required this.onLogin,
    required this.onRegister,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;

  static const _navy = Color(0xFF143C82);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BarButton(
            label: '登录',
            background: Colors.white,
            foreground: _navy,
            onTap: onLogin,
            border: false,
          ),
          const SizedBox(height: 12),
          _BarButton(
            label: '注册',
            background: Colors.transparent,
            foreground: Colors.white,
            onTap: onRegister,
            border: true,
          ),
        ],
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    required this.border,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.zero,
            border: border
                ? Border.all(color: Colors.white, width: 1.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
