import 'package:askaide/repo/model/creative_island_history.dart';
import 'package:sqflite/sqlite_api.dart';

class CreativeIslandDataProvider {
  Database conn;
  CreativeIslandDataProvider(this.conn);

  Future<List<CreativeIslandHistory>> getRecentHistories(
      String itemId, int count,
      {int? userId}) async {
    final userCondition =
        userId == null ? ' AND user_id IS NULL' : ' AND user_id = $userId';

    List<Map<String, Object?>> histories = await conn.query(
      'creative_island_history',
      where: 'item_id = ? $userCondition',
      whereArgs: [itemId],
      orderBy: 'id DESC',
      limit: count,
    );

    return histories.map((e) => CreativeIslandHistory.fromJson(e)).toList();
  }

  Future<CreativeIslandHistory> create(
    String itemId, {
    String? arguments,
    String? prompt,
    String? answer,
    String? taskId,
    String? status,
    int? userId,
  }) async {
    final his = CreativeIslandHistory(
      itemId,
      arguments: arguments,
      prompt: prompt,
      answer: answer,
      taskId: taskId,
      status: status,
      userId: userId,
    );

    his.id = await conn.insert('creative_island_history', his.toJson());
    return his;
  }

  /// Update
  Future<void> update(int id, CreativeIslandHistory his) async {
    await conn.update('creative_island_history', his.toJson(),
        where: 'id = ?', whereArgs: [id]);
  }

  /// Delete history
  Future<int> delete(int hisId) async {
    return conn
        .delete('creative_island_history', where: 'id = ?', whereArgs: [hisId]);
  }

  /// Get specific history information
  Future<CreativeIslandHistory?> history(int id) async {
    List<Map<String, Object?>> histories = await conn.query(
        'creative_island_history',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1);
    if (histories.isEmpty) {
      return null;
    }

    return CreativeIslandHistory.fromJson(histories.first);
  }
}