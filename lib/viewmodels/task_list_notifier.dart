import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../repositories/task_repository.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

final sharedPreferencesLoaderProvider = Provider<SharedPreferencesLoader>((
  ref,
) {
  return SharedPreferences.getInstance;
});

final taskListErrorProvider = StateProvider<String?>((ref) {
  return null;
});

final searchQueryProvider = StateProvider<String>((ref) {
  return '';
});

final filterPriorityProvider = StateProvider<TaskPriority?>((ref) {
  return null;
});

final taskListProvider =
    StateNotifierProvider<TaskListNotifier, AsyncValue<List<Task>>>((ref) {
      final repository = ref.watch(taskRepositoryProvider);
      final sharedPreferencesLoader = ref.watch(
        sharedPreferencesLoaderProvider,
      );
      return TaskListNotifier(
        repository: repository,
        legacyPreferencesLoader: sharedPreferencesLoader,
        ref: ref,
      );
    });

final filteredTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskListProvider).valueOrNull ?? const <Task>[];
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final priority = ref.watch(filterPriorityProvider);

  return tasks.where((task) {
    final matchesQuery = query.isEmpty
        ? true
        : task.title.toLowerCase().contains(query) ||
              (task.description?.toLowerCase().contains(query) ?? false);
    final matchesPriority = priority == null || task.priority == priority;

    return matchesQuery && matchesPriority;
  }).toList();
});

final hasActiveTaskFilterProvider = Provider<bool>((ref) {
  final query = ref.watch(searchQueryProvider).trim();
  final priority = ref.watch(filterPriorityProvider);
  return query.isNotEmpty || priority != null;
});

final todoTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(filteredTasksProvider);
  return tasks.where((task) => task.status == TaskStatus.todo).toList();
});

final inProgressTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(filteredTasksProvider);
  return tasks.where((task) => task.status == TaskStatus.inProgress).toList();
});

final doneTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(filteredTasksProvider);
  return tasks.where((task) => task.status == TaskStatus.done).toList();
});

class TaskListNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  TaskListNotifier({
    required TaskRepository repository,
    required SharedPreferencesLoader legacyPreferencesLoader,
    Ref? ref,
  }) : _ref = ref,
       _repository = repository,
       _legacyPreferencesLoader = legacyPreferencesLoader,
       super(const AsyncValue.loading()) {
    _initialization = _loadTasks();
  }

  static const storageKey = 'sprint_tasks';

  final Ref? _ref;
  final TaskRepository _repository;
  final SharedPreferencesLoader _legacyPreferencesLoader;
  SharedPreferences? _legacyPreferences;
  late final Future<void> _initialization;

  Future<void> get initialization => _initialization;

  Future<void> addTask(Task task) async {
    try {
      final tasks = await _repository.addTask(task);
      state = AsyncValue.data(tasks);
    } catch (_) {
      _reportError('タスクの保存に失敗しました');
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      final tasks = await _repository.updateTask(task);
      state = AsyncValue.data(tasks);
    } catch (_) {
      _reportError('タスクの保存に失敗しました');
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      final tasks = await _repository.deleteTask(id);
      state = AsyncValue.data(tasks);
    } catch (_) {
      _reportError('タスクの保存に失敗しました');
      rethrow;
    }
  }

  Future<void> moveTask(String id, TaskStatus newStatus) async {
    try {
      final tasks = await _repository.moveTask(id, newStatus);
      state = AsyncValue.data(tasks);
    } catch (_) {
      _reportError('タスクの保存に失敗しました');
      rethrow;
    }
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _repository.getTasks();
      if (tasks.isNotEmpty) {
        state = AsyncValue.data(tasks);
        return;
      }

      final legacyTasks = await _loadLegacyTasks();
      final nextTasks = legacyTasks.isEmpty ? Task.sampleTasks() : legacyTasks;
      final seededTasks = await _repository.seedIfEmpty(nextTasks);
      if (legacyTasks.isNotEmpty) {
        await _clearLegacyTasks();
      }
      state = AsyncValue.data(seededTasks);
    } catch (_) {
      state = AsyncValue.data(
        await _repository.seedIfEmpty(Task.sampleTasks()),
      );
      _reportError('タスクの読み込みに失敗しました');
    }
  }

  Future<List<Task>> _loadLegacyTasks() async {
    try {
      final sharedPreferences = await _getLegacyPreferences();
      final json = sharedPreferences.getString(storageKey);
      if (json == null || json.isEmpty) {
        return const <Task>[];
      }

      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded
          .map((item) => Task.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return const <Task>[];
    }
  }

  Future<void> _clearLegacyTasks() async {
    final sharedPreferences = await _getLegacyPreferences();
    await sharedPreferences.remove(storageKey);
  }

  Future<SharedPreferences> _getLegacyPreferences() async {
    final sharedPreferences = _legacyPreferences;
    if (sharedPreferences != null) {
      return sharedPreferences;
    }

    final loadedSharedPreferences = await _legacyPreferencesLoader();
    _legacyPreferences = loadedSharedPreferences;
    return loadedSharedPreferences;
  }

  void _reportError(String message) {
    _ref?.read(taskListErrorProvider.notifier).state = message;
  }
}
