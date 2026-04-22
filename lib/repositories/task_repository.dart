import '../models/task.dart';

class TaskRepository {
  TaskRepository({List<Task>? initialTasks})
    : _tasks = List<Task>.from(initialTasks ?? Task.sampleTasks());

  final List<Task> _tasks;

  List<Task> getTasks() => List.unmodifiable(_tasks);

  List<Task> addTask(Task task) {
    _tasks.insert(0, task);
    return getTasks();
  }

  List<Task> updateTask(Task task) {
    final index = _tasks.indexWhere((currentTask) => currentTask.id == task.id);

    if (index == -1) {
      return getTasks();
    }

    _tasks[index] = task;
    return getTasks();
  }

  List<Task> deleteTask(String id) {
    _tasks.removeWhere((task) => task.id == id);
    return getTasks();
  }

  List<Task> moveTask(String id, TaskStatus newStatus) {
    final index = _tasks.indexWhere((task) => task.id == id);

    if (index == -1) {
      return getTasks();
    }

    _tasks[index] = _tasks[index].copyWith(status: newStatus);
    return getTasks();
  }
}
