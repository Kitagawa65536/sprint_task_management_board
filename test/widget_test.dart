// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sprint_task_management_board/main.dart';
import 'package:sprint_task_management_board/models/task.dart';

void main() {
  testWidgets('Sprint board shows kanban columns and sample tasks', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SprintBoardApp());

    expect(find.text('スプリントボード'), findsOneWidget);
    expect(find.text('未着手'), findsOneWidget);
    expect(find.text('進行中'), findsOneWidget);
    expect(find.text('完了'), findsOneWidget);
    expect(find.text('ログイン画面のUI確認'), findsOneWidget);
    expect(find.text('API接続エラーの調査'), findsOneWidget);
    expect(find.text('High'), findsNWidgets(2));
    expect(find.text('04/20 09:00'), findsOneWidget);
  });

  testWidgets('Task status changes from detail dialog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SprintBoardApp());

    await tester.tap(find.text('ログイン画面のUI確認'));
    await tester.pumpAndSettle();

    expect(find.text('ステータス: 未着手'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<TaskStatus>),
        matching: find.text('進行中'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('タスクを進行中に変更しました'), findsOneWidget);
    expect(find.text('未着手'), findsOneWidget);
  });

  testWidgets('User can add a task from fullscreen dialog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SprintBoardApp());

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('タスク追加'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '保存'))
          .onPressed,
      isNull,
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'タイトル'), '新規タスク');
    await tester.pump();

    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '保存'))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(find.text('タスクを追加しました'), findsOneWidget);
    expect(find.text('新規タスク'), findsOneWidget);
  });
}
