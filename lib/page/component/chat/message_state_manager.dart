import 'dart:convert';

import 'package:askaide/repo/cache_repo.dart';
import 'package:askaide/repo/model/message.dart';

class MessageWithState {
  final Message message;
  final MessageState state;

  MessageWithState(this.message, this.state);
}

/// Message state
class MessageState {
  /// Whether to show translation
  bool showTranslate = false;

  /// Translation text
  String? translateText;

  /// Whether to show Markdown
  bool showMarkdown = true;

  MessageState({
    this.showTranslate = false,
    this.translateText,
    this.showMarkdown = true,
  });

  /// Whether it is the initial state
  bool isInitializeState() {
    return !showTranslate && translateText == null && showMarkdown;
  }

  toJson() {
    return {
      'showTranslate': showTranslate,
      'translateText': translateText,
      'showMarkdown': showMarkdown,
    };
  }

  MessageState.fromJson(Map<String, dynamic> json) {
    showTranslate = json['showTranslate'] ?? false;
    translateText = json['translateText'];
    showMarkdown = json['showMarkdown'] ?? true;
  }
}

/// Message state manager
class MessageStateManager {
  final CacheRepository cacheRepo;
  MessageStateManager(this.cacheRepo);

  Future<Map<String, MessageState>> loadRoomStates(int roomId) async {
    final states = await cacheRepo.getAllInGroup('room:$roomId');

    return states.map((key, value) =>
        MapEntry(key, MessageState.fromJson(jsonDecode(value))));
  }

  String getKey(int roomId, int id) {
    return 'msg:state:$roomId:$id';
  }

  Future<MessageState> getState(int roomId, int id) async {
    final key = getKey(roomId, id);
    final value = await cacheRepo.get(key);
    if (value == null) {
      return MessageState();
    }

    return MessageState.fromJson(jsonDecode(value));
  }

  Future<void> setState(int roomId, int id, MessageState state) async {
    final key = getKey(roomId, id);
    if (state.isInitializeState()) {
      return removeState(roomId, id);
    }

    return cacheRepo.set(
      key,
      jsonEncode(state.toJson()),
      const Duration(days: 7),
      group: 'room:$roomId',
    );
  }

  Future<void> removeState(int roomId, int id) async {
    final key = getKey(roomId, id);
    return cacheRepo.remove(key);
  }
}