import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprint_task_management_board/models/task.dart';
import 'package:sprint_task_management_board/viewmodels/task_form_notifier.dart';

void main() {
  group('TaskFormNotifier', () {
    test('starts with the provided task values', () {
      final notifier = TaskFormNotifier(TaskFormState.fromTask(_task()));

      expect(notifier.state.title, 'existing title');
      expect(notifier.state.description, 'existing description');
      expect(notifier.state.priority, TaskPriority.high);
      expect(notifier.state.status, TaskStatus.inProgress);
    });

    test('updates each field through notifier methods', () {
      final notifier = TaskFormNotifier(TaskFormState.fromTask(null));

      notifier.updateTitle('new title');
      notifier.updateDescription('new description');
      notifier.updatePriority(TaskPriority.low);
      notifier.updateStatus(TaskStatus.done);

      expect(notifier.state.title, 'new title');
      expect(notifier.state.description, 'new description');
      expect(notifier.state.priority, TaskPriority.low);
      expect(notifier.state.status, TaskStatus.done);
    });

    test('isValid requires a non-empty title and max lengths', () {
      final notifier = TaskFormNotifier(TaskFormState.fromTask(null));

      expect(notifier.state.isValid, isFalse);

      notifier.updateTitle('valid title');
      expect(notifier.state.isValid, isTrue);

      notifier.updateTitle(' ');
      expect(notifier.state.isValid, isFalse);

      notifier.updateTitle('a' * 51);
      expect(notifier.state.isValid, isFalse);

      notifier.updateTitle('valid title');
      notifier.updateDescription('a' * 201);
      expect(notifier.state.isValid, isFalse);
    });
  });

  group('taskFormProvider', () {
    test('builds default state for a new task', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final subscription = container.listen(
        taskFormProvider(null),
        (previous, next) {},
      );
      addTearDown(subscription.close);

      final state = container.read(taskFormProvider(null));

      expect(state.title, '');
      expect(state.description, '');
      expect(state.priority, TaskPriority.medium);
      expect(state.status, TaskStatus.todo);
      expect(state.isValid, isFalse);
    });

    test('builds state from the supplied task', () {
      final task = _task();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final subscription = container.listen(
        taskFormProvider(task),
        (previous, next) {},
      );
      addTearDown(subscription.close);

      final state = container.read(taskFormProvider(task));

      expect(state.title, 'existing title');
      expect(state.description, 'existing description');
      expect(state.priority, TaskPriority.high);
      expect(state.status, TaskStatus.inProgress);
      expect(state.isValid, isTrue);
    });
  });
}

Task _task() {
  return Task(
    id: 'task-1',
    title: 'existing title',
    description: 'existing description',
    status: TaskStatus.inProgress,
    priority: TaskPriority.high,
    createdAt: DateTime(2026, 4, 22, 9),
  );
}
