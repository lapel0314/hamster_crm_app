import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  AppDatabase({DatabaseFactory? factory, String? path})
    : _factory = factory ?? databaseFactoryFfi,
      _path = path;

  final DatabaseFactory _factory;
  final String? _path;
  Database? _database;

  Future<Database> get instance async {
    final existing = _database;
    if (existing != null) return existing;

    sqfliteFfiInit();
    final dbPath = _path ?? await defaultDatabasePath();
    await Directory(p.dirname(dbPath)).create(recursive: true);
    final db = await _factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
          await db.execute('PRAGMA journal_mode = WAL');
        },
        onCreate: (db, version) async => _createSchema(db),
      ),
    );
    _database = db;
    return db;
  }

  static Future<String> defaultDatabasePath() async {
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, 'GoldenHamsterCRM', 'hamster_crm.db');
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS customers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  customer_name TEXT NOT NULL,
  gender TEXT,
  phone TEXT,
  adoption TEXT,
  purchase TEXT,
  revenue INTEGER NOT NULL DEFAULT 0,
  cost INTEGER NOT NULL DEFAULT 0,
  memo TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT
);
''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_customers_date ON customers(date);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(customer_name);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);',
    );

    await db.execute('''
CREATE TABLE IF NOT EXISTS prospects (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  consultation_date TEXT NOT NULL,
  visit_date TEXT,
  customer_name TEXT NOT NULL,
  gender TEXT,
  phone TEXT,
  adoption TEXT,
  purchase TEXT,
  revenue INTEGER NOT NULL DEFAULT 0,
  cost INTEGER NOT NULL DEFAULT 0,
  memo TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT
);
''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_prospects_consultation_date ON prospects(consultation_date);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_prospects_visit_date ON prospects(visit_date);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_prospects_name ON prospects(customer_name);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_prospects_phone ON prospects(phone);',
    );

    await db.execute('''
CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value TEXT
);
''');
  }

  Future<void> close() async {
    final db = _database;
    _database = null;
    await db?.close();
  }
}
