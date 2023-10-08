import 'dart:async';
import 'package:askaide/helper/constant.dart';
import 'package:askaide/lang/lang.dart';
import 'package:askaide/repo/data/chat_history.dart';
import 'package:askaide/repo/data/room_data.dart';
import 'package:askaide/repo/model/chat_history.dart';
import 'package:askaide/repo/model/message.dart';
import 'package:askaide/repo/data/chat_message_data.dart';
import 'package:askaide/repo/model/room.dart';

class ChatMessageRepository {
  final ChatMessageDataProvider _chatMsgDataProvider;
  final RoomDataProvider _chatRoomDataProvider;
  final ChatHistoryProvider _chatHistoryProvider;

  ChatMessageRepository(
    this._chatRoomDataProvider,
    this._chatMsgDataProvider,
    this._chatHistoryProvider,
  );

  /// Get all rooms
  Future<List<Room>> rooms({int? userId}) async {
    return await _chatRoomDataProvider.chatRooms(userId: userId);
  }

  /// Create room
  Future<Room> createRoom({
    required String name,
    required category,
    String? description,
    String? model,
    String? color,
    String? systemPrompt,
    int? userId,
    int? maxContext,
  }) async {
    return await _chatRoomDataProvider.createRoom(
      name: name,
      category: category,
      description: description,
      model: model,
      color: color,
      systemPrompt: systemPrompt,
      userId: userId,
      maxContext: maxContext,
    );
  }

  /// Delete room
  Future<void> deleteRoom(int roomId) async {
    await _chatRoomDataProvider.deleteRoom(roomId);
    await _chatMsgDataProvider.clearMessages(roomId);
  }

  /// Get recent messages in a room
  Future<List<Message>> getRecentMessages(
    int roomId, {
    int? userId,
    int? chatHistoryId,
  }) async {
    return (await _chatMsgDataProvider.getRecentMessages(
      roomId,
      chatMessagePerPage,
      userId: userId,
      chatHistoryId: chatHistoryId,
    ))
        .reversed
        .toList();
  }

  /// Send message to a room
  Future<int> sendMessage(int roomId, Message message) async {
    return await _chatMsgDataProvider.sendMessage(roomId, message);
  }

  /// Fix the status of all messages (pending -> failed)
  Future<void> fixMessageStatus(int roomId) async {
    return await _chatMsgDataProvider.fixMessageStatus(roomId);
  }

  /// Update a message
  Future<void> updateMessage(int roomId, int id, Message message) async {
    return await _chatMsgDataProvider.updateMessage(roomId, id, message);
  }

  /// Partially update a message
  Future<void> updateMessagePart(
    int roomId,
    int id,
    List<MessagePart> parts,
  ) async {
    return await _chatMsgDataProvider.updateMessagePart(roomId, id, parts);
  }

  /// Remove messages
  Future<void> removeMessage(int roomId, List<int> ids) async {
    return await _chatMsgDataProvider.removeMessage(roomId, ids);
  }

  /// Clear messages in a room
  Future<void> clearMessages(int roomId, {int? userId}) async {
    await _chatMsgDataProvider.clearMessages(roomId, userId: userId);
  }

  /// Get the last message in a room
  Future<Message?> getLastMessage(int roomId,
      {int? userId, int? chatHistoryId}) async {
    return await _chatMsgDataProvider.getLastMessage(roomId,
        userId: userId, chatHistoryId: chatHistoryId);
  }

  /// Get a room
  Future<Room?> room(int roomId) async {
    final room = await _chatRoomDataProvider.room(roomId);
    if (room != null) {
      room.localRoom = true;
    }

    return room;
  }

  /// Update a room
  Future<int> updateRoom(Room room) async {
    return await _chatRoomDataProvider.updateRoom(room);
  }

  /// Update the last active time of a room
  Future<void> updateRoomLastActiveTime(int roomId) async {
    return await _chatRoomDataProvider.updateRoomLastActiveTime(roomId);
  }

  Future<ChatHistory> createChatHistory({
    required String title,
    int? userId,
    int? roomId,
    String? lastMessage,
    String? model,
  }) {
    return _chatHistoryProvider.create(
      title: title,
      userId: userId,
      roomId: roomId,
      model: model,
      lastMessage: lastMessage,
    );
  }

  Future<List<ChatHistory>> recentChatHistories(
    int roomId,
    int count, {
    int? userId,
  }) async {
    return await _chatHistoryProvider.getChatHistories(
      roomId,
      count,
      userId: userId,
    );
  }

  Future<ChatHistory?> getChatHistory(int chatId) async {
    return await _chatHistoryProvider.history(chatId);
  }

  Future<int> deleteChatHistory(int chatId) async {
    return await _chatHistoryProvider.delete(chatId);
  }

  Future<int> updateChatHistory(int chatId, ChatHistory chatHistory) async {
    chatHistory.id = chatId;
    return await _chatHistoryProvider.update(chatHistory);
  }
}