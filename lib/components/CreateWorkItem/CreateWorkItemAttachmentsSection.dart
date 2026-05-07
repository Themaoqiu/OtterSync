import 'package:flutter/material.dart';
import 'package:ottersync/components/CreateWorkItem/AttachmentAction.dart';
import 'package:ottersync/components/CreateWorkItem/AttachmentTile.dart';
import 'package:ottersync/components/CreateWorkItem/CreateWorkItemSectionCard.dart';
import 'package:ottersync/viewmodels/work_item_models.dart';

class CreateWorkItemAttachmentsSection extends StatelessWidget {
  const CreateWorkItemAttachmentsSection({
    required this.attachments,
    required this.saving,
    required this.onAddPhoto,
    required this.onAddVideo,
    required this.onAddDocument,
    required this.onAddScreen,
    required this.onDeleteAttachment,
    super.key,
  });

  final List<AttachmentCreateRequest> attachments;
  final bool saving;
  final VoidCallback onAddPhoto;
  final VoidCallback onAddVideo;
  final VoidCallback onAddDocument;
  final VoidCallback onAddScreen;
  final ValueChanged<int> onDeleteAttachment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CreateWorkItemSectionCard(
      title: '附件',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AttachmentAction(
                  icon: Icons.photo_camera_outlined,
                  label: '拍摄照片',
                  onTap: saving ? null : onAddPhoto,
                ),
              ),
              Expanded(
                child: AttachmentAction(
                  icon: Icons.videocam_outlined,
                  label: '录制视频',
                  onTap: saving ? null : onAddVideo,
                ),
              ),
              Expanded(
                child: AttachmentAction(
                  icon: Icons.attach_file_rounded,
                  label: '选择文件',
                  onTap: saving ? null : onAddDocument,
                ),
              ),
              Expanded(
                child: AttachmentAction(
                  icon: Icons.screen_share_outlined,
                  label: '录制屏幕',
                  onTap: saving ? null : onAddScreen,
                ),
              ),
            ],
          ),
          if (attachments.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text('暂未添加附件', style: theme.textTheme.bodySmall),
            ),
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...attachments.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AttachmentTile(
                  attachment: entry.value,
                  onDelete: saving ? null : () => onDeleteAttachment(entry.key),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
