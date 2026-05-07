import 'package:flutter/material.dart';
import 'package:ottersync/components/Common/AppSurface.dart';
import 'package:ottersync/components/Common/IssueListTile.dart';
import 'package:ottersync/theme/design_tokens.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

class BoardTabView extends StatelessWidget {
  const BoardTabView({
    super.key,
    required this.onOpenBacklog,
    required this.itemCount,
    required this.items,
  });

  final VoidCallback onOpenBacklog;
  final int itemCount;
  final List<IssueSummary> items;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);

    return ListView(
      padding: AppSpace.pagePaddingWithNav,
      children: [
        AppSurface(
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    '冲刺工作  $itemCount',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: palette.textSecondary,
                        ),
                  ),
                  const Spacer(),
                  Icon(Icons.more_vert_rounded, color: palette.primary),
                ],
              ),
              const SizedBox(height: 22),
              if (items.isEmpty) ...[
                SizedBox(
                  height: 230,
                  child: CustomPaint(painter: _EmptyBoardPainter()),
                ),
                const SizedBox(height: 22),
                Text('尚无工作!', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 18),
                Text(
                  '从待办事项列表开始冲刺时，团队工作将显示在此处。',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ] else
                Column(
                  children: items
                      .map(
                        (item) => IssueListTile(
                          title: item.title,
                          subtitle: '${item.key} · ${item.subtitle ?? ''}',
                          status: item.status,
                          avatar: item.assigneeInitials,
                        ),
                      )
                      .toList(growable: false),
                ),
              const SizedBox(height: 28),
              TextButton.icon(
                onPressed: onOpenBacklog,
                icon: Icon(Icons.view_list_rounded, color: palette.primary),
                label: Text(
                  items.isEmpty ? '查看待办事项列表' : '管理冲刺工作',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: palette.primary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blue = Paint()..color = const Color(0xFF1F5DBD);
    final orange = Paint()..color = const Color(0xFFF57C00);
    final green = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.18, 30, size.width * 0.54, 42),
      blue,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.32, 88, size.width * 0.28, 42),
      blue,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.18, 190, size.width * 0.34, 42),
      blue,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.48, 0)
        ..lineTo(size.width * 0.60, 0)
        ..lineTo(size.width * 0.54, 42)
        ..lineTo(size.width * 0.48, 42)
        ..close(),
      orange,
    );
    canvas.drawRect(Rect.fromLTWH(size.width * 0.51, 42, 12, 178), green);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.48, 144)
        ..lineTo(size.width * 0.86, 144)
        ..lineTo(size.width * 0.90, 192)
        ..lineTo(size.width * 0.54, 192)
        ..close(),
      orange,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
