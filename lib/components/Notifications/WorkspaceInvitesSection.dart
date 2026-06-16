import 'package:flutter/material.dart';
import 'package:ottersync/components/Notifications/WorkspaceInviteCard.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/work_item_models.dart';

class WorkspaceInvitesSection extends StatelessWidget {
  const WorkspaceInvitesSection({
    super.key,
    required this.invites,
    required this.processingInviteId,
    required this.onAccept,
    required this.onDecline,
  });

  final List<WorkspaceInvite> invites;
  final String? processingInviteId;
  final ValueChanged<WorkspaceInvite> onAccept;
  final ValueChanged<WorkspaceInvite> onDecline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (invites.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 8, 2, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('待处理邀请', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('接受后才会加入对应工作空间。', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        ...invites.map(
          (invite) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sectionGap),
            child: WorkspaceInviteCard(
              invite: invite,
              processing: processingInviteId == invite.id,
              onAccept: () => onAccept(invite),
              onDecline: () => onDecline(invite),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
