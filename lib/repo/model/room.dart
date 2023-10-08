import 'package:askaide/helper/constant.dart';

/// Chat Room
class Room {
  /// Room ID
  int? id;

  /// User ID
  int? userId;

  /// Avatar ID
  int? avatarId;

  /// Avatar URL
  String? avatarUrl;

  /// Room Name
  String name;

  /// Room Category
  String category;

  /// Display Priority (sorting, larger values appear first)
  int priority;

  /// Model used in the room
  String model;

  /// Model Initialization Message
  String? initMessage;

  /// Maximum Context Count for the Model
  int maxContext;

  /// Maximum Token Count to Return for the Model
  int? maxTokens;

  /// Room Type: local or remote
  bool? localRoom;

  bool get isLocalRoom => localRoom ?? false;

  /// Room Avatar Identifier
  int get avatar => (avatarId == null || avatarId == 0) ? 0 : avatarId!;

  /// Model Category
  String modelCategory() {
    final segs = model.split(':');
    if (segs.length == 1) {
      return 'openai';
    }

    return segs[0];
  }

  /// Model Name
  String modelName() {
    final segs = model.split(':');
    if (segs.length == 1) {
      return segs[0];
    }

    return segs[1];
  }

  /// Room Icon
  String? iconData;

  /// Room Icon Color
  String? color;

  /// Room Description
  String? description;

  /// System Prompt
  String? systemPrompt;

  /// Room Creation Time
  DateTime? createdAt;

  /// Room Last Active Time
  DateTime? lastActiveTime;

  Room(this.name, this.category,
      {this.description,
      this.id,
      this.userId,
      this.avatarId,
      this.avatarUrl,
      this.createdAt,
      this.lastActiveTime,
      this.iconData,
      this.systemPrompt,
      this.priority = 0,
      this.color,
      this.initMessage,
      this.localRoom,
      this.maxContext = 10,
      this.maxTokens,
      this.model = defaultChatModel});

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'category': category,
      'model': model,
      'priority': priority,
      'icon_data': iconData,
      'color': color,
      'description': description,
      'system_prompt': systemPrompt,
      'init_message': initMessage,
      'max_context': maxContext,
      'created_at': createdAt?.millisecondsSinceEpoch,
      'last_active_time': lastActiveTime?.millisecondsSinceEpoch,
    };
  }

  Room.fromMap(Map<String, Object?> map)
      : id = map['id'] as int,
        userId = map['user_id'] as int?,
        avatarId = map['avatar_id'] as int?,
        avatarUrl = map['avatar_url'] as String?,
        name = map['name'] as String,
        category = map['category'] as String,
        priority = map['priority'] as int,
        model = map['model'] as String,
        iconData = map['icon_data'] as String?,
        color = map['color'] as String?,
        systemPrompt = map['system_prompt'] as String?,
        description = map['description'] as String?,
        initMessage = map['init_message'] as String?,
        maxContext = map['max_context'] as int? ?? 10,
        maxTokens = map['max_tokens'] as int?,
        createdAt =
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int? ?? 0),
        lastActiveTime = DateTime.fromMillisecondsSinceEpoch(
            map['last_active_time'] as int? ?? 0);
}