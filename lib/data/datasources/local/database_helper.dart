import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE ratings (
      id TEXT PRIMARY KEY,
      tourPointId TEXT NOT NULL,
      userId TEXT NOT NULL,
      overallRating REAL NOT NULL,
      accessibilityRating REAL NOT NULL,
      cleanlinessRating REAL NOT NULL,
      infrastructureRating REAL NOT NULL,
      safetyRating REAL NOT NULL,
      experienceRating REAL NOT NULL,
      comment TEXT,
      dateCreated TEXT NOT NULL,
      isRecommended INTEGER NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE visited_points (
      tourPointId TEXT PRIMARY KEY
    )
    ''');
  }
}
