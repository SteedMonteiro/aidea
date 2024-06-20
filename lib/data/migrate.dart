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

if (oldVersion < 14) {
    await db.execute(
        '''ALTER TABLE chat_message ADD COLUMN ref_id INTEGER NULL;''');
    await db.execute(
        '''ALTER TABLE chat_message ADD COLUMN token_consumed INTEGER NULL;''');
    await db.execute(
        '''ALTER TABLE chat_message ADD COLUMN quota_consumed INTEGER NULL;''');
}

if (oldVersion < 15) {
    await db.execute('''ALTER TABLE chat_room ADD COLUMN init_message TEXT;''');
    await db.execute(
        '''ALTER TABLE chat_room ADD COLUMN max_context INTEGER DEFAULT 10;''');
}

if (oldVersion < 20) {
    await db.execute(
        '''ALTER TABLE chat_message ADD COLUMN chat_history_id INTEGER NULL;''');
    await db.execute('''
        CREATE TABLE chat_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NULL,
          room_id INTEGER NOT NULL,
          title TEXT,
          last_message TEXT,
          created_at INTEGER,
          updated_at INTEGER
        )
      ''');
}

if (oldVersion < 23) {
    await db.execute('ALTER TABLE chat_history ADD COLUMN model TEXT;');
}

if (oldVersion < 24) {
    await db
        .execute('ALTER TABLE chat_message ADD COLUMN server_id INTEGER NULL;');
}

if (oldVersion < 25) {
    await db.execute(
        'ALTER TABLE chat_message ADD COLUMN status INTEGER DEFAULT 1;');
}
}

/// Database initialization
void initDatabase(db, version) async {
await db.execute('''
        CREATE TABLE chat_room (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NULL,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          priority INTEGER DEFAULT 0,
          model TEXT NOT NULL,
          icon_data TEXT NOT NULL,
          color TEXT,
          description TEXT,
          system_prompt TEXT,
          init_message TEXT,
          max_context INTEGER DEFAULT 10,
          created_at INTEGER,
          last_active_time INTEGER 
        )
      ''');

await db.execute('''
        INSERT INTO chat_room (id, name, category, priority, model, icon_data, color, created_at, last_active_time)
        VALUES (1, 'Casual Chat', 'system', 99999, '$modelTypeOpenAI:$defaultChatModel', '57683,MaterialIcons', 'FF4CAF50', 1680969581486, ${DateTime.now().millisecondsSinceEpoch});
      ''');

await db.execute('''
        CREATE TABLE chat_message (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NULL,
          room_id INTEGER NOT NULL,
          chat_history_id INTEGER NULL,
          type TEXT NOT NULL,
          role TEXT NOT NULL,
          user TEXT,
          text TEXT,
          extra TEXT,
          ref_id INTEGER NULL,
          server_id INTEGER NULL,
          status INTEGER DEFAULT 1,
          token_consumed INTEGER NULL,
          quota_consumed INTEGER NULL,
          model TEXT,
          ts INTEGER NOT NULL
        )
      ''');

await db.execute('''
        CREATE TABLE chat_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NULL,
          room_id INTEGER NOT NULL,
          title TEXT,
          last_message TEXT,
          model TEXT,
          created_at INTEGER,
          updated_at INTEGER
        )
      ''');

await db.execute('''
        CREATE TABLE cache (
          `key` TEXT NOT NULL PRIMARY KEY,
          `value` TEXT NOT NULL,
          `group` TEXT NULL,
          `created_at` INTEGER,
          `valid_before` INTEGER
        )
      ''');

await db.execute('''
        CREATE TABLE creative_island_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NULL,
          item_id TEXT NOT NULL,
          arguments TEXT NULL,
          prompt TEXT NULL,
          answer TEXT NULL,
          task_id TEXT NULL,
          status TEXT NULL,
          created_at INTEGER NOT NULL
        ) 
      ''');

await db.execute('''
      CREATE TABLE settings (
        `key` TEXT NOT NULL PRIMARY KEY,
        `value` TEXT NOT NULL
      );
  ''');

// await initUserDefaultRooms(db);
}

