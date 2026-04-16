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
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE audit_writeups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plant_number TEXT NOT NULL,
        date_detected TEXT NOT NULL,
        detected_by TEXT NOT NULL,
        unit_number TEXT NOT NULL,
        model_number TEXT NOT NULL,
        department TEXT NOT NULL,
        non_conformance_no TEXT NOT NULL,
        category TEXT NOT NULL,
        new_code_reference TEXT NOT NULL,
        code_class TEXT NOT NULL,
        code_description TEXT NOT NULL,
        repeat_violation INTEGER NOT NULL DEFAULT 0,
        times_repeat INTEGER NOT NULL DEFAULT 0,
        grounding INTEGER NOT NULL DEFAULT 0,
        solar INTEGER NOT NULL DEFAULT 0,
        panel_board INTEGER NOT NULL DEFAULT 0,
        appliance_install INTEGER NOT NULL DEFAULT 0,
        rvia_id INTEGER,
        rvia_type TEXT,
        rvia_description TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Since the schema changed significantly during development,
    // rebuild the table cleanly for version 3.
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS audit_writeups');
      await _onCreate(db, newVersion);
    }
  }

  Future<int> insertWriteup(AuditWriteup writeup) async {
    final db = await database;
    return await db.insert(
      'audit_writeups',
      writeup.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AuditWriteup>> getWriteupsByPlant(String plantNumber) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'audit_writeups',
      where: 'plant_number = ?',
      whereArgs: [plantNumber],
      orderBy: 'date_detected DESC',
    );

    return maps.map((map) => AuditWriteup.fromMap(map)).toList();
  }

  Future<List<AuditWriteup>> getAllWriteups() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'audit_writeups',
      orderBy: 'date_detected DESC',
    );

    return maps.map((map) => AuditWriteup.fromMap(map)).toList();
  }

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
