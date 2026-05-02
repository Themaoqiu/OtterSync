import 'package:flutter/material.dart';
import 'package:ottersync/components/CreateWorkItem/CircleIconButton.dart';

class CreateWorkItemTopBar extends StatelessWidget {
  const CreateWorkItemTopBar({
    required this.onClose,
    required this.onSubmit,
    required this.saving,
    super.key,
  });

  final VoidCallback onClose;
  final VoidCallback onSubmit;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        CircleIconButton(
          icon: Icons.close_rounded,
          onTap: saving ? null : onClose,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '创建',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        CircleIconButton(
          icon: Icons.check_rounded,
          filled: true,
          busy: saving,
          onTap: saving ? null : onSubmit,
        ),
      ],
    );
  }
}
