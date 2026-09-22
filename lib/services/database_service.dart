import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../models/metric.dart';
import '../models/summary.dart';

class DatabaseService {
  static Database? _database;
  static const String _tasksTable = 'tasks';
  static const String _metricsTable = 'metrics';
  static const String _summariesTable = 'summaries';
  static const Uuid _uuid = Uuid();

  static Future<void> init() async {
    if (_database != null) return;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'study_io.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tasksTable (
            id TEXT PRIMARY KEY,
            title TEXT,
            description TEXT,
            date TEXT,
            priority INTEGER,
            completed INTEGER,
            startTime TEXT,
            endTime TEXT,
            pomodoroCount INTEGER,
            timeSpent INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE $_metricsTable (
            id TEXT PRIMARY KEY,
            date TEXT,
            studyMinutes INTEGER,
            pauses INTEGER,
            environment TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE $_summariesTable (
            id TEXT PRIMARY KEY,
            title TEXT,
            content TEXT,
            createdAt TEXT,
            description TEXT,
            audioPath TEXT
          )
        ''');
      },
    );
  }

  static Future<List<Task>> getTasksByDate(DateTime date) async {
    final dayStart = DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String();
    final dayEnd = DateTime(
      date.year,
      date.month,
      date.day,
    ).add(const Duration(days: 1)).toIso8601String();

    final maps = await _database!.query(
      _tasksTable,
      where: 'date >= ? AND date < ?',
      whereArgs: [dayStart, dayEnd],
      orderBy: 'date ASC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  static Future<List<Task>> getTasks() async {
    final maps = await _database!.query(_tasksTable, orderBy: 'date ASC');
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  static Future<void> insertTask(Task task) async {
    final data = task.toMap();
    data['id'] = _uuid.v4();
    await _database!.insert(
      _tasksTable,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateTask(Task task) async {
    if (task.id == null) throw Exception("Task ID is null, cannot update.");
    await _database!.update(
      _tasksTable,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  static Future<void> deleteTask(String id) async {
    await _database!.delete(_tasksTable, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> updateTaskTime(
    String taskId,
    int? pomodoroCount,
    int? timeSpent,
  ) async {
    final updates = <String, dynamic>{};
    if (pomodoroCount != null) updates['pomodoroCount'] = pomodoroCount;
    if (timeSpent != null) updates['timeSpent'] = timeSpent;

    if (updates.isNotEmpty) {
      await _database!.update(
        _tasksTable,
        updates,
        where: 'id = ?',
        whereArgs: [taskId],
      );
    }
  }

  static Future<Task?> getTaskById(String id) async {
    final maps = await _database!.query(
      _tasksTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    return null;
  }

  static Future<List<Metric>> getMetrics() async {
    final maps = await _database!.query(_metricsTable);
    return maps.map((map) => Metric.fromMap(map)).toList();
  }

  static Future<void> saveMetric(Metric metric) async {
    final data = metric.toMap();
    if (metric.id == null) {
      data['id'] = _uuid.v4();
      await _database!.insert(
        _metricsTable,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await _database!.update(
        _metricsTable,
        data,
        where: 'id = ?',
        whereArgs: [metric.id],
      );
    }
  }

  static Future<void> deleteMetric(String id) async {
    await _database!.delete(_metricsTable, where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Summary>> getSummaries() async {
    final maps = await _database!.query(
      _summariesTable,
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Summary.fromMap(map)).toList();
  }

  static Future<void> saveSummary(Summary summary) async {
    final data = summary.toMap();
    if (summary.id == null) {
      data['id'] = _uuid.v4();
      await _database!.insert(
        _summariesTable,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await _database!.update(
        _summariesTable,
        data,
        where: 'id = ?',
        whereArgs: [summary.id],
      );
    }
  }

  static Future<void> deleteSummary(String id) async {
    await _database!.delete(_summariesTable, where: 'id = ?', whereArgs: [id]);
  }
}
