import 'package:askaide/helper/constant.dart';
import 'package:sqflite/sqflite.dart';

/// Execute database migration
Future<void> migrate(db, oldVersion, newVersion) async {
  if (oldVersion <= 1) {
    await db.execute('''
          ALTER TABLE chat_room ADD COLUMN color TEXT;
          UPDATE chat_room SET color = 'FF4CAF50' WHERE category = 'system';
        ''');
  }

  if (oldVersion <= 2) {
    await db.execute('ALTER TABLE chat_message ADD COLUMN extra TEXT;');
    await db.execute('ALTER TABLE chat_message ADD COLUMN model TEXT;');
  }

  if (oldVersion < 5) {
    await db.execute('''
        CREATE TABLE cache (
          `key` TEXT NOT NULL PRIMARY KEY,
          `value` TEXT NOT NULL,
          `created_at` INTEGER,
          `valid_before` INTEGER
        )
        ''');
  }
  if (oldVersion < 6) {
    await db.execute('''
        CREATE TABLE creative_island_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_id TEXT NOT NULL,
          arguments TEXT NULL,
          prompt TEXT NULL,
          answer TEXT NULL,
          created_at INTEGER NOT NULL
        ) 
      ''');
  }

  if (oldVersion < 7) {
    await db.execute(
        'ALTER TABLE creative_island_history ADD COLUMN task_id TEXT NULL;');
    await db.execute(
        'ALTER TABLE creative_island_history ADD COLUMN status TEXT NULL;');
  }

  if (oldVersion < 10) {
    await db.execute('ALTER TABLE cache ADD COLUMN `group` TEXT NULL;');
  }

  if (oldVersion < 11) {
    await db.execute('''
      CREATE TABLE settings (
        `key` TEXT NOT NULL PRIMARY KEY,
        `value` TEXT NOT NULL
      );
    ''');
  }

  if (oldVersion < 12) {
    await db
        .execute('''ALTER TABLE chat_room ADD COLUMN user_id INTEGER NULL;''');
    await db.execute(
        '''ALTER TABLE creative_island_history ADD COLUMN user_id INTEGER NULL;''');
  }

  if (oldVersion < 13) {
    await db.execute(
        '''ALTER TABLE chat_message ADD COLUMN user_id INTEGER NULL;''');
  }

  if (oldVersion