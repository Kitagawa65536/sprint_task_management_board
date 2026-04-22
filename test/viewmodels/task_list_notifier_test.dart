import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprint_task_management_board/models/task.dart';
import 'package:sprint_task_management_board/repositories/task_repository.dart';
import 'package:sprint_task_management_board/viewmodels/task_list_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TaskListNotifier', () {
    test('initializes from repository state when no saved tasks exist', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = TaskListNotifier(
        repository: TaskRepository(initialTasks: [_task(id: 'todo-1')]),
        sharedPreferencesLoader: SharedPreferences.getInstance,
        ref: null,
      );

      await notifier.initialization;

      expect(notifier.state.requireValue.map((task) => task.id), ['todo-1']);
    });

    test('loads tasks from shared preferences on startup', () async {
      SharedPreferences.setMockInitialValues({
        TaskListNotifier.storageKey:
            '[{"id":"saved-1","title":"saved","description":"memo","status":"done","priority":"high","createdAt":"2026-04-22T09:00:00.000"}]',
      });
      final notifier = TaskListNotifier(
        repository: TaskRepository(initialTasks: [_task(id: 'fallback')]),
        sharedPreferencesLoader: SharedPreferences.getInstance,
        ref: null,
      );

      await notifier.initialization;

      expect(notifier.state.requireValue.map((task) => task.id), ['saved-1']);
      expect(notifier.state.requireValue.single.status, TaskStatus.done);
    });

    test('addTask prepends a new task to state', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = TaskListNotifier(
        repository: TaskRepository(initialTasks: [_task(id: 'existing')]),
        sharedPreferencesLoader: SharedPreferences.getInstance,
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
      final notifier = TaskListNotifier(
        repository: TaskRepository(
          initialTasks: [
            _task(id: 'target'),
            _task(id: 'other'),
          ],
        ),
        sharedPreferencesLoader: SharedPreferences.getInstance,
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
      expect(notifier.state.requireValue.first.description, 'updated description');
      expect(notifier.state.requireValue.first.priority, TaskPriority.high);
      expect(notifier.state.requireValue.first.status, TaskStatus.inProgress);
      expect(notifier.state.requireValue.last.title, 'task-other');
    });

    test('deleteTask removes the matching task from state', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = TaskListNotifier(
        repository: TaskRepository(
          initialTasks: [
            _task(id: 'delete-me'),
            _task(id: 'keep-me'),
          ],
        ),
        sharedPreferencesLoader: SharedPreferences.getInstance,
        ref: null,
      );

      await notifier.initialization;

      await notifier.deleteTask('delete-me');

      expect(notifier.state.requireValue.map((task) => task.id), ['keep-me']);
    });

    test('moveTask changes the target task status', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = TaskListNotifier(
        repository: TaskRepository(initialTasks: [_task(id: 'move-me')]),
        sharedPreferencesLoader: SharedPreferences.getInstance,
        ref: null,
      );

      await notifier.initialization;

      await notifier.moveTask('move-me', TaskStatus.done);

      expect(notifier.state.requireValue.single.status, TaskStatus.done);
      expect(notifier.state.requireValue.single.title, 'task-move-me');
    });

    test('persists updated tasks to shared preferences', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = TaskListNotifier(
        repository: TaskRepository(initialTasks: [_task(id: 'existing')]),
        sharedPreferencesLoader: SharedPreferences.getInstance,
        ref: null,
      );

      await notifier.initialization;
      await notifier.addTask(_task(id: 'saved-task', status: TaskStatus.done));

      final sharedPreferences = await SharedPreferences.getInstance();
      final savedValue = sharedPreferences.getString(TaskListNotifier.storageKey);

      expect(savedValue, isNotNull);
      expect(savedValue, contains('saved-task'));
    });
  });

  group('task list providers', () {
    test('filtered providers return tasks by status', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = TaskRepository(
        initialTasks: [
          _task(id: 'todo-1', status: TaskStatus.todo),
          _task(id: 'progress-1', status: TaskStatus.inProgress),
          _task(id: 'done-1', status: TaskStatus.done),
          _task(id: 'todo-2', status: TaskStatus.todo),
        ],
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
