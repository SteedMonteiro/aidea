import 'dart:convert';

import 'package:askaide/bloc/bloc_manager.dart';
import 'package:askaide/helper/ability.dart';
import 'package:askaide/helper/constant.dart';
import 'package:askaide/helper/error.dart';
import 'package:askaide/helper/model_resolver.dart';
import 'package:askaide/helper/queue.dart';
import 'package:askaide/lang/lang.dart';
import 'package:askaide/repo/api_server.dart';
import 'package:askaide/repo/chat_message_repo.dart';
import 'package:askaide/repo/data/chat_message_data.dart';
import 'package:askaide/repo/model/chat_history.dart';
import 'package:askaide/repo/model/message.dart';
import 'package:askaide/repo/model/room.dart';
import 'package:askaide/repo/openai_repo.dart';
import 'package:askaide/repo/settings_repo.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatMessageBloc extends BlocExt<ChatMessageEvent, ChatMessageState> {
  final ChatMessageRepository chatMsgRepo;
  final SettingRepository settingRepo;
  final int roomId;
  final int? chatHistoryId;

  ChatMessageBloc(
    this.roomId, {
    required this.chatMsgRepo,
    required this.settingRepo,
    this.chatHistoryId,
  }) : super(ChatMessageInitial()) {
    on<ChatMessageSendEvent>(_messageSendEventHandler);
    on<ChatMessageGetRecentEvent>(_getRecentEventHandler);
    on<ChatMessageClearAllEvent>(_clearAllEventHandler);
    on<ChatMessageBreakContextEvent>(_breakContextEventHandler);
    on<ChatMessageDeleteEvent>(_deleteMessageEventHandler);
  }

  Future<void> _deleteMessageEventHandler(event, emit) async {
    await chatMsgRepo.removeMessage(roomId, event.ids);

    ChatHistory? his;
    if (event.chatHistoryId != null && event.chatHistoryId! > 0) {
      his = await chatMsgRepo.getChatHistory(event.chatHistoryId!);
    }

    emit(ChatMessagesLoaded(
      await chatMsgRepo.getRecentMessages(
        roomId,
        userId: APIServer().localUserID(),
        chatHistoryId: event.chatHistoryId,
      ),
      chatHistory: his,
    ));
  }

  /// Set context break flag
  Future<void> _breakContextEventHandler(event, emit) async {
    // Query current Room information
    final room = await queryRoomById(chatMsgRepo, roomId);
    if (room == null) {
      emit(ChatMessagesLoaded(
        await chatMsgRepo.getRecentMessages(
          roomId,
          userId: APIServer().localUserID(),
        ),
        error: 'The selected digital person does not exist',
      ));
      return;
    }

    final lastMessage = await chatMsgRepo.getLastMessage(
      roomId,
      userId: APIServer().localUserID(),
    );

    if (lastMessage != null &&
        (lastMessage.type == MessageType.contextBreak ||
            lastMessage.isInitMessage())) {
      return;
    }

    await chatMsgRepo.sendMessage(
      roomId,
      Message(
        Role.receiver,
        AppLocale.contextBreakMessage,
        ts: DateTime.now(),
        type: MessageType.contextBreak,
        roomId: roomId,
        userId: APIServer().localUserID(),
      ),
    );

    if (room.initMessage != null && room.initMessage != '') {
      await chatMsgRepo.sendMessage(
        roomId,
        Message(
          Role.receiver,
          room.initMessage!,
          ts: DateTime.now(),
          type: MessageType.initMessage,
          roomId: roomId,
          userId: APIServer().localUserID(),
        ),
      );
    }

    final messages = await chatMsgRepo.getRecentMessages(
