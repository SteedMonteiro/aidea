import 'dart:convert';

import 'package:askaide/helper/helper.dart';

/// Chat message
class Message {
  /// ID of the chat room to which the message belongs
  int? roomId;

  /// User ID
  int? userId;

  /// ID of the chat history
  int? chatHistoryId;

  /// Message ID
  int? id;

  /// Message direction
  Role role;

  /// Message content
  String text;

  /// Additional information for the message, used to provide model-related information
  String? extra;

  /// Model used when sending the message
  String? model;

  /// Message type
  MessageType type;

  /// Sender
  String? user;

  /// Timestamp
  DateTime? ts;

  /// Associated message ID (question ID)
  int? refId;

  /// Server ID
  int? serverId;

  /// Message status: 1-success 0-waiting for response 2-failed
  int status;

  /// Quota consumed by the message
  int? quotaConsumed;

  /// Token consumed by the message
  int? tokenConsumed;

  /// Whether the current message is ready and does not need to be persisted
  bool isReady = true;

  Message(
    this.role,
    this.text, {
    required this.type,
    this.userId,
    this.chatHistoryId,
    this.id,
    this.user,
    this.ts,
    this.model,
    this.roomId,
    this.extra,
    this.refId,
    this.serverId,
    this.status = 1,
    this.quotaConsumed,
    this.tokenConsumed,
  });

  /// Get the additional information for the message
  void setExtra(dynamic data) {
    extra = jsonEncode(data);
  }

  /// Get the additional information for the message
  decodeExtra() {
    if (extra == null) {
      return null;
    }

    return jsonDecode(extra!);
  }

  /// Check if it is a system message, including timeline
  bool isSystem() {
    return type == MessageType.system ||
        type == MessageType.timeline ||
        type == MessageType.contextBreak;
  }

  /// Check if it is an initial message
  bool isInitMessage() {
    return type == MessageType.initMessage;
  }

  /// Check if it is a timeline
  bool isTimeline() {
    return type == MessageType.timeline;
  }

  /// Format the timestamp
  String friendlyTime() {
    return humanTime(ts);
  }

  /// Check if the message has failed
  bool statusIsFailed() {
    return status == 2;
  }

  /// Check if the message is successful
  bool statusIsSucceed() {
    return status == 1;
  }

  /// Check if the message is waiting for response
  bool statusPending() {
    return status == 0;
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'chat_history_id': chatHistoryId,
      'role': role.getRoleText(),
      'text': text,
      'type': type.getTypeText(),
      'extra': extra,
      'model': model,
      'user': user,
      'ts': ts?.millisecondsSinceEpoch,
      'room_id': roomId,
      'ref_id': refId,
      'server_id': serverId,
      'status': status,
      'token_consumed': tokenConsumed,
      'quota_consumed': quotaConsumed,
    };
  }

  Message.fromMap(Map<String, Object?> map)
      : id = map['id'] as int,
        userId = map['user_id'] as int?,
        chatHistoryId = map['chat_history_id'] as int?,
        role = Role.getRoleFromText(map['role'] as String),
        text = map['text'] as String,
        extra = map['extra'] as String?,
        model = map['model'] as String?,
        type = MessageType.getTypeFromText(map['type'] as String),
        user = map['user'] as String?,
        refId = map['ref_id'] as int?,
        serverId = map['server_id'] as int?,
        status = (map['status'] ?? 1) as int,
        tokenConsumed = map['token_consumed'] as int?,
        quotaConsumed = map['quota_consumed'] as int?,
        ts = map['ts'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map['ts'] as int),
        roomId = map['room_id'] as int?;
}

enum Role {
  receiver,
  sender;

  static Role getRoleFromText(String value) {
    switch (value) {
      case 'receiver':
        return Role.receiver;
      case 'sender':
        return Role.sender;
      default:
        return Role.receiver;
    }
  }

  String getRoleText() {
    switch (this) {
      case Role.receiver:
        return 'receiver';
      case Role.sender:
        return 'sender';
      default:
        return 'receiver';
    }
  }
}

enum MessageType {
  text,
  image,
  file,
  audio,
  video,
  location,
  command,
  system,
  timeline,
  contextBreak,
  hide,
  initMessage;

  String getTypeText() {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.file:
        return 'file';
      case MessageType.audio:
        return 'audio';
      case MessageType.video:
        return 'video';
      case MessageType.location:
        return 'location';
      case MessageType.command:
        return 'command';
      case MessageType.system:
        return 'system';
      case MessageType.timeline:
        return 'timeline';
      case MessageType.contextBreak:
        return 'contextBreak';
      case MessageType.hide:
        return 'hide';
      case MessageType.initMessage:
        return 'initMessage';
      default:
        return 'text';
    }
  }

  static MessageType getTypeFromText(String value) {
    switch (value) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'audio':
        return MessageType.audio;
      case 'video':
        return MessageType.video;
      case 'location':
        return MessageType.location;
      case 'command':
        return MessageType.command;
      case 'system':
        return MessageType.system;
      case 'timeline':
        return MessageType.timeline;
      case 'contextBreak':
        return MessageType.contextBreak;
      case 'hide':
        return MessageType.hide;
      case 'initMessage':
        return MessageType.initMessage;
      default:
        return MessageType.text;
    }
  }
}