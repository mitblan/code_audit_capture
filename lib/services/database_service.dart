import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/audit_writeup.dart';
import '../models/plant_session_summary.dart';
import '../models/rvia_code.dart';
import '../models/plant.dart';
import '../models/department.dart';
import '../models/plant_unit_prefix.dart';
import '../models/product_line.dart';
import '../models/plant_product_line.dart';
import '../models/plant_product_line_option.dart';

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
      version: 8,
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

    await db.execute('''
      CREATE TABLE rvia_codes (
        rvia_id INTEGER PRIMARY KEY,
        standard TEXT NOT NULL,
        sub_cat TEXT NOT NULL,
        type TEXT NOT NULL,
        discipline TEXT NOT NULL,
        description TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE plants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plant_number TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE departments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE plant_unit_prefixes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plant_number TEXT NOT NULL,
        prefix TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        UNIQUE(plant_number, prefix)
      )
    ''');

    await db.execute('''
      CREATE TABLE product_lines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE plant_product_lines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plant_number TEXT NOT NULL,
        product_line_id INTEGER NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        UNIQUE(plant_number, product_line_id)
      )
    ''');

    await _seedDefaultPlants(db);
    await _seedDefaultDepartments(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await db.execute('DROP TABLE IF EXISTS audit_writeups');
      await db.execute('DROP TABLE IF EXISTS rvia_codes');
      await db.execute('DROP TABLE IF EXISTS plants');
      await db.execute('DROP TABLE IF EXISTS departments');
      await db.execute('DROP TABLE IF EXISTS plant_unit_prefixes');
      await db.execute('DROP TABLE IF EXISTS product_lines');
      await db.execute('DROP TABLE IF EXISTS plant_product_lines');
      await _onCreate(db, newVersion);
      return;
    }

    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE departments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        )
      ''');

      await _seedDefaultDepartments(db);
    }

    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE plant_unit_prefixes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          plant_number TEXT NOT NULL,
          prefix TEXT NOT NULL,
          is_default INTEGER NOT NULL DEFAULT 0,
          UNIQUE(plant_number, prefix)
        )
      ''');
    }

    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE product_lines (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT NOT NULL UNIQUE
        )
      ''');

      await db.execute('''
        CREATE TABLE plant_product_lines (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          plant_number TEXT NOT NULL,
          product_line_id INTEGER NOT NULL,
          is_default INTEGER NOT NULL DEFAULT 0,
          UNIQUE(plant_number, product_line_id)
        )
      ''');
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

  Future<int> deleteAllWriteups() async {
    final db = await database;
    return await db.delete('audit_writeups');
  }

  Future<List<PlantSessionSummary>> getPlantSessionSummaries() async {
    final db = await database;

    final results = await db.rawQuery('''
      SELECT plant_number, COUNT(*) AS writeupCount
      FROM audit_writeups
      GROUP BY plant_number
      ORDER BY CAST(plant_number AS INTEGER)
    ''');

    return results.map((row) {
      return PlantSessionSummary(
        plantNumber: row['plant_number'] as String,
        writeupCount: row['writeupCount'] as int,
      );
    }).toList();
  }

  Future<int> getRviaCodeCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM rvia_codes',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<RviaCode>> getAllRviaCodes() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'rvia_codes',
      orderBy: 'standard, sub_cat',
    );

    return maps.map((map) => RviaCode.fromMap(map)).toList();
  }

  Future<void> replaceAllRviaCodes(List<RviaCode> codes) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete('rvia_codes');

      final batch = txn.batch();

      for (final code in codes) {
        batch.insert(
          'rvia_codes',
          code.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
    });
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

  Future<void> _seedDefaultPlants(Database db) async {
    const defaultPlants = ['320', '340', '501', '810', '815'];

    final batch = db.batch();

    for (final plant in defaultPlants) {
      batch.insert('plants', {
        'plant_number': plant,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await batch.commit(noResult: true);
  }

  Future<void> _seedDefaultDepartments(Database db) async {
    const defaultDepartments = [
      'Floors',
      'Plumbing',
      'Shelling',
      'Electrical',
      'Metal',
      'Slide-outs',
      'Final',
      'Cabinet Shop',
    ];

    final batch = db.batch();

    for (final department in defaultDepartments) {
      batch.insert('departments', {
        'name': department,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await batch.commit(noResult: true);
  }

  Future<List<Plant>> getAllPlants() async {
    final db = await database;

    final maps = await db.query(
      'plants',
      orderBy: 'CAST(plant_number AS INTEGER)',
    );

    return maps.map((map) => Plant.fromMap(map)).toList();
  }

  Future<bool> plantExists(String plantNumber) async {
    final db = await database;

    final result = await db.query(
      'plants',
      where: 'LOWER(plant_number) = ?',
      whereArgs: [plantNumber.trim().toLowerCase()],
    );

    return result.isNotEmpty;
  }

  Future<int> insertPlant(Plant plant) async {
    final db = await database;

    return await db.insert('plants', {
      'plant_number': plant.plantNumber.trim(),
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<int> updatePlant(Plant plant) async {
    final db = await database;

    return await db.update(
      'plants',
      {'plant_number': plant.plantNumber.trim()},
      where: 'id = ?',
      whereArgs: [plant.id],
    );
  }

  Future<int> deletePlant(int id) async {
    final db = await database;

    return await db.delete('plants', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Department>> getAllDepartments() async {
    final db = await database;

    final maps = await db.query('departments', orderBy: 'LOWER(name)');

    return maps.map((map) => Department.fromMap(map)).toList();
  }

  Future<bool> departmentExists(String name) async {
    final db = await database;

    final result = await db.query(
      'departments',
      where: 'LOWER(name) = ?',
      whereArgs: [name.trim().toLowerCase()],
    );

    return result.isNotEmpty;
  }

  Future<int> insertDepartment(Department department) async {
    final db = await database;

    return await db.insert('departments', {
      'name': department.name.trim(),
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<int> updateDepartment(Department department) async {
    final db = await database;

    return await db.update(
      'departments',
      {'name': department.name.trim()},
      where: 'id = ?',
      whereArgs: [department.id],
    );
  }

  Future<int> deleteDepartment(int id) async {
    final db = await database;

    return await db.delete('departments', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<PlantUnitPrefix>> getPrefixesForPlant(String plantNumber) async {
    final db = await database;

    final maps = await db.query(
      'plant_unit_prefixes',
      where: 'plant_number = ?',
      whereArgs: [plantNumber],
      orderBy: 'is_default DESC, prefix',
    );

    return maps.map((map) => PlantUnitPrefix.fromMap(map)).toList();
  }

  Future<int> insertPlantUnitPrefix(PlantUnitPrefix prefix) async {
    final db = await database;

    return await db.transaction((txn) async {
      if (prefix.isDefault) {
        await txn.update(
          'plant_unit_prefixes',
          {'is_default': 0},
          where: 'plant_number = ?',
          whereArgs: [prefix.plantNumber],
        );
      }

      return await txn.insert('plant_unit_prefixes', {
        'plant_number': prefix.plantNumber,
        'prefix': prefix.prefix.toUpperCase().trim(),
        'is_default': prefix.isDefault ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.abort);
    });
  }

  Future<int> updatePlantUnitPrefix(PlantUnitPrefix prefix) async {
    final db = await database;

    return await db.transaction((txn) async {
      if (prefix.isDefault) {
        await txn.update(
          'plant_unit_prefixes',
          {'is_default': 0},
          where: 'plant_number = ?',
          whereArgs: [prefix.plantNumber],
        );
      }

      return await txn.update(
        'plant_unit_prefixes',
        {
          'prefix': prefix.prefix.toUpperCase().trim(),
          'is_default': prefix.isDefault ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [prefix.id],
      );
    });
  }

  Future<int> deletePlantUnitPrefix(int id) async {
    final db = await database;

    return await db.delete(
      'plant_unit_prefixes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> plantUnitPrefixExists(String plantNumber, String prefix) async {
    final db = await database;

    final result = await db.query(
      'plant_unit_prefixes',
      where: 'plant_number = ? AND LOWER(prefix) = ?',
      whereArgs: [plantNumber, prefix.trim().toLowerCase()],
    );

    return result.isNotEmpty;
  }

  Future<List<ProductLine>> getAllProductLines() async {
    final db = await database;

    final maps = await db.query('product_lines', orderBy: 'LOWER(code)');

    return maps.map((map) => ProductLine.fromMap(map)).toList();
  }

  Future<int> insertProductLine(ProductLine productLine) async {
    final db = await database;

    return await db.insert('product_lines', {
      'code': productLine.code.toUpperCase().trim(),
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<int> updateProductLine(ProductLine productLine) async {
    final db = await database;

    return await db.update(
      'product_lines',
      {'code': productLine.code.toUpperCase().trim()},
      where: 'id = ?',
      whereArgs: [productLine.id],
    );
  }

  Future<int> deleteProductLine(int id) async {
    final db = await database;

    return await db.delete('product_lines', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> productLineExists(String code) async {
    final db = await database;

    final result = await db.query(
      'product_lines',
      where: 'LOWER(code) = ?',
      whereArgs: [code.trim().toLowerCase()],
    );

    return result.isNotEmpty;
  }

  Future<int> assignProductLineToPlant(
    String plantNumber,
    int productLineId, {
    bool isDefault = false,
  }) async {
    final db = await database;

    return await db.transaction((txn) async {
      if (isDefault) {
        await txn.update(
          'plant_product_lines',
          {'is_default': 0},
          where: 'plant_number = ?',
          whereArgs: [plantNumber],
        );
      }

      return await txn.insert('plant_product_lines', {
        'plant_number': plantNumber,
        'product_line_id': productLineId,
        'is_default': isDefault ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.abort);
    });
  }

  Future<int> updatePlantProductLine(PlantProductLine assignment) async {
    final db = await database;

    return await db.transaction((txn) async {
      if (assignment.isDefault) {
        await txn.update(
          'plant_product_lines',
          {'is_default': 0},
          where: 'plant_number = ?',
          whereArgs: [assignment.plantNumber],
        );
      }

      return await txn.update(
        'plant_product_lines',
        {'is_default': assignment.isDefault ? 1 : 0},
        where: 'id = ?',
        whereArgs: [assignment.id],
      );
    });
  }

  Future<int> removeProductLineFromPlant(int assignmentId) async {
    final db = await database;

    return await db.delete(
      'plant_product_lines',
      where: 'id = ?',
      whereArgs: [assignmentId],
    );
  }

  Future<List<PlantProductLineOption>> getProductLinesForPlant(
    String plantNumber,
  ) async {
    final db = await database;

    final results = await db.rawQuery(
      '''
      SELECT 
        ppl.id AS assignment_id,
        pl.id AS product_line_id,
        ppl.plant_number,
        pl.code,
        ppl.is_default
      FROM plant_product_lines ppl
      JOIN product_lines pl ON pl.id = ppl.product_line_id
      WHERE ppl.plant_number = ?
      ORDER BY ppl.is_default DESC, pl.code
    ''',
      [plantNumber],
    );

    return results.map((row) => PlantProductLineOption.fromMap(row)).toList();
  }

  Future<bool> plantHasProductLine(
    String plantNumber,
    int productLineId,
  ) async {
    final db = await database;

    final result = await db.query(
      'plant_product_lines',
      where: 'plant_number = ? AND product_line_id = ?',
      whereArgs: [plantNumber, productLineId],
    );

    return result.isNotEmpty;
  }
}
