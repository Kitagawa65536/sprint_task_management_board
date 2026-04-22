import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprint_task_management_board/database/app_database.dart';
import 'package:sprint_task_management_board/models/task.dart';
import 'package:sprint_task_management_board/repositories/task_repository.dart';
import 'package:sprint_task_management_board/viewmodels/task_list_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TaskListNotifier', () {
    test(
      'initializes from repository state when no saved tasks exist',
      () async {
        SharedPreferences.setMockInitialValues({});
        final database = AppDatabase.memory();
        addTearDown(database.close);
        final repository = TaskRepository(database);
        await repository.replaceTasks([_task(id: 'todo-1')]);
        final notifier = TaskListNotifier(
          repository: repository,
          legacyPreferencesLoader: SharedPreferences.getInstance,
          ref: null,
        );

        await notifier.initialization;

        expect(notifier.state.requireValue.map((task) => task.id), ['todo-1']);
      },
    );

    test('loads tasks from shared preferences on startup', () async {
      SharedPreferences.setMockInitialValues({
        TaskListNotifier.storageKey:
            '[{"id":"saved-1","title":"saved","description":"memo","status":"done","priority":"high","createdAt":"2026-04-22T09:00:00.000"}]',
      });
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final notifier = TaskListNotifier(
        repository: TaskRepository(database),
        legacyPreferencesLoader: SharedPreferences.getInstance,
        ref: null,
      );

      await notifier.initialization;

      expect(notifier.state.requireValue.map((task) => task.id), ['saved-1']);
      expect(notifier.state.requireValue.single.status, TaskStatus.done);

      final sharedPreferences = await SharedPreferences.getInstance();
      expect(sharedPreferences.getString(TaskListNotifier.storageKey), isNull);
    });

    test('keeps legacy data when drift seeding fails', () async {
      SharedPreferences.setMockInitialValues({
        TaskListNotifier.storageKey:
            '[{"id":"saved-1","title":"saved","description":"memo","status":"done","priority":"high","createdAt":"2026-04-22T09:00:00.000"}]',
      });
      final repository = _ThrowingTaskRepository(
        initialTasks: const <Task>[],
        throwOnSeedIfEmpty: true,
      );
      final notifier = TaskListNotifier(
        repository: repository,
        legacyPreferencesLoader: SharedPreferences.getInstance,
        ref: null,
      );

      await expectLater(notifier.initialization, throwsException);

      final sharedPreferences = await SharedPreferences.getInstance();
      expect(
        sharedPreferences.getString(TaskListNotifier.storageKey),
        isNotNull,
      );
    });

    test('addTask prepends a new task to state', () async {
      SharedPreferences.setMockInitialValues({});
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final repository = TaskRepository(database);
      await repository.replaceTasks([_task(id: 'existing')]);
      final notifier = TaskListNotifier(
        repository: repository,
        legacyPreferencesLoader: SharedPreferences.getInstance,
        ref: null,
      );

      await notifier.initialization;

      await notifier.addTask(_task(id: 'new-task', status: TaskStatus.done));

      expect(notifier.state.requireValue.map((task) => task.id), [
        'new-task',
        'existing',
      ]);
      expect(notifier.state.requireValue.first.status, TaskStatus.done);
    });

    test('updateTask refreshes the matching task', () async {
      SharedPreferences.setMockInitialValues({});
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final repository = TaskRepository(database);
      await repository.replaceTasks([_task(id: 'target'), _task(id: 'other')]);
      final notifier = TaskListNotifier(
        repository: repository,
        legacyPreferencesLoader: SharedPreferences.getInstance,
        ref: null,
      );

      await notifier.initialization;

      await notifier.updateTask(
        _task(
          id: 'target',
          title: 'updated title',
          description: 'updated description',
          priority: TaskPriority.high,
          status: TaskStatus.inProgress,
        ),
      );

      expect(notifier.state.requireValue.first.title, 'updated title');
      expect(
        notifier.state.requireValue.first.description,
        'updated description',
      );
      expect(notifier.state.requireValue.first.priority, TaskPriority.high);
      expect(notifier.state.requireValue.first.status, TaskStatus.inProgress);
      expect(notifier.state.requireValue.last.title, 'task-other');
    });

    test('deleteTask removes the matching task from state', () async {
      SharedPreferences.setMockInitialValues({});
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final repository = TaskRepository(database);
      await repository.replaceTasks([
        _task(id: 'delete-me'),
        _task(id: 'keep-me'),
      ]);
      final notifier = TaskListNotifier(
        repository: repository,
        legacyPreferencesLoader: SharedPreferences.getInstance,
        ref: null,
      );

      await notifier.initialization;

      await notifier.deleteTask('delete-me');

      expect(notifier.state.requireValue.map((task) => task.id), ['keep-me']);
    });

    test('moveTask changes the target task status', () async {
      SharedPreferences.setMockInitialValues({});
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final repository = TaskRepository(database);
      await repository.replaceTasks([_task(id: 'move-me')]);
      final notifier = TaskListNotifier(
        repository: repository,
        legacyPreferencesLoader: SharedPreferences.getInstance,
        ref: null,
      );

      await notifier.initialization;

      await notifier.moveTask('move-me', TaskStatus.done);

      expect(notifier.state.requireValue.single.status, TaskStatus.done);
      expect(notifier.state.requireValue.single.title, 'task-move-me');
    });

    test('persists updated tasks to drift database', () async {
      SharedPreferences.setMockInitialValues({});
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final repository = TaskRepository(database);
      await repository.replaceTasks([_task(id: 'existing')]);
      final notifier = TaskListNotifier(
        repository: repository,
        legacyPreferencesLoader: SharedPreferences.getInstance,
        ref: null,
      );

      await notifier.initialization;
      await notifier.addTask(_task(id: 'saved-task', status: TaskStatus.done));

      final savedTasks = await repository.getTasks();

      expect(savedTasks.map((task) => task.id), contains('saved-task'));
    });

    test('reports an error and keeps state when addTask fails', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = _ThrowingTaskRepository(
        initialTasks: [_task(id: 'existing')],
        throwOnAddTask: true,
      );
      final container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWithValue(repository),
          sharedPreferencesLoaderProvider.overrideWithValue(
            SharedPreferences.getInstance,
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(taskListProvider.notifier).initialization;

      await expectLater(
        container
            .read(taskListProvider.notifier)
            .addTask(_task(id: 'new-task')),
        throwsException,
      );

      expect(
        container.read(taskListProvider).requireValue.map((task) => task.id),
        ['existing'],
      );
      expect(container.read(taskListErrorProvider), 'タスクの保存に失敗しました');
    });
  });

  group('task list providers', () {
    test('filtered providers return tasks by status', () async {
      SharedPreferences.setMockInitialValues({});
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final repository = TaskRepository(database);
      await repository.replaceTasks([
        _task(id: 'todo-1', status: TaskStatus.todo),
        _task(id: 'progress-1', status: TaskStatus.inProgress),
        _task(id: 'done-1', status: TaskStatus.done),
        _task(id: 'todo-2', status: TaskStatus.todo),
      ]);
      final container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWithValue(repository),
          sharedPreferencesLoaderProvider.overrideWithValue(
            SharedPreferences.getInstance,
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(taskListProvider.notifier).initialization;

      expect(container.read(todoTasksProvider).map((task) => task.id), [
        'todo-1',
        'todo-2',
      ]);
      expect(container.read(inProgressTasksProvider).map((task) => task.id), [
        'progress-1',
      ]);
      expect(container.read(doneTasksProvider).map((task) => task.id), [
        'done-1',
      ]);
    });

    test('search matches both title and description', () async {
      SharedPreferences.setMockInitialValues({});
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final repository = TaskRepository(database);
      await repository.replaceTasks([
        _task(id: 'title-hit', title: 'ログイン画面', description: '説明'),
        _task(id: 'desc-hit', title: '別タスク', description: 'ログを確認する'),
        _task(id: 'miss', title: '別件', description: '対象外'),
      ]);
      final container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWithValue(repository),
          sharedPreferencesLoaderProvider.overrideWithValue(
            SharedPreferences.getInstance,
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(taskListProvider.notifier).initialization;
      container.read(searchQueryProvider.notifier).state = 'ログ';

      expect(container.read(filteredTasksProvider).map((task) => task.id), [
        'title-hit',
        'desc-hit',
      ]);
    });

    test('search and priority filter are combined with AND', () async {
      SharedPreferences.setMockInitialValues({});
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final repository = TaskRepository(database);
      await repository.replaceTasks([
        _task(id: 'match', title: 'ログ調査', priority: TaskPriority.high),
        _task(id: 'query-only', title: 'ログ収集', priority: TaskPriority.low),
        _task(
          id: 'priority-only',
          title: '別作業',
          description: '対象外',
          priority: TaskPriority.high,
        ),
      ]);
      final container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWithValue(repository),
          sharedPreferencesLoaderProvider.overrideWithValue(
            SharedPreferences.getInstance,
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(taskListProvider.notifier).initialization;
      container.read(searchQueryProvider.notifier).state = 'ログ';
      container.read(filterPriorityProvider.notifier).state = TaskPriority.high;

      expect(container.read(filteredTasksProvider).map((task) => task.id), [
        'match',
      ]);
    });
  });
}

Task _task({
  required String id,
  String? title,
  String? description = 'description',
  TaskStatus status = TaskStatus.todo,
  TaskPriority priority = TaskPriority.medium,
}) {
  return Task(
    id: id,
    title: title ?? 'task-$id',
    description: description,
    status: status,
    priority: priority,
    createdAt: DateTime(2026, 4, 22, 9),
  );
}

class _ThrowingTaskRepository implements TaskRepository {
  _ThrowingTaskRepository({
    required List<Task> initialTasks,
    this.throwOnSeedIfEmpty = false,
    this.throwOnAddTask = false,
  }) : _tasks = List<Task>.from(initialTasks);

  final List<Task> _tasks;
  final bool throwOnSeedIfEmpty;
  final bool throwOnAddTask;

  @override
  Future<List<Task>> addTask(Task task) async {
    if (throwOnAddTask) {
      throw Exception('add failed');
    }

    _tasks.insert(0, task);
    return List<Task>.unmodifiable(_tasks);
  }

  @override
  Future<List<Task>> deleteTask(String id) async {
    _tasks.removeWhere((task) => task.id == id);
    return List<Task>.unmodifiable(_tasks);
  }

  @override
  Future<List<Task>> getTasks() async {
    return List<Task>.unmodifiable(_tasks);
  }

  @override
  Future<List<Task>> moveTask(String id, TaskStatus newStatus) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(status: newStatus);
    }
    return List<Task>.unmodifiable(_tasks);
  }

  @override
  Future<List<Task>> replaceTasks(List<Task> tasks) async {
    _tasks
      ..clear()
      ..addAll(tasks);
    return List<Task>.unmodifiable(_tasks);
  }

  @override
  Future<List<Task>> seedIfEmpty(List<Task> tasks) async {
    if (throwOnSeedIfEmpty) {
      throw Exception('seed failed');
    }
    if (_tasks.isEmpty) {
      _tasks.addAll(tasks);
    }
    return List<Task>.unmodifiable(_tasks);
  }

  @override
  Future<List<Task>> updateTask(Task task) async {
    final index = _tasks.indexWhere((currentTask) => currentTask.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    }
    return List<Task>.unmodifiable(_tasks);
  }
}
