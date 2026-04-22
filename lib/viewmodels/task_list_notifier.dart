import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../repositories/task_repository.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

final sharedPreferencesLoaderProvider = Provider<SharedPreferencesLoader>((ref) {
  return SharedPreferences.getInstance;
});

final taskListErrorProvider = StateProvider<String?>((ref) {
  return null;
});

final taskListProvider =
    StateNotifierProvider<TaskListNotifier, AsyncValue<List<Task>>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final sharedPreferencesLoader = ref.watch(sharedPreferencesLoaderProvider);
  return TaskListNotifier(
    repository: repository,
    sharedPreferencesLoader: sharedPreferencesLoader,
    ref: ref,
  );
});

final todoTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskListProvider).valueOrNull ?? const <Task>[];
  return tasks.where((task) => task.status == TaskStatus.todo).toList();
});

final inProgressTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskListProvider).valueOrNull ?? const <Task>[];
  return tasks.where((task) => task.status == TaskStatus.inProgress).toList();
});

final doneTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskListProvider).valueOrNull ?? const <Task>[];
  return tasks.where((task) => task.status == TaskStatus.done).toList();
});

class TaskListNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  TaskListNotifier({
    required TaskRepository repository,
    required SharedPreferencesLoader sharedPreferencesLoader,
    Ref? ref,
  }) : _ref = ref,
       _repository = repository,
       _sharedPreferencesLoader = sharedPreferencesLoader,
       super(const AsyncValue.loading()) {
    _initialization = _loadTasks();
  }

  static const storageKey = 'sprint_tasks';

  final Ref? _ref;
  final TaskRepository _repository;
  final SharedPreferencesLoader _sharedPreferencesLoader;
  SharedPreferences? _sharedPreferences;
  late final Future<void> _initialization;

  Future<void> get initialization => _initialization;

  Future<void> addTask(Task task) async {
    final tasks = _repository.addTask(task);
    state = AsyncValue.data(tasks);
    await _persistTasks(tasks);
  }

  Future<void> updateTask(Task task) async {
    final tasks = _repository.updateTask(task);
    state = AsyncValue.data(tasks);
    await _persistTasks(tasks);
  }

  Future<void> deleteTask(String id) async {
    final tasks = _repository.deleteTask(id);
    state = AsyncValue.data(tasks);
    await _persistTasks(tasks);
  }

  Future<void> moveTask(String id, TaskStatus newStatus) async {
    final tasks = _repository.moveTask(id, newStatus);
    state = AsyncValue.data(tasks);
    await _persistTasks(tasks);
  }

  Future<void> _loadTasks() async {
    try {
      final sharedPreferences = await _getSharedPreferences();
      final json = sharedPreferences.getString(storageKey);

      if (json == null || json.isEmpty) {
        state = AsyncValue.data(_repository.getTasks());
        return;
      }

      final decoded = jsonDecode(json) as List<dynamic>;
      final loadedTasks = decoded
          .map((item) => Task.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
      final nextTasks = loadedTasks.isEmpty ? Task.sampleTasks() : loadedTasks;

      state = AsyncValue.data(_repository.replaceTasks(nextTasks));
    } catch (_) {
      state = AsyncValue.data(_repository.getTasks());
      _reportError('タスクの読み込みに失敗しました');
    }
  }

  Future<void> _persistTasks(List<Task> tasks) async {
    try {
      final sharedPreferences = await _getSharedPreferences();
      final json = jsonEncode(tasks.map((task) => task.toJson()).toList());
      await sharedPreferences.setString(storageKey, json);
    } catch (_) {
      _reportError('タスクの保存に失敗しました');
    }
  }

  Future<SharedPreferences> _getSharedPreferences() async {
    final sharedPreferences = _sharedPreferences;
    if (sharedPreferences != null) {
      return sharedPreferences;
    }

    final loadedSharedPreferences = await _sharedPreferencesLoader();
    _sharedPreferences = loadedSharedPreferences;
    return loadedSharedPreferences;
  }

  void _reportError(String message) {
    _ref?.read(taskListErrorProvider.notifier).state = message;
  }
}
