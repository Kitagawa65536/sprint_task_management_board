import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../models/task.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return TaskRepository(database);
});

class TaskRepository {
  TaskRepository(this._database);

  final AppDatabase _database;

  Future<List<Task>> getTasks() {
    return _database.getTasks();
  }

  Future<List<Task>> replaceTasks(List<Task> tasks) async {
    await _database.replaceTasks(tasks);
    return getTasks();
  }

  Future<List<Task>> seedIfEmpty(List<Task> tasks) async {
    if (!await _database.isEmpty()) {
      return getTasks();
    }

    await _database.replaceTasks(tasks);
    return getTasks();
  }

  Future<List<Task>> addTask(Task task) async {
    await _database.insertTask(task);
    return getTasks();
  }

  Future<List<Task>> updateTask(Task task) async {
    await _database.updateTaskRecord(task);
    return getTasks();
  }

  Future<List<Task>> deleteTask(String id) async {
    await _database.deleteTaskRecord(id);
    return getTasks();
  }

  Future<List<Task>> moveTask(String id, TaskStatus newStatus) async {
    await _database.moveTaskRecord(id, newStatus);
    return getTasks();
  }
}
