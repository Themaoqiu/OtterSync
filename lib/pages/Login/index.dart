import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/services/auth_service.dart';
import 'package:ottersync/state/auth_controller.dart';
import 'package:ottersync/theme/design_tokens.dart';

enum _LoginMethod { password, oneClick }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  _LoginMethod _method = _LoginMethod.password;
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _accountFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    _accountFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordLogin() async {
    final account = _accountController.text.trim();
    final password = _passwordController.text;

    if (account.isEmpty || password.isEmpty) {
      _showError('请输入账号和密码。');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthScope.of(context).signIn(account, password);
    } on AuthServiceException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('登录失败：$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await AuthScope.of(context).signInWithGoogle();
    } on AuthServiceException catch (e) {
      if (e.message != '已取消 Google 登录') {
        _showError(e.message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await AuthScope.of(context).signInWithApple();
    } on AuthServiceException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);

    return Scaffold(
      backgroundColor: palette.scaffold,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpace.pagePadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(palette),
                const SizedBox(height: 40),
                _buildMethodSwitcher(palette),
                const SizedBox(height: 32),
                if (_method == _LoginMethod.password)
                  _buildPasswordForm(palette)
                else
                  _buildOneClickSection(palette),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppPalette palette) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: palette.primarySoft,
            borderRadius: BorderRadius.circular(AppSpace.radiusXLarge),
          ),
          child: Icon(
            Icons.sync_alt_rounded,
            size: 36,
            color: palette.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'OtterSync',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '登录以继续',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildMethodSwitcher(AppPalette palette) {
    return SegmentedButton<_LoginMethod>(
      segments: const [
        ButtonSegment(
          value: _LoginMethod.password,
          label: Text('账号登录'),
          icon: Icon(Icons.person_outline, size: 18),
        ),
        ButtonSegment(
          value: _LoginMethod.oneClick,
          label: Text('一键登录'),
          icon: Icon(Icons.login_rounded, size: 18),
        ),
      ],
      selected: {_method},
      onSelectionChanged: (value) => setState(() => _method = value.first),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.primarySoft;
          }
          return palette.surfaceRaised;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.primary;
          }
          return palette.textSecondary;
        }),
      ),
    );
  }

  Widget _buildPasswordForm(AppPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _accountController,
          focusNode: _accountFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) =>
              FocusScope.of(context).requestFocus(_passwordFocus),
          decoration: const InputDecoration(
            hintText: '邮箱或用户名',
            prefixIcon: Icon(Icons.person_outline, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handlePasswordLogin(),
          decoration: InputDecoration(
            hintText: '密码',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isLoading ? null : _handlePasswordLogin,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('登录', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => context.push('/register'),
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: const [
                TextSpan(text: '还没有账号？'),
                TextSpan(
                  text: ' 注册新账号',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOneClickSection(AppPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _handleGoogleSignIn,
          icon: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : _buildProviderIcon(Icons.g_mobiledata_rounded, palette),
          label: const Text('使用 Google 登录'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _handleAppleSignIn,
          icon: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.apple, size: 22, color: palette.textPrimary),
          label: const Text('使用 Apple 登录'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => context.push('/register'),
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: const [
                TextSpan(text: '还没有账号？'),
                TextSpan(
                  text: ' 注册新账号',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProviderIcon(IconData icon, AppPalette palette) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      child: Icon(icon, size: 22, color: palette.textPrimary),
    );
  }
}