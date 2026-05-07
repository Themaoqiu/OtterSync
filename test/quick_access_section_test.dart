import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ottersync/components/Home/QuickAccessSection.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

void main() {
  testWidgets(
    'compact quick access cards do not overflow at tight heights',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            textTheme: const TextTheme(
              titleMedium: TextStyle(fontSize: 18, height: 1.5),
              bodyMedium: TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: QuickAccessSection(
                  items: const [
                    QuickAccessItem(
                      title: '总览',
                      subtitle: 'overview',
                      icon: Icons.home_outlined,
                      color: Color(0xFFE9F2FF),
                    ),
                    QuickAccessItem(
                      title: 'OT面板',
                      subtitle: 'ottersync',
                      icon: Icons.dashboard_outlined,
                      color: Color(0xFFE9F2FF),
                    ),
                    QuickAccessItem(
                      title: '团队',
                      subtitle: 'members',
                      icon: Icons.group_outlined,
                      color: Color(0xFFE9F2FF),
                    ),
                  ],
                  onItemTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final titleBox = tester.renderObject<RenderBox>(find.text('OT面板'));
      final subtitleBox = tester.renderObject<RenderBox>(find.text('ottersync'));
      final textColumnBox = tester.renderObject<RenderBox>(
        find.ancestor(
          of: find.text('OT面板'),
          matching: find.byType(Column),
        ).first,
      );

      expect(
        titleBox.size.height + 2 + subtitleBox.size.height,
        lessThanOrEqualTo(textColumnBox.size.height),
      );
    },
  );
}
