import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const SprintBoardPage(),
    );
  }
}

class SprintBoardPage extends ConsumerStatefulWidget {
  const SprintBoardPage({super.key});

  @override
  ConsumerState<SprintBoardPage> createState() => _SprintBoardPageState();
}

class _SprintBoardPageState extends ConsumerState<SprintBoardPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(taskListErrorProvider, (previous, next) {
      if (!kDebugMode || next == null) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(next)));

      ref.read(taskListErrorProvider.notifier).state = null;
    });

    final taskListState = ref.watch(taskListProvider);
    final totalTasks = taskListState.valueOrNull?.length ?? 0;
    final searchQuery = ref.watch(searchQueryProvider);
    final filterPriority = ref.watch(filterPriorityProvider);
    final filteredTasks = ref.watch(filteredTasksProvider);
    final hasActiveFilter = ref.watch(hasActiveTaskFilterProvider);

    if (_searchController.text != searchQuery) {
      _searchController.value = TextEditingValue(
        text: searchQuery,
        selection: TextSelection.collapsed(offset: searchQuery.length),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('スプリントボード'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(92),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).state = value;
                  },
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'タスクを検索...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchQueryProvider.notifier).state = '';
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _PriorityFilterChip(
                        label: 'すべて',
                        selected: filterPriority == null,
                        onSelected: () {
                          ref.read(filterPriorityProvider.notifier).state =
                              null;
                        },
                      ),
                      const SizedBox(width: 8),
                      _PriorityFilterChip(
                        label: '高',
                        selected: filterPriority == TaskPriority.high,
                        onSelected: () {
                          ref.read(filterPriorityProvider.notifier).state =
                              TaskPriority.high;
                        },
                      ),
                      const SizedBox(width: 8),
                      _PriorityFilterChip(
                        label: '中',
                        selected: filterPriority == TaskPriority.medium,
                        onSelected: () {
                          ref.read(filterPriorityProvider.notifier).state =
                              TaskPriority.medium;
                        },
                      ),
                      const SizedBox(width: 8),
                      _PriorityFilterChip(
                        label: '低',
                        selected: filterPriority == TaskPriority.low,
                        onSelected: () {
                          ref.read(filterPriorityProvider.notifier).state =
                              TaskPriority.low;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '（$totalTasks）',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTaskCreatePage(context, ref),
        child: const Icon(Icons.add),
      ),
      body: taskListState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: CircularProgressIndicator()),
        data: (_) {
          if (hasActiveFilter && filteredTasks.isEmpty) {
            return const Center(child: Text('該当するタスクがありません'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final boardSpacing = 56.0;
              final fittedColumnWidth =
                  (constraints.maxWidth - boardSpacing) / 3;
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
                        status: TaskStatus.todo,
                        width: columnWidth,
                        tasksProvider: todoTasksProvider,
                        onTaskTap: (task) =>
                            _showTaskDetails(context, ref, task),
                        onTaskAccepted: (task) => _updateTaskStatus(
                          context,
                          ref,
                          task,
                          TaskStatus.todo,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _BoardColumn(
                        title: '進行中',
                        status: TaskStatus.inProgress,
                        width: columnWidth,
                        tasksProvider: inProgressTasksProvider,
                        onTaskTap: (task) =>
                            _showTaskDetails(context, ref, task),
                        onTaskAccepted: (task) => _updateTaskStatus(
                          context,
                          ref,
                          task,
                          TaskStatus.inProgress,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _BoardColumn(
                        title: '完了',
                        status: TaskStatus.done,
                        width: columnWidth,
                        tasksProvider: doneTasksProvider,
                        onTaskTap: (task) =>
                            _showTaskDetails(context, ref, task),
                        onTaskAccepted: (task) => _updateTaskStatus(
                          context,
                          ref,
                          task,
                          TaskStatus.done,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openTaskCreatePage(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.of(context).push<_TaskFormResult>(
      _TaskFormPageRoute(
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
      _TaskFormPageRoute(
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
    _showSnackBar(context, '${task.title}を${_statusLabel(nextStatus)}に移動しました');
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BoardColumn extends ConsumerStatefulWidget {
  const _BoardColumn({
    required this.title,
    required this.status,
    required this.width,
    required this.tasksProvider,
    required this.onTaskTap,
    required this.onTaskAccepted,
  });

  final String title;
  final TaskStatus status;
  final double width;
  final ProviderListenable<List<Task>> tasksProvider;
  final ValueChanged<Task> onTaskTap;
  final ValueChanged<Task> onTaskAccepted;

  @override
  ConsumerState<_BoardColumn> createState() => _BoardColumnState();
}

class _BoardColumnState extends ConsumerState<_BoardColumn> {
  bool _isHighlighted = false;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(widget.tasksProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final headerColor = _statusColor(widget.status, colorScheme);
    final containerColor = colorScheme.surfaceContainerLowest;

    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: headerColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: headerColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${tasks.length}件)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: headerColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: DragTarget<Task>(
                onWillAcceptWithDetails: (details) {
                  final canAccept = details.data.status != widget.status;
                  setState(() {
                    _isHighlighted = canAccept;
                  });
                  return canAccept;
                },
                onLeave: (_) {
                  if (_isHighlighted) {
                    setState(() {
                      _isHighlighted = false;
                    });
                  }
                },
                onAcceptWithDetails: (details) {
                  widget.onTaskAccepted(details.data);
                  setState(() {
                    _isHighlighted = false;
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: _isHighlighted
                          ? Colors.blue.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isHighlighted
                            ? Colors.blue.shade300
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: tasks.isEmpty
                        ? _EmptyColumnPlaceholder(status: widget.status)
                        : ListView.builder(
                            padding: const EdgeInsets.all(6),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final task = tasks[index];

                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index == tasks.length - 1 ? 0 : 10,
                                ),
                                child: _TaskCard(
                                  task: task,
                                  cardWidth: widget.width - 36,
                                  priorityColor: _priorityColor(task.priority),
                                  priorityLabel: _priorityLabel(task.priority),
                                  priorityIcon: _priorityIcon(task.priority),
                                  createdAtLabel: _formatCreatedAt(
                                    task.createdAt,
                                  ),
                                  onTap: () => widget.onTaskTap(task),
                                ),
                              );
                            },
                          ),
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

class _TaskFormPage extends ConsumerStatefulWidget {
  const _TaskFormPage({this.task});

  final Task? task;

  @override
  ConsumerState<_TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends ConsumerState<_TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final FocusNode _titleFocusNode;
  late final FocusNode _descriptionFocusNode;

  @override
  void initState() {
    super.initState();
    _titleFocusNode = FocusNode();
    _descriptionFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
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
                focusNode: _titleFocusNode,
                maxLength: 50,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'タイトル',
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (_) {
                  _descriptionFocusNode.requestFocus();
                },
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
                focusNode: _descriptionFocusNode,
                maxLength: 200,
                minLines: 4,
                maxLines: 6,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: '説明文',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (_) => _saveTask(context, ref),
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
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final formState = ref.read(taskFormProvider(widget.task));
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

class _PriorityFilterChip extends StatelessWidget {
  const _PriorityFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.cardWidth,
    required this.priorityColor,
    required this.priorityLabel,
    required this.priorityIcon,
    required this.createdAtLabel,
    required this.onTap,
  });

  final Task task;
  final double cardWidth;
  final Color priorityColor;
  final String priorityLabel;
  final IconData priorityIcon;
  final String createdAtLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final card = Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        splashColor: priorityColor.withValues(alpha: 0.12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: priorityColor, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    decoration: task.status == TaskStatus.done
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.status == TaskStatus.done
                        ? colorScheme.onSurfaceVariant
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  task.description ?? '説明はありません',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(priorityIcon, size: 14, color: priorityColor),
                      const SizedBox(width: 4),
                      Text(
                        priorityLabel,
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  createdAtLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return LongPressDraggable<Task>(
      data: task,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Opacity(
        opacity: 0.7,
        child: Material(
          elevation: 4,
          color: Colors.transparent,
          child: SizedBox(width: cardWidth, child: card),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.7, child: card),
      child: card,
    );
  }
}

class _TaskFormPageRoute<T> extends MaterialPageRoute<T> {
  _TaskFormPageRoute({required super.builder, super.fullscreenDialog});

  @override
  Duration get transitionDuration => const Duration(milliseconds: 260);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 220);
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

Color _statusColor(TaskStatus status, ColorScheme colorScheme) {
  switch (status) {
    case TaskStatus.todo:
      return colorScheme.outline;
    case TaskStatus.inProgress:
      return colorScheme.primary;
    case TaskStatus.done:
      return Colors.green.shade700;
  }
}

IconData _priorityIcon(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.low:
      return Icons.arrow_downward_rounded;
    case TaskPriority.medium:
      return Icons.remove_rounded;
    case TaskPriority.high:
      return Icons.arrow_upward_rounded;
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

class _EmptyColumnPlaceholder extends StatelessWidget {
  const _EmptyColumnPlaceholder({required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = _statusColor(status, colorScheme);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _emptyStateIcon(status),
              size: 40,
              color: accentColor.withValues(alpha: 0.9),
            ),
            const SizedBox(height: 12),
            Text(
              _emptyStateTitle(status),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _emptyStateMessage(status),
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _emptyStateIcon(TaskStatus status) {
  switch (status) {
    case TaskStatus.todo:
      return Icons.inbox_outlined;
    case TaskStatus.inProgress:
      return Icons.timelapse_rounded;
    case TaskStatus.done:
      return Icons.task_alt_rounded;
  }
}

String _emptyStateTitle(TaskStatus status) {
  switch (status) {
    case TaskStatus.todo:
      return 'タスクがありません';
    case TaskStatus.inProgress:
      return 'タスクがありません';
    case TaskStatus.done:
      return 'タスクがありません';
  }
}

String _emptyStateMessage(TaskStatus status) {
  switch (status) {
    case TaskStatus.todo:
      return '新しいタスクを追加するとここに表示されます。';
    case TaskStatus.inProgress:
      return '着手したタスクをここへ移動して進捗を管理できます。';
    case TaskStatus.done:
      return '完了したタスクはここに蓄積されます。';
  }
}
