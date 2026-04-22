import 'package:flutter/material.dart';

import 'models/task.dart';

void main() {
  runApp(const SprintBoardApp());
}

class SprintBoardApp extends StatelessWidget {
  const SprintBoardApp({super.key});

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

class SprintBoardPage extends StatefulWidget {
  const SprintBoardPage({super.key});

  @override
  State<SprintBoardPage> createState() => _SprintBoardPageState();
}

class _SprintBoardPageState extends State<SprintBoardPage> {
  late final List<Task> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = Task.sampleTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('スプリントボード')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openTaskCreatePage,
        child: const Icon(Icons.add),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columnWidth = constraints.maxWidth > 420
              ? 320.0
              : constraints.maxWidth * 0.85;

          return SizedBox(
            height: constraints.maxHeight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBoardColumn(
                    title: '未着手',
                    status: TaskStatus.todo,
                    width: columnWidth,
                  ),
                  const SizedBox(width: 12),
                  _buildBoardColumn(
                    title: '進行中',
                    status: TaskStatus.inProgress,
                    width: columnWidth,
                  ),
                  const SizedBox(width: 12),
                  _buildBoardColumn(
                    title: '完了',
                    status: TaskStatus.done,
                    width: columnWidth,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openTaskCreatePage() async {
    final result = await Navigator.of(context).push<_TaskFormResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const _TaskFormPage(),
      ),
    );

    if (result == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    final createdTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: result.title,
      description: result.description,
      status: result.status,
      priority: result.priority,
      createdAt: DateTime.now(),
    );

    setState(() {
      _tasks.insert(0, createdTask);
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('タスクを追加しました')));
  }

  Future<void> _showTaskDetails(Task task) async {
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
                  _updateTaskStatus(task, nextStatus);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _openTaskEditPage(task);
              },
              child: const Text('編集'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _confirmAndDeleteTask(task);
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

  Future<void> _openTaskEditPage(Task task) async {
    final result = await Navigator.of(context).push<_TaskFormResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _TaskFormPage(task: task),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      task
        ..title = result.title
        ..description = result.description
        ..priority = result.priority
        ..status = result.status;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('タスクを更新しました')));
  }

  Future<void> _confirmAndDeleteTask(Task task) async {
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

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() {
      _tasks.remove(task);
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('タスクを削除しました')));
  }

  Future<void> _showTaskActions(Task task) async {
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

    if (selectedStatus != null) {
      _updateTaskStatus(task, selectedStatus);
    }
  }

  void _updateTaskStatus(Task task, TaskStatus nextStatus) {
    if (task.status == nextStatus) {
      return;
    }

    setState(() {
      task.status = nextStatus;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('タスクを${_statusLabel(nextStatus)}に変更しました')),
      );
  }

  Widget _buildBoardColumn({
    required String title,
    required TaskStatus status,
    required double width,
  }) {
    final tasks = _tasks.where((task) => task.status == status).toList();

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
                          onTap: () => _showTaskDetails(task),
                          onLongPress: () => _showTaskActions(task),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
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
}

class _TaskFormPage extends StatefulWidget {
  const _TaskFormPage({this.task});

  final Task? task;

  @override
  State<_TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<_TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskPriority _priority = TaskPriority.medium;
  TaskStatus _status = TaskStatus.todo;

  bool get _isFormValid {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    return title.isNotEmpty && title.length <= 50 && description.length <= 200;
  }

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task != null) {
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _priority = task.priority;
      _status = task.status;
    }
    _titleController.addListener(_onFormChanged);
    _descriptionController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _titleController
      ..removeListener(_onFormChanged)
      ..dispose();
    _descriptionController
      ..removeListener(_onFormChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'タスク追加' : 'タスク編集'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _isFormValid ? _saveTask : null,
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
                controller: _titleController,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'タイトル',
                  border: OutlineInputBorder(),
                ),
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
                controller: _descriptionController,
                maxLength: 200,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: '説明文',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
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
                selected: {_priority},
                onSelectionChanged: (selected) {
                  setState(() {
                    _priority = selected.first;
                  });
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
                selected: {_status},
                onSelectionChanged: (selected) {
                  setState(() {
                    _status = selected.first;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onFormChanged() {
    setState(() {});
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final description = _descriptionController.text.trim();

    Navigator.of(context).pop(
      _TaskFormResult(
        title: _titleController.text.trim(),
        description: description.isEmpty ? null : description,
        status: _status,
        priority: _priority,
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
