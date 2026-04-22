import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/task.dart';
import 'viewmodels/task_form_notifier.dart';
import 'viewmodels/task_list_notifier.dart';

void main() {
  runApp(const SprintBoardApp());
}

class SprintBoardApp extends StatelessWidget {
  const SprintBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'スプリントボード',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const SprintBoardPage(),
    );
  }
}

class SprintBoardPage extends ConsumerWidget {
  const SprintBoardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('スプリントボード')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTaskCreatePage(context, ref),
        child: const Icon(Icons.add),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final boardSpacing = 56.0;
          final fittedColumnWidth = (constraints.maxWidth - boardSpacing) / 3;
          final columnWidth = constraints.maxWidth > 420
              ? fittedColumnWidth.clamp(220.0, 320.0)
              : constraints.maxWidth * 0.85;

          return SizedBox(
            height: constraints.maxHeight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BoardColumn(
                    title: '未着手',
                    width: columnWidth,
                    tasksProvider: todoTasksProvider,
                    onTaskTap: (task) => _showTaskDetails(context, ref, task),
                    onTaskLongPress: (task) =>
                        _showTaskActions(context, ref, task),
                  ),
                  const SizedBox(width: 12),
                  _BoardColumn(
                    title: '進行中',
                    width: columnWidth,
                    tasksProvider: inProgressTasksProvider,
                    onTaskTap: (task) => _showTaskDetails(context, ref, task),
                    onTaskLongPress: (task) =>
                        _showTaskActions(context, ref, task),
                  ),
                  const SizedBox(width: 12),
                  _BoardColumn(
                    title: '完了',
                    width: columnWidth,
                    tasksProvider: doneTasksProvider,
                    onTaskTap: (task) => _showTaskDetails(context, ref, task),
                    onTaskLongPress: (task) =>
                        _showTaskActions(context, ref, task),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openTaskCreatePage(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.of(context).push<_TaskFormResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _TaskFormPage(),
      ),
    );

    if (result == null || !context.mounted) {
      return;
    }

    ref
        .read(taskListProvider.notifier)
        .addTask(
          Task(
            title: result.title,
            description: result.description,
            status: result.status,
            priority: result.priority,
          ),
        );

    _showSnackBar(context, 'タスクを追加しました');
  }

