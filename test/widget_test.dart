// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:sprint_task_management_board/main.dart';

void main() {
  testWidgets('Sprint board shows sample tasks', (WidgetTester tester) async {
    await tester.pumpWidget(const SprintBoardApp());

    expect(find.text('スプリントボード'), findsOneWidget);
    expect(find.text('ログイン画面のUI確認'), findsOneWidget);
    expect(find.text('API接続エラーの調査'), findsOneWidget);
    expect(find.text('Done'), findsNWidgets(2));
  });
}
