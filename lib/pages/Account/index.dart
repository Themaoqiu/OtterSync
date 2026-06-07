import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/components/Account/AccountActionList.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/components/Common/UserAvatar.dart';
import 'package:ottersync/state/auth_controller.dart';
import 'package:ottersync/theme/design_tokens.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await AuthScope.of(context).signOut();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('退出失败：$e')),
      );
    }
  }

  Future<void> _editDisplayName(BuildContext context) async {
    final auth = AuthScope.of(context);
    final controller = TextEditingController(text: auth.displayName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑显示名'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '显示名'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty || !context.mounted) return;
    try {
      await AuthScope.of(context).updateDisplayName(result);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已更新显示名')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('更新失败：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);
    final auth = AuthScope.of(context);
    final initials = (auth.displayName.isEmpty ? '?' : auth.displayName)
        .characters
        .take(2)
        .toString()
        .toUpperCase();

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('账户中心', style: theme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          AppSurface(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                UserAvatar(label: initials, size: 60),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.displayName.isEmpty ? '未命名用户' : auth.displayName,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        auth.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _editDisplayName(context),
                  icon: Icon(Icons.edit_rounded, color: palette.primary),
                  tooltip: '编辑显示名',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _SectionLabel(text: '偏好'),
          const SizedBox(height: 8),
          AccountActionList(
            items: const [
              AccountActionItem(
                title: '设置',
                icon: Icons.settings_outlined,
              ),
            ],
            onTap: (item) => context.push('/settings'),
          ),
          const SizedBox(height: 28),
          _SectionLabel(text: '关于'),
          const SizedBox(height: 8),
          AccountActionList(
            items: const [
              AccountActionItem(
                title: '版本',
                icon: Icons.info_outline_rounded,
              ),
            ],
            onTap: (item) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('OtterSync 1.0.0')));
            },
          ),
          const SizedBox(height: 48),
          Center(
            child: TextButton(
              onPressed: () => _handleSignOut(context),
              child: Text(
                '退出登录',
                style: TextStyle(color: palette.danger, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.textSecondary,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
