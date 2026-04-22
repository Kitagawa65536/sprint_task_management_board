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
              child: ListView.separated(
                itemCount: tasks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final task = tasks[index];

                  return _TaskCard(
                    task: task,
                    priorityColor: _priorityColor(task.priority),
                    priorityLabel: _priorityLabel(task.priority),
                    createdAtLabel: _formatCreatedAt(task.createdAt),
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
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.priorityColor,
    required this.priorityLabel,
    required this.createdAtLabel,
  });

  final Task task;
  final Color priorityColor;
  final String priorityLabel;
  final String createdAtLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
    );
  }
}
