import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

class SettingsTabView extends StatelessWidget {
  const SettingsTabView({
    super.key,
    required this.space,
    required this.onInviteMember,
  });

  final JiraSpace space;
  final VoidCallback onInviteMember;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: AppSpace.pagePaddingWithNav,
      children: [
        AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('空间设置', style: theme.textTheme.titleMedium),
              const SizedBox(height: 18),
              _SettingRow(label: '空间名称', value: space.name),
              const SizedBox(height: 14),
              _SettingRow(label: '空间 Key', value: space.key),
              const SizedBox(height: 14),
              _SettingRow(label: '空间模板', value: space.template),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onInviteMember,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('邀请成员协作'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(value, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}
