import 'package:flutter_test/flutter_test.dart';
import 'package:sprint_task_management_board/models/task.dart';
import 'package:sprint_task_management_board/repositories/task_repository.dart';

void main() {
  group('TaskRepository', () {
    test('returns an unmodifiable snapshot of tasks', () {
      final repository = TaskRepository(initialTasks: [_task(id: 'todo-1')]);

      final tasks = repository.getTasks();

      expect(() => tasks.add(_task(id: 'todo-2')), throwsUnsupportedError);
      expect(repository.getTasks(), hasLength(1));
    });

    test('addTask inserts a task at the top of the list', () {
      final repository = TaskRepository(
        initialTasks: [
          _task(id: 'existing-1'),
          _task(id: 'existing-2'),
        ],
      );
      final newTask = _task(id: 'new-task', status: TaskStatus.done);

      final tasks = repository.addTask(newTask);

      expect(tasks.map((task) => task.id), [
        'new-task',
        'existing-1',
        'existing-2',
      ]);
      expect(tasks.first.status, TaskStatus.done);
    });

    test('updateTask replaces the matching task only', () {
      final repository = TaskRepository(
        initialTasks: [
          _task(id: 'target'),
          _task(id: 'other'),
        ],
      );

      final tasks = repository.updateTask(
        _task(
          id: 'target',
          title: 'updated',
          description: 'updated description',
          priority: TaskPriority.high,
          status: TaskStatus.inProgress,
        ),
      );

      expect(tasks.first.title, 'updated');
      expect(tasks.first.description, 'updated description');
      expect(tasks.first.priority, TaskPriority.high);
      expect(tasks.first.status, TaskStatus.inProgress);
      expect(tasks.last.title, 'task-other');
    });

    test('deleteTask removes the matching task by id', () {
      final repository = TaskRepository(
        initialTasks: [
          _task(id: 'delete-me'),
          _task(id: 'keep-me'),
        ],
      );

      final tasks = repository.deleteTask('delete-me');

      expect(tasks.map((task) => task.id), ['keep-me']);
    });

    test('moveTask updates only the task status', () {
      final repository = TaskRepository(initialTasks: [_task(id: 'move-me')]);

      final tasks = repository.moveTask('move-me', TaskStatus.done);

      expect(tasks.single.status, TaskStatus.done);
      expect(tasks.single.title, 'task-move-me');
      expect(tasks.single.priority, TaskPriority.medium);
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
