import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DatabaseService {
  static Database? _database;

  // Método init para inicializar o banco de dados
  static Future<void> init() async {
    _database = await _initDatabase();
  }

  static Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'tasks.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            description TEXT,
            date TEXT,
            priority INTEGER,
            completed INTEGER,
            startTime TEXT,
            endTime TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE tasks ADD COLUMN startTime TEXT');
          await db.execute('ALTER TABLE tasks ADD COLUMN endTime TEXT');
        }
      },
    );
  }

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<List<Task>> getTasks() async {
    final db = await database;
    final maps = await db.query('tasks');
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  static Future<List<Task>> getTasksByDate(String date) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'date = ?',
      whereArgs: [date],
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  static Future<List<Task>> getTasksByDateRange(String startDate, String endDate) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  static Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap());
  }

  static Future<void> updateTaskCompletion(int id, bool completed) async {
    final db = await database;
    await db.update(
      'tasks',
      {'completed': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> updateTaskTime(int id, DateTime? startTime, DateTime? endTime) async {
    final db = await database;
    await db.update(
      'tasks',
      {
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}

