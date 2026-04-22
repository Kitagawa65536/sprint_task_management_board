import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/task.dart' as model;

part 'app_database.g.dart';

class TaskEntries extends Table {
  TextColumn get id => text()();

  TextColumn get title => text()();

  TextColumn get description => text().nullable()();

  TextColumn get status => text()();

  TextColumn get priority => text()();

  DateTimeColumn get createdAt => dateTime()();

  IntColumn get sortOrder => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [TaskEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  Future<List<model.Task>> getTasks() async {
    final rows = await (select(
      taskEntries,
    )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();
    return rows.map(_mapRowToTask).toList(growable: false);
  }

  Future<void> replaceTasks(List<model.Task> nextTasks) async {
    await transaction(() async {
      await delete(taskEntries).go();
      for (var index = 0; index < nextTasks.length; index++) {
        await into(taskEntries).insert(_toCompanion(nextTasks[index], index));
      }
    });
  }

  Future<void> insertTask(model.Task task) async {
    final minSortOrder = await _readMinSortOrder();
    await into(taskEntries).insert(_toCompanion(task, minSortOrder - 1));
  }

  Future<void> updateTaskRecord(model.Task task) async {
    final current = await _rowById(task.id);
    if (current == null) {
      return;
    }

    await update(taskEntries).replace(_toCompanion(task, current.sortOrder));
  }

  Future<void> deleteTaskRecord(String id) async {
    await (delete(taskEntries)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> moveTaskRecord(String id, model.TaskStatus newStatus) async {
    await ((update(taskEntries)..where((tbl) => tbl.id.equals(id))).write(
      TaskEntriesCompanion(status: Value(newStatus.name)),
    ));
  }

  Future<bool> isEmpty() async {
    final row =
        await (selectOnly(taskEntries)
              ..addColumns([taskEntries.id])
              ..limit(1))
            .getSingleOrNull();
    return row == null;
  }

  Future<int> _readMinSortOrder() async {
    final row =
        await (selectOnly(taskEntries)
              ..addColumns([taskEntries.sortOrder])
              ..orderBy([OrderingTerm.asc(taskEntries.sortOrder)])
              ..limit(1))
            .getSingleOrNull();
    return row?.read(taskEntries.sortOrder) ?? 0;
  }

  Future<TaskEntry?> _rowById(String id) {
    return (select(
      taskEntries,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  model.Task _mapRowToTask(TaskEntry row) {
    return model.Task(
      id: row.id,
      title: row.title,
      description: row.description,
      status: model.TaskStatus.values.byName(row.status),
      priority: model.TaskPriority.values.byName(row.priority),
      createdAt: row.createdAt,
    );
  }

  TaskEntriesCompanion _toCompanion(model.Task task, int sortOrder) {
    return TaskEntriesCompanion.insert(
      id: task.id,
      title: task.title,
      description: Value(task.description),
      status: task.status.name,
      priority: task.priority.name,
      createdAt: task.createdAt,
      sortOrder: sortOrder,
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'sprint_tasks.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