  Future<void> _showTaskDetails(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(task.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.description ?? '説明はありません'),
              const SizedBox(height: 16),
              Text('ステータス: ${_statusLabel(task.status)}'),
              const SizedBox(height: 8),
              Text('優先度: ${_priorityLabel(task.priority)}'),
              const SizedBox(height: 8),
              Text('作成日時: ${_formatCreatedAt(task.createdAt)}'),
              const SizedBox(height: 20),
              const Text(
                'ステータス変更',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SegmentedButton<TaskStatus>(
                segments: const [
                  ButtonSegment(value: TaskStatus.todo, label: Text('未着手')),
                  ButtonSegment(
                    value: TaskStatus.inProgress,
                    label: Text('進行中'),
                  ),
                  ButtonSegment(value: TaskStatus.done, label: Text('完了')),
                ],
                selected: {task.status},
                onSelectionChanged: (selected) {
                  final nextStatus = selected.first;
                  Navigator.of(dialogContext).pop();
                  _updateTaskStatus(context, ref, task, nextStatus);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _openTaskEditPage(context, ref, task);
              },
              child: const Text('編集'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _confirmAndDeleteTask(context, ref, task);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('削除'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openTaskEditPage(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final result = await Navigator.of(context).push<_TaskFormResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _TaskFormPage(task: task),
      ),
    );

    if (result == null || !context.mounted) {
      return;
    }

    ref
        .read(taskListProvider.notifier)
        .updateTask(
          task.copyWith(
            title: result.title,
            description: result.description,
            priority: result.priority,
            status: result.status,
          ),
        );

    _showSnackBar(context, 'タスクを更新しました');
  }

  Future<void> _confirmAndDeleteTask(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('タスクを削除'),
          content: const Text('このタスクを削除しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    ref.read(taskListProvider.notifier).deleteTask(task.id);
    _showSnackBar(context, 'タスクを削除しました');
  }

  Future<void> _showTaskActions(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final nextStatuses = TaskStatus.values
        .where((status) => status != task.status)
        .toList();

    final selectedStatus = await showModalBottomSheet<TaskStatus>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text(task.title), subtitle: const Text('移動先を選択')),
              for (final status in nextStatuses)
                ListTile(
                  leading: const Icon(Icons.swap_horiz),
                  title: Text('${_statusActionLabel(status)}に移動'),
                  onTap: () => Navigator.of(sheetContext).pop(status),
                ),
            ],
          ),
        );
      },
    );

    if (!context.mounted) {
      return;
    }

    if (selectedStatus != null) {
      _updateTaskStatus(context, ref, task, selectedStatus);
    }
  }

  void _updateTaskStatus(
    BuildContext context,
    WidgetRef ref,
    Task task,
    TaskStatus nextStatus,
  ) {
    if (task.status == nextStatus) {
      return;
    }

    ref.read(taskListProvider.notifier).moveTask(task.id, nextStatus);
    _showSnackBar(context, 'タスクを${_statusLabel(nextStatus)}に変更しました');
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BoardColumn extends ConsumerWidget {
  const _BoardColumn({
    required this.title,
    required this.width,
    required this.tasksProvider,
    required this.onTaskTap,
    required this.onTaskLongPress,
  });

  final String title;
  final double width;
  final ProviderListenable<List<Task>> tasksProvider;
  final ValueChanged<Task> onTaskTap;
  final ValueChanged<Task> onTaskLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      color: Colors.indigo.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Text(
                        'タスクがありません',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.separated(
                      itemCount: tasks.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final task = tasks[index];

                        return _TaskCard(
                          task: task,
                          priorityColor: _priorityColor(task.priority),
                          priorityLabel: _priorityLabel(task.priority),
                          createdAtLabel: _formatCreatedAt(task.createdAt),
                          onTap: () => onTaskTap(task),
                          onLongPress: () => onTaskLongPress(task),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskFormPage extends ConsumerWidget {
  _TaskFormPage({this.task});

  final Task? task;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(taskFormProvider(task));

    return Scaffold(
      appBar: AppBar(
        title: Text(task == null ? 'タスク追加' : 'タスク編集'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: formState.isValid
                  ? () => _saveTask(context, ref)
                  : null,
              child: const Text('保存'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                initialValue: formState.title,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'タイトル',
                  border: OutlineInputBorder(),
                ),
                onChanged: ref
                    .read(taskFormProvider(task).notifier)
                    .updateTitle,
                validator: (value) {
                  final title = value?.trim() ?? '';
                  if (title.isEmpty) {
                    return 'タイトルは必須です';
                  }
                  if (title.length > 50) {
                    return 'タイトルは50文字以内で入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: formState.description,
                maxLength: 200,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: '説明文',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: ref
                    .read(taskFormProvider(task).notifier)
                    .updateDescription,
                validator: (value) {
                  final description = value?.trim() ?? '';
                  if (description.length > 200) {
                    return '説明文は200文字以内で入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                '優先度',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SegmentedButton<TaskPriority>(
                segments: const [
                  ButtonSegment(value: TaskPriority.low, label: Text('低')),
                  ButtonSegment(value: TaskPriority.medium, label: Text('中')),
                  ButtonSegment(value: TaskPriority.high, label: Text('高')),
                ],
                selected: {formState.priority},
                onSelectionChanged: (selected) {
                  ref
                      .read(taskFormProvider(task).notifier)
                      .updatePriority(selected.first);
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'ステータス',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SegmentedButton<TaskStatus>(
                segments: const [
                  ButtonSegment(value: TaskStatus.todo, label: Text('未着手')),
                  ButtonSegment(
                    value: TaskStatus.inProgress,
                    label: Text('進行中'),
                  ),
                  ButtonSegment(value: TaskStatus.done, label: Text('完了')),
                ],
                selected: {formState.status},
                onSelectionChanged: (selected) {
                  ref
                      .read(taskFormProvider(task).notifier)
                      .updateStatus(selected.first);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveTask(BuildContext context, WidgetRef ref) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final formState = ref.read(taskFormProvider(task));
    final description = formState.description.trim();

    Navigator.of(context).pop(
      _TaskFormResult(
        title: formState.title.trim(),
        description: description.isEmpty ? null : description,
        status: formState.status,
        priority: formState.priority,
      ),
    );
  }
}

class _TaskFormResult {
  const _TaskFormResult({
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
  });

  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.priorityColor,
    required this.priorityLabel,
    required this.createdAtLabel,
    required this.onTap,
    required this.onLongPress,
  });

  final Task task;
  final Color priorityColor;
  final String priorityLabel;
  final String createdAtLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                task.description ?? '説明はありません',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  priorityLabel,
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                createdAtLabel,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _priorityColor(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.low:
      return Colors.green;
    case TaskPriority.medium:
      return Colors.amber;
    case TaskPriority.high:
      return Colors.red;
  }
}

String _formatCreatedAt(DateTime dateTime) {
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');

  return '$month/$day $hour:$minute';
}

String _priorityLabel(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.low:
      return 'Low';
    case TaskPriority.medium:
      return 'Medium';
    case TaskPriority.high:
      return 'High';
  }
}

String _statusLabel(TaskStatus status) {
  switch (status) {
    case TaskStatus.todo:
      return '未着手';
    case TaskStatus.inProgress:
      return '進行中';
    case TaskStatus.done:
      return '完了';
  }
}

String _statusActionLabel(TaskStatus status) {
  switch (status) {
    case TaskStatus.todo:
      return '未着手';
    case TaskStatus.inProgress:
      return '進行中';
    case TaskStatus.done:
      return '完了';
  }
}
