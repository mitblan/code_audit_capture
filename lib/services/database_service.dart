import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/audit_writeup.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'code_audit_capture.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE audit_writeups (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  plant_number TEXT NOT NULL,
  code_reference TEXT NOT NULL,
  discipline TEXT NOT NULL,
  description TEXT NOT NULL,
  created_at TEXT NOT NULL,
  rvia_id INTEGER,
  rvia_type TEXT,
  rvia_description TEXT
)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE audit_writeups ADD COLUMN rvia_id INTEGER;
      ''');
      await db.execute('''
        ALTER TABLE audit_writeups ADD COLUMN rvia_type TEXT;
      ''');
      await db.execute('''
        ALTER TABLE audit_writeups ADD COLUMN rvia_description TEXT;
      ''');
    }
  }

  // Insert a write-up
  Future<int> insertWriteup(AuditWriteup writeup) async {
    final db = await database;
    return await db.insert(
      'audit_writeups',
      writeup.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Retrieve write-ups for a specific plant
  Future<List<AuditWriteup>> getWriteupsByPlant(String plantNumber) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'audit_writeups',
      where: 'plant_number = ?',
      whereArgs: [plantNumber],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => AuditWriteup.fromMap(map)).toList();
  }

  Future<List<AuditWriteup>> getAllWriteups() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'audit_writeups',
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => AuditWriteup.fromMap(map)).toList();
  }

  // Delete a write-up
  Future<int> deleteWriteup(int id) async {
    final db = await database;
    return await db.delete('audit_writeups', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateWriteup(AuditWriteup writeup) async {
    final db = await database;

    return await db.update(
      'audit_writeups',
      writeup.toMap(),
      where: 'id = ?',
      whereArgs: [writeup.id],
    );
  }
}
