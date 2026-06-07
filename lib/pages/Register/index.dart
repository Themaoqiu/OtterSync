import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/components/Login/AuthFormScaffold.dart';
import 'package:ottersync/services/auth_service.dart';
import 'package:ottersync/state/auth_controller.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthScope.of(context).register(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
    } on AuthServiceException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('注册失败：$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AuthFormScaffold(
        title: '创建账号',
        subtitle: '填写下面的信息来开启 OtterSync。',
        primaryLabel: '注册',
        onPrimary: _handleRegister,
        loading: _isLoading,
        bottomLink: '已有账号？立即登录',
        onBottomLinkTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/sign-in');
          }
        },
        children: [
          AuthTextField(
            controller: _usernameController,
            focusNode: _usernameFocus,
            hint: '用户名称',
            icon: Icons.badge_outlined,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_emailFocus),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入用户名称。';
              }
              if (value.trim().length < 2) {
                return '用户名称至少 2 个字符。';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: _emailController,
            focusNode: _emailFocus,
            hint: '邮箱',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_passwordFocus),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入邮箱。';
              }
              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!emailRegex.hasMatch(value.trim())) {
                return '邮箱格式不正确。';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            hint: '密码',
            icon: Icons.lock_outline,
            obscure: _obscurePassword,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_confirmFocus),
            suffix: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white.withValues(alpha: 0.8),
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入密码。';
              }
              if (value.trim().length < 6) {
                return '密码至少 6 位。';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: _confirmController,
            focusNode: _confirmFocus,
            hint: '确认密码',
            icon: Icons.lock_outline,
            obscure: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleRegister(),
            suffix: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white.withValues(alpha: 0.8),
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请确认密码。';
              }
              if (value != _passwordController.text) {
                return '两次输入的密码不一致。';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
