import 'package:flutter/material.dart';
import 'package:ottersync/components/Account/AccountActionList.dart';
import 'package:ottersync/components/Account/AccountProfileCard.dart';
import 'package:ottersync/components/Common/demo_feedback.dart';
import 'package:ottersync/theme/design_tokens.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    // Grouping the items visually creates a cleaner "iOS Settings" / "Premium App" vibe.
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
        title: Text(
          '账户中心',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          AccountProfileCard(
            onAddSite: () => showDemoFeedback(context, '后续可在这里接入站点新增流程。'),
          ),
          const SizedBox(height: 32),

          Text(
            '工作区',
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textSecondary,
              fontWeight: FontWeight.w600,
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
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          AccountActionList(
            items: itemsGroup2,
            onTap: (item) => showDemoFeedback(context, '${item.title} 视图未实现。'),
          ),

          const SizedBox(height: 24),
          Text(
            '关于',
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          AccountActionList(
            items: itemsGroup3,
            onTap: (item) => showDemoFeedback(context, '${item.title} 操作已代理。'),
          ),
          const SizedBox(height: 48),

          Center(
            child: TextButton(
              onPressed: () => showDemoFeedback(context, '登出流程预留'),
              child: Text(
                '退出登录',
                style: TextStyle(
                  color: palette.danger,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
