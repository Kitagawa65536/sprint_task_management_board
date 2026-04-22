import 'package:uuid/uuid.dart';

enum TaskStatus { todo, inProgress, done }

enum TaskPriority { low, medium, high }

class Task {
  Task({
    String? id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime createdAt;

  static List<Task> sampleTasks() {
    return [
      Task(
        title: 'ログイン画面のUI確認',
        description: '入力フォームとボタン配置を最終確認する',
        status: TaskStatus.todo,
        priority: TaskPriority.high,
        createdAt: DateTime(2026, 4, 20, 9),
      ),
      Task(
        title: 'バックログの優先度見直し',
        description: '次スプリント向けにチケットを再整理する',
        status: TaskStatus.inProgress,
        priority: TaskPriority.medium,
        createdAt: DateTime(2026, 4, 20, 10, 30),
      ),
      Task(
        title: 'API接続エラーの調査',
        description: 'タイムアウト発生条件を確認する',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        createdAt: DateTime(2026, 4, 20, 13),
      ),
      Task(
        title: 'バーンダウンチャート更新',
        description: '最新の完了数を反映する',
        status: TaskStatus.done,
        priority: TaskPriority.low,
        createdAt: DateTime(2026, 4, 21, 11),
      ),
      Task(
        title: 'レビューコメントの対応',
        description: '命名とレイアウト崩れを修正する',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        createdAt: DateTime(2026, 4, 21, 14, 15),
      ),
      Task(
        title: 'リリースノート草案作成',
        description: null,
        status: TaskStatus.done,
        priority: TaskPriority.low,
        createdAt: DateTime(2026, 4, 22, 9, 45),
      ),
    ];
  }
}
