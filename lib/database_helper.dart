import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'todo_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE lists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        listId INTEGER NOT NULL,
        title TEXT NOT NULL,
        isCompleted INTEGER NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (listId) REFERENCES lists (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertList(String title) async {
    Database db = await database;
    return await db.insert('lists', {'title': title, 'synced': 0});
  }

  Future<List<Map<String, dynamic>>> getLists() async {
    Database db = await database;
    return await db.query('lists');
  }

  Future<int> deleteList(int id) async {
    Database db = await database;
    return await db.delete('lists', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertTask(int listId, String title) async {
    Database db = await database;
    return await db.insert('tasks', {'listId': listId, 'title': title, 'isCompleted': 0, 'synced': 0});
  }

  Future<List<Map<String, dynamic>>> getTasks(int listId) async {
    Database db = await database;
    return await db.query('tasks', where: 'listId = ?', whereArgs: [listId]);
  }

  Future<int> deleteTask(int id) async {
    Database db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateTaskCompletion(int id, bool isCompleted) async {
    Database db = await database;
    return await db.update('tasks', {'isCompleted': isCompleted ? 1 : 0, 'synced': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateTaskTitle(int id, String title) async {
    Database db = await database;
    return await db.update('tasks', {'title': title, 'synced': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedLists() async {
    Database db = await database;
    return await db.query('lists', where: 'synced = ?', whereArgs: [0]);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedTasks() async {
    Database db = await database;
    return await db.query('tasks', where: 'synced = ?', whereArgs: [0]);
  }

  Future<int> markListAsSynced(int id) async {
    Database db = await database;
    return await db.update('lists', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> markTaskAsSynced(int id) async {
    Database db = await database;
    return await db.update('tasks', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }
}
