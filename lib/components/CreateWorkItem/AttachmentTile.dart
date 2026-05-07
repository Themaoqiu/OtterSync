import 'package:flutter/material.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/work_item_models.dart';

class AttachmentTile extends StatelessWidget {
  const AttachmentTile({required this.attachment, this.onDelete, super.key});

  final AttachmentCreateRequest attachment;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemePalette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: BorderRadius.circular(AppSpace.radiusLarge),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_file_rounded, color: palette.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(attachment.name, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  '${attachment.kind.name} · ${attachment.uri}',
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}
