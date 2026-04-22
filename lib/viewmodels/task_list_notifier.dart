import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../repositories/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

final taskListProvider = StateNotifierProvider<TaskListNotifier, List<Task>>((
  ref,
) {
  final repository = ref.watch(taskRepositoryProvider);
  return TaskListNotifier(repository);
});

final todoTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskListProvider);
  return tasks.where((task) => task.status == TaskStatus.todo).toList();
});

final inProgressTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskListProvider);
  return tasks.where((task) => task.status == TaskStatus.inProgress).toList();
});

final doneTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskListProvider);
  return tasks.where((task) => task.status == TaskStatus.done).toList();
});

class TaskListNotifier extends StateNotifier<List<Task>> {
  TaskListNotifier(this._repository) : super(_repository.getTasks());

  final TaskRepository _repository;

  void addTask(Task task) {
    state = _repository.addTask(task);
  }

  void updateTask(Task task) {
    state = _repository.updateTask(task);
  }

  void deleteTask(String id) {
    state = _repository.deleteTask(id);
  }

  void moveTask(String id, TaskStatus newStatus) {
    state = _repository.moveTask(id, newStatus);
  }
}
