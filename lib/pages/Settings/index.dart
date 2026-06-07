import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/state/theme_controller.dart';
import 'package:ottersync/theme/design_tokens.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);
    final themeController = ThemeControllerScope.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('设置', style: theme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SectionLabel(text: '外观'),
          AppSurface(
            padding: EdgeInsets.zero,
            child: _SwitchRow(
              icon: Icons.dark_mode_rounded,
              iconColor: const Color(0xFF6E5BFF),
              title: '深色模式',
              subtitle: '使用深色背景，弱光环境下更舒适',
              value: themeController.isDarkMode,
              onChanged: (_) => themeController.toggle(),
            ),
          ),
          const SizedBox(height: 22),
          _SectionLabel(text: '关于'),
          AppSurface(
            padding: EdgeInsets.zero,
            child: _NavRow(
              icon: Icons.info_outline_rounded,
              iconColor: palette.textSecondary,
              title: '版本',
              trailing: '1.0.0',
              onTap: null,
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
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
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

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: theme.textTheme.bodyLarge)),
            if (trailing.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  trailing,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: palette.textSecondary),
                ),
              ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded,
                  color: palette.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
