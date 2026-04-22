import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';

final taskFormProvider = StateNotifierProvider.autoDispose
    .family<TaskFormNotifier, TaskFormState, Task?>((ref, task) {
      return TaskFormNotifier(TaskFormState.fromTask(task));
    });

class TaskFormNotifier extends StateNotifier<TaskFormState> {
  TaskFormNotifier(super.state);

  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  void updatePriority(TaskPriority priority) {
    state = state.copyWith(priority: priority);
  }

  void updateStatus(TaskStatus status) {
    state = state.copyWith(status: status);
  }
}

class TaskFormState {
  const TaskFormState({
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
  });

  factory TaskFormState.fromTask(Task? task) {
    return TaskFormState(
      title: task?.title ?? '',
      description: task?.description ?? '',
      priority: task?.priority ?? TaskPriority.medium,
      status: task?.status ?? TaskStatus.todo,
    );
  }

  final String title;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;

  bool get isValid {
    final trimmedTitle = title.trim();
    final trimmedDescription = description.trim();

    return trimmedTitle.isNotEmpty &&
        trimmedTitle.length <= 50 &&
        trimmedDescription.length <= 200;
  }

  TaskFormState copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
  }) {
    return TaskFormState(
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
    );
  }
}
