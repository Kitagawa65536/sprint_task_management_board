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
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _tasks.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final task = _tasks[index];

          return Card(
            child: ListTile(
              leading: Icon(Icons.flag, color: _priorityColor(task.priority)),
              title: Text(task.title),
              subtitle: Text(_statusLabel(task.status)),
            ),
          );
        },
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

  String _statusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }
}
