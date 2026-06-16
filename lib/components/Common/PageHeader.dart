import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/components/Common/UserAvatar.dart';
import 'package:ottersync/state/auth_controller.dart';
import 'package:ottersync/theme/design_tokens.dart';

/// Top-of-page header shared by Home / Spaces / AllWork / Dashboard / Notifications.
///
/// Layout: [avatar] · [title] · [actions...]
/// Padding mirrors the home page so the layout never feels jarring across tabs.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    this.title,
    this.actions = const [],
    this.userInitials,
    this.onAvatarTap,
    this.titleAlign = TextAlign.left,
  });

  final String? title;
  final List<Widget> actions;

  /// Optional override; when null the initials are derived from the signed-in
  /// user's display name so every page stays in sync with the account page.
  final String? userInitials;
  final VoidCallback? onAvatarTap;
  final TextAlign titleAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = userInitials ?? _initialsFromAuth(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
      child: Row(
        children: [
          InkWell(
            onTap: onAvatarTap ?? () => context.push('/account'),
            borderRadius: BorderRadius.circular(999),
            child: UserAvatar(label: initials),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: title == null
                ? const SizedBox.shrink()
                : Text(
                    title!,
                    textAlign: titleAlign,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          ...actions,
        ],
      ),
    );
  }

  static String _initialsFromAuth(BuildContext context) {
    final name = AuthScope.of(context).displayName.trim();
    if (name.isEmpty) return '?';
    return name.characters.take(2).toString().toUpperCase();
  }
}

/// Standardized header action button. Consistent size + tap area across pages.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.emphasized = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final iconColor =
        color ?? (emphasized ? palette.primary : palette.textSecondary);
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: 28,
      visualDensity: VisualDensity.standard,
      icon: Icon(icon, color: iconColor),
    );
  }
}

/// Wrap any page body to apply a fade+slide entrance animation.
/// Keeps inter-tab transitions feeling cohesive.
class PageFadeSlide extends StatefulWidget {
  const PageFadeSlide({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 320),
  });

  final Widget child;
  final Duration duration;

  @override
  State<PageFadeSlide> createState() => _PageFadeSlideState();
}

class _PageFadeSlideState extends State<PageFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _ctl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(_fade);
    _ctl.forward();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
