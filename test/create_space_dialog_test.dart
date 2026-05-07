import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ottersync/components/Spaces/CreateSpaceDialog.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

void main() {
  testWidgets('create space dialog validates required fields', (tester) async {
    WorkspaceCreateDialogResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                result = await showModalBottomSheet<WorkspaceCreateDialogResult>(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const CreateSpaceDialog(),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '创建空间'));
    await tester.pump();

    expect(find.text('请输入空间名称'), findsOneWidget);
    expect(find.text('请输入空间 Key'), findsOneWidget);
    expect(result, isNull);
  });

  testWidgets('create space dialog auto generates key from name', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Material(child: CreateSpaceDialog())),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'ottersync');
    await tester.pump();

    expect(find.text('OTTE'), findsOneWidget);
  });

  test('workspace key generator builds readable uppercase keys', () {
    expect(generateWorkspaceKey('毛球'), 'MQMQ');
    expect(generateWorkspaceKey('智能终端开发课程设计'), 'ZNZD');
    expect(generateWorkspaceKey('ottersync'), 'OTTE');
    expect(generateWorkspaceKey('A'), 'AAAA');
  });
}
