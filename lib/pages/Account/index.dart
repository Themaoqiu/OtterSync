import 'package:flutter/material.dart';
import 'package:ottersync/components/Account/AccountActionList.dart';
import 'package:ottersync/components/Account/AccountProfileCard.dart';
import 'package:ottersync/components/Common/demo_feedback.dart';
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              '退出',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);
    final auth = AuthScope.of(context);

    const itemsGroup1 = [
      AccountActionItem(
        title: '邀请人员访问该工作区',
        icon: Icons.person_add_alt_1_outlined,
      ),
    ];

    const itemsGroup2 = [
      AccountActionItem(title: '通知设置', icon: Icons.notifications_none_rounded),
      AccountActionItem(title: '设置', icon: Icons.settings_outlined),
    ];

    const itemsGroup3 = [
      AccountActionItem(title: '提供反馈', icon: Icons.mail_outline_rounded),
      AccountActionItem(title: '评价我们', icon: Icons.star_border_rounded),
      AccountActionItem(
        title: '更多 Atlassian 应用',
        icon: Icons.grid_view_rounded,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('账户中心', style: theme.textTheme.headlineMedium),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          AccountProfileCard(
            displayName: auth.displayName,
            email: auth.email,
            onAddSite: () => showDemoFeedback(context, '后续可在这里接入站点新增流程。'),
          ),
          const SizedBox(height: 32),

          Text(
            '工作区',
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          AccountActionList(
            items: itemsGroup1,
            onTap: (item) =>
                showDemoFeedback(context, '${item.title} 入口已保留，可直接接后端。'),
          ),

          const SizedBox(height: 24),
          Text(
            '首选项',
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          AccountActionList(
            items: itemsGroup2,
            onTap: (item) => showDemoFeedback(context, '功能开发中，敬请期待'),
          ),

          const SizedBox(height: 24),
          Text(
            '关于',
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          AccountActionList(
            items: itemsGroup3,
            onTap: (item) {
              if (item.title == '提供反馈') {
                showDemoFeedback(context, '反馈渠道开发中，敬请期待');
              } else if (item.title == '评价我们') {
                showDemoFeedback(context, '评价功能开发中，敬请期待');
              } else {
                showDemoFeedback(context, '功能开发中，敬请期待');
              }
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
