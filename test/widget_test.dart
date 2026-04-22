// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sprint_task_management_board/database/app_database.dart';
import 'package:sprint_task_management_board/main.dart';
import 'package:sprint_task_management_board/models/task.dart';
import 'package:sprint_task_management_board/repositories/task_repository.dart';
import 'package:sprint_task_management_board/viewmodels/task_list_notifier.dart';

void main() {
  testWidgets('Sprint board shows kanban columns and sample tasks', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase.memory();
    addTearDown(database.close);
    await tester.pumpWidget(
      SprintBoardApp(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      ),
    );
    await tester.pumpAndSettle();

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
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase.memory();
    addTearDown(database.close);
    await tester.pumpWidget(
      SprintBoardApp(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      ),
    );
    await tester.pumpAndSettle();

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

    expect(find.text('ログイン画面のUI確認を進行中に移動しました'), findsOneWidget);
    expect(find.text('未着手'), findsOneWidget);
  });

  testWidgets('User can add a task from fullscreen dialog', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase.memory();
    addTearDown(database.close);
    await tester.pumpWidget(
      SprintBoardApp(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      ),
    );
    await tester.pumpAndSettle();

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

  testWidgets('User can edit a task from detail dialog', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase.memory();
    addTearDown(database.close);
    await tester.pumpWidget(
      SprintBoardApp(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ログイン画面のUI確認'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, '編集'));
    await tester.pumpAndSettle();

    expect(find.text('タスク編集'), findsOneWidget);
    expect(find.text('ログイン画面のUI確認'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'タイトル'),
      'ログイン画面の文言調整',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '説明文'),
      'フォーム文言と案内テキストを更新する',
    );
    await tester.pump();

    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<TaskStatus>),
        matching: find.text('完了'),
      ),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(find.text('タスクを更新しました'), findsOneWidget);
    expect(find.text('ログイン画面の文言調整'), findsOneWidget);
    expect(find.text('ログイン画面のUI確認'), findsNothing);
  });

  testWidgets('User can delete tasks and empty column shows placeholder', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase.memory();
    addTearDown(database.close);
    await tester.pumpWidget(
      SprintBoardApp(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('バーンダウンチャート更新'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '削除').last);
    await tester.pumpAndSettle();

    expect(find.text('タスクを削除しました'), findsOneWidget);
    expect(find.text('バーンダウンチャート更新'), findsNothing);

    await tester.tap(find.text('リリースノート草案作成'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '削除').last);
    await tester.pumpAndSettle();

    expect(find.text('リリースノート草案作成'), findsNothing);
    expect(find.text('タスクがありません'), findsOneWidget);
  });

  testWidgets('Search matches task descriptions and clear button resets it', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      TaskListNotifier.storageKey:
          '[{"id":"desc-1","title":"別タスク","description":"ログを確認する","status":"todo","priority":"medium","createdAt":"2026-04-22T09:00:00.000"}]',
    });
    final database = AppDatabase.memory();
    addTearDown(database.close);
    await tester.pumpWidget(
      SprintBoardApp(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ログ');
    await tester.pumpAndSettle();

    expect(find.text('別タスク'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('ログイン画面のUI確認'), findsNothing);
    expect(find.text('別タスク'), findsOneWidget);
  });

  testWidgets('Search and priority filter narrow results together', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final repository = TaskRepository(database);
    await repository.replaceTasks([
      Task(
        id: 'match',
        title: 'ログ調査',
        description: '詳細',
        status: TaskStatus.todo,
        priority: TaskPriority.high,
        createdAt: DateTime(2026, 4, 22, 9),
      ),
      Task(
        id: 'query-only',
        title: 'ログ収集',
        description: '詳細',
        status: TaskStatus.todo,
        priority: TaskPriority.low,
        createdAt: DateTime(2026, 4, 22, 10),
      ),
    ]);
    await tester.pumpWidget(
      SprintBoardApp(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ログ');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, '高'));
    await tester.pumpAndSettle();

    expect(find.text('ログ調査'), findsOneWidget);
    expect(find.text('ログ収集'), findsNothing);
  });

  testWidgets('Search field keeps keyboard deletion working on desktop', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase.memory();
    addTearDown(database.close);
    await tester.pumpWidget(
      SprintBoardApp(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ログ');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();

    expect(find.text('ロ'), findsWidgets);
  });
}