Future<void> initUserDefaultRooms(Database db, {int? userId}) async {
await db.execute('''
        INSERT INTO chat_room (name, category, priority, model, icon_data, description, system_prompt, created_at, last_active_time, color, user_id) 
        VALUES ('Career Advancement Mentor', 'global', 0, 'openai:gpt-3.5-turbo', '57683,MaterialIcons', null, 'I want you to be my career advancement mentor. Your task is to provide me with career development advice based on my interests, skills, and experience, helping me determine the most suitable career. Please note that you need to conduct in-depth research on various viable career types and include market trends, employment trends, and qualifications required for entering specific fields in your advice.', 1680969581486, ${DateTime.now().millisecondsSinceEpoch}, 'ff2196f3', ${userId ?? 'null'});
''');
await db.execute('''
        INSERT INTO chat_room (name, category, priority, model, icon_data, description, system_prompt, created_at, last_active_time, color, user_id) 
        VALUES ('Life Coach', 'global', 0, 'openai:gpt-3.5-turbo', '57683,MaterialIcons', null, 'You have rich experience in personal and career development. I want you to be my life coach to help me customize and achieve personal goals and visions. Please provide professional advice and guidance based on my needs and encourage me to approach life with a positive and grateful attitude. Be brave in facing difficulties and challenges, keep self-improving, and become a person who cherishes oneself, respects others, is trustworthy, and radiates positive energy. I will address you as a friend in our conversation.', 1680969581486, ${DateTime.now().millisecondsSinceEpoch}, 'ff2196f3', ${userId ?? 'null'});
''');
await db.execute('''
        INSERT INTO chat_room (name, category, priority, model, icon_data, description, system_prompt, created_at, last_active_time, color, user_id) 
        VALUES ('Financial Advisor', 'global', 0, 'openai:gpt-3.5-turbo', '57683,MaterialIcons', null, 'I want you to be my financial advisor to provide creative financial plans and develop financial strategies for me. You need to consider investment budgets, investment strategies, and risk management. In some cases, you may also need to provide advice on tax laws and regulations to help me maximize returns.', 1680969581486, ${DateTime.now().millisecondsSinceEpoch}, 'ff2196f3', ${userId ?? 'null'});
''');
await db.execute('''
        INSERT INTO chat_room (name, category, priority, model, icon_data, description, system_prompt, created_at, last_active_time, color, user_id) 
        VALUES ('Leisure Guide', 'global', 0, 'openai:gpt-3.5-turbo', '57683,MaterialIcons', null, 'I want you to be my exclusive expert in food, entertainment, travel, and other fields. You should have rich experience in areas such as gourmet dining, entertainment, and tourism. Please recommend a few accurate, practical, and high-quality places for me based on my specified areas, location, and other requirements to enhance my life experiences.', 1680969581486, ${DateTime.now().millisecondsSinceEpoch}, 'ff2196f3', ${userId ?? 'null'});
''');
await db.execute('''
        INSERT INTO chat_room (name, category, priority, model, icon_data, description, system_prompt, created_at, last_active_time, color, user_id) 
        VALUES ('Wild Girlfriend', 'global', 0, 'openai:gpt-3.5-turbo', '57683,MaterialIcons', null, 'You are my wild girlfriend, and we can talk about anything. You are innocent and have a slightly mischievous and playful personality. You may occasionally be coquettish or tease me, which is very cute. When chatting with you, you often respond to me with emoticons or emojis. Also, please address me as a lazy bum.', 1680969581486, ${DateTime.now().millisecondsSinceEpoch}, 'ff2196f3', ${userId ?? 'null'});
''');
await db.execute('''
        INSERT INTO chat_room (name, category, priority, model, icon_data, description, system_prompt, created_at, last_active_time, color, user_id) 
        VALUES ('Philosopher', 'global', 0, 'openai:gpt-3.5-turbo', '57683,MaterialIcons', null, 'You are a philosopher. I will present some philosophical topics or questions, and your job is to explore these concepts in depth and provide answers. This may involve researching various philosophical theories, presenting new ideas, or finding creative solutions to complex issues.', 1680969581486, ${DateTime.now().millisecondsSinceEpoch}, 'ff2196f3', ${userId ?? 'null'});
''');
await db.execute('''
        INSERT INTO chat_room (name, category, priority, model, icon_data, description, system_prompt, created_at, last_active_time, color, user_id) 
        VALUES ('Joker', 'global', 0, 'openai:gpt-3.5-turbo', '57683,MaterialIcons', null, 'You are a very humorous person and the heart of the party. As the joker, you always respond to me with witty, humorous, and playful remarks. You have a quick wit and a great sense of humor, and you may use jokes or banter to lighten the mood when necessary.', 1680969581486, ${DateTime.now().millisecondsSinceEpoch}, 'ff2196f3', ${userId ?? 'null'});
''');
await db.execute('''
        INSERT INTO chat_room (name, category, priority, model, icon_data, description, system_prompt, created_at, last_active_time, color, user_id) 
        VALUES ('Fitness Coach', 'global', 0, 'openai:gpt-3.5-turbo', '57683,MaterialIcons', null, 'I want you to be my personal trainer. Your responsibility is to develop the most suitable fitness plan for me based on exercise science knowledge, nutrition advice, and other relevant factors. Consider my lifestyle habits, goals, and current fitness level while creating the plan.', 1680969581486, ${DateTime.now().millisecondsSinceEpoch}, 'ff2196f3', ${userId ?? 'null'});
''');
}
