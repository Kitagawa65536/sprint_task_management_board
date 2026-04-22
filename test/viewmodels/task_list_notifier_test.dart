import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprint_task_management_board/models/task.dart';
import 'package:sprint_task_management_board/repositories/task_repository.dart';
import 'package:sprint_task_management_board/viewmodels/task_list_notifier.dart';

void main() {
  group('TaskListNotifier', () {
    test('initializes from repository state', () {
      final notifier = TaskListNotifier(
        TaskRepository(initialTasks: [_task(id: 'todo-1')]),
      );

      expect(notifier.state.map((task) => task.id), ['todo-1']);
    });

    test('addTask prepends a new task to state', () {
      final notifier = TaskListNotifier(
        TaskRepository(initialTasks: [_task(id: 'existing')]),
      );

      notifier.addTask(_task(id: 'new-task', status: TaskStatus.done));

      expect(notifier.state.map((task) => task.id), ['new-task', 'existing']);
      expect(notifier.state.first.status, TaskStatus.done);
    });

    test('updateTask refreshes the matching task', () {
      final notifier = TaskListNotifier(
        TaskRepository(
          initialTasks: [
            _task(id: 'target'),
            _task(id: 'other'),
          ],
        ),
      );

      notifier.updateTask(
        _task(
          id: 'target',
          title: 'updated title',
          description: 'updated description',
          priority: TaskPriority.high,
          status: TaskStatus.inProgress,
        ),
      );

      expect(notifier.state.first.title, 'updated title');
      expect(notifier.state.first.description, 'updated description');
      expect(notifier.state.first.priority, TaskPriority.high);
      expect(notifier.state.first.status, TaskStatus.inProgress);
      expect(notifier.state.last.title, 'task-other');
    });

    test('deleteTask removes the matching task from state', () {
      final notifier = TaskListNotifier(
        TaskRepository(
          initialTasks: [
            _task(id: 'delete-me'),
            _task(id: 'keep-me'),
          ],
        ),
      );

      notifier.deleteTask('delete-me');

      expect(notifier.state.map((task) => task.id), ['keep-me']);
    });

    test('moveTask changes the target task status', () {
      final notifier = TaskListNotifier(
        TaskRepository(initialTasks: [_task(id: 'move-me')]),
      );

      notifier.moveTask('move-me', TaskStatus.done);

      expect(notifier.state.single.status, TaskStatus.done);
      expect(notifier.state.single.title, 'task-move-me');
    });
  });

  group('task list providers', () {
    test('filtered providers return tasks by status', () {
      final repository = TaskRepository(
        initialTasks: [
          _task(id: 'todo-1', status: TaskStatus.todo),
          _task(id: 'progress-1', status: TaskStatus.inProgress),
          _task(id: 'done-1', status: TaskStatus.done),
          _task(id: 'todo-2', status: TaskStatus.todo),
        ],
      );
      final container = ProviderContainer(
        overrides: [taskRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

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
