import 'package:askaide/bloc/chat_message_bloc.dart';
import 'package:askaide/bloc/free_count_bloc.dart';
import 'package:askaide/bloc/notify_bloc.dart';
import 'package:askaide/bloc/room_bloc.dart';
import 'package:askaide/helper/constant.dart';
import 'package:askaide/lang/lang.dart';
import 'package:askaide/page/chat_screen.dart';
import 'package:askaide/page/component/audio_player.dart';
import 'package:askaide/page/component/background_container.dart';
import 'package:askaide/page/component/chat/chat_input.dart';
import 'package:askaide/page/component/chat/chat_preview.dart';
import 'package:askaide/page/component/chat/empty.dart';
import 'package:askaide/page/component/chat/help_tips.dart';
import 'package:askaide/page/component/chat/message_state_manager.dart';
import 'package:askaide/page/component/enhanced_error.dart';
import 'package:askaide/page/component/random_avatar.dart';
import 'package:askaide/page/dialog.dart';
import 'package:askaide/page/theme/custom_size.dart';
import 'package:askaide/page/theme/custom_theme.dart';
import 'package:askaide/repo/api_server.dart';
import 'package:askaide/repo/model/message.dart';
import 'package:askaide/repo/model/room.dart';
import 'package:askaide/repo/settings_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localization/flutter_localization.dart';

class ChatAnywhereScreen extends StatefulWidget {
  final MessageStateManager stateManager;
  final SettingRepository setting;
  final int? chatId;
  final String? initialMessage;
  final String? model;

  const ChatAnywhereScreen({
    super.key,
    required this.stateManager,
    required this.setting,
    this.chatId,
    this.initialMessage,
    this.model,
  });

  @override
  State<ChatAnywhereScreen> createState() => _ChatAnywhereScreenState();
}

class _ChatAnywhereScreenState extends State<ChatAnywhereScreen> {
  final ChatPreviewController _chatPreviewController = ChatPreviewController();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _inputEnabled = ValueNotifier(true);
  final AudioPlayerController _audioPlayerController =
      AudioPlayerController(useRemoteAPI: false);

  int? chatId;

  bool showAudioPlayer = false;

  @override
  void initState() {
    chatId = widget.chatId;

    context.read<RoomBloc>().add(RoomLoadEvent(
          chatAnywhereRoomId,
          chatHistoryId: chatId,
          cascading: true,
        ));
    context
        .read<ChatMessageBloc>()
        .add(ChatMessageGetRecentEvent(chatHistoryId: widget.chatId));

    _chatPreviewController.addListener(() {
      setState(() {});
    });

    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleSubmit(widget.initialMessage!);
        });
      });
    }

    _audioPlayerController.onPlayStopped = () {
      setState(() {
        showAudioPlayer = false;
      });
    };
    _audioPlayerController.onPlayAudioStarted = () {
      setState(() {
        showAudioPlayer = true;
      });
    };

    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chatPreviewController.dispose();
    _audioPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return BackgroundContainer(
      setting: widget.setting,
      child: Scaffold(
        // AppBar
        appBar: _buildAppBar(context, customColors),
        backgroundColor: Colors.transparent,
        // Chat content window
        body: BlocConsumer<RoomBloc, RoomState>(
          listenWhen: (previous, current) => current is RoomLoaded,
          listener: (context, state) {
            if (state is RoomLoaded && state.cascading) {
              // Load free usage count
              context
                  .read<FreeCountBloc>()
                  .add(FreeCountReloadEvent(model: state.room.model));
            }
          },
          buildWhen: (previous, current) => current is RoomLoaded,
          builder: (context, room) {
            // Load chat room
            if (room is RoomLoaded) {
              if (room.error != null) {
                return EnhancedErrorWidget(error: room.error);
              }

              return _buildChatComponents(
                customColors,
                context,
                room,
              );
            } else {
              return Container();
            }
          },
        ),
      ),
    );
  }

/// Build AppBar
AppBar _buildAppBar(BuildContext context, CustomColors customColors) {
  if (_chatPreviewController.selectMode) {
    return AppBar(
      title: Text(AppLocale.select.getString(context)),
      backgroundColor: Colors.transparent,
      centerTitle: true,
      leading: TextButton(
        onPressed: () {
          _chatPreviewController.exitSelectMode();
        },
        child: Text(
          AppLocale.cancel.getString(context),
          style: TextStyle(color: customColors.linkColor),
        ),
      ),
    );
  }

  return AppBar(
    centerTitle: true,
    elevation: 0,
    toolbarHeight: CustomSize.toolbarHeight,
    title: BlocBuilder<ChatMessageBloc, ChatMessageState>(
      buildWhen: (previous, current) => current is ChatMessagesLoaded,
      builder: (context, state) {
        if (state is ChatMessagesLoaded) {
          return Column(
            children: [
              Text(
                AppLocale.chatAnywhere.getString(context),
                style: const TextStyle(fontSize: CustomSize.appBarTitleSize),
              ),
              // BlocBuilder<RoomBloc, RoomState>(
              //   buildWhen: (previous, current) => current is RoomLoaded,
              //   builder: (context, state) {
              //     if (state is RoomLoaded) {
              //       return BlocBuilder<FreeCountBloc, FreeCountState>(
              //         buildWhen: (previous, current) =>
              //             current is FreeCountLoadedState,
              //         builder: (context, freeState) {
              //           if (freeState is FreeCountLoadedState) {
              //             final matched = freeState.model(state.room.model);
              //             if (matched != null &&
              //                 matched.leftCount > 0 &&
              //                 matched.maxCount > 0) {
              //               return Text(
              //                 '今日剩余免费 ${matched.leftCount} 次',
              //                 style: TextStyle(
              //                   color: customColors.weakTextColor,
              //                   fontSize: 12,
              //                 ),
              //               );
              //             }
              //           }
              //           return const SizedBox();
              //         },
              //       );
              //     }
              //     return const SizedBox();
              //   },
              // ),
              // if (state.chatHistory != null &&
              //     state.chatHistory!.model != null)
              //   Text(
              //     state.chatHistory!.model ?? '',
              //     style: const TextStyle(fontSize: 12),
              //   ),
            ],
          );
        }

        return const SizedBox();
      },
    ),

    // actions: [
    //   buildChatMoreMenu(
    //     context,
    //     chatAnywhereRoomId,
    //     useLocalContext: false,
    //     withSetting: false,
    //   ),
    // ],
    flexibleSpace: SizedBox(
      width: double.infinity,
      child: ShaderMask(
        shaderCallback: (rect) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.transparent],
          ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
        },
        blendMode: BlendMode.dstIn,
        child: Image.asset(
          customColors.appBarBackgroundImage!,
          fit: BoxFit.cover,
        ),
      ),
    ),
  );
}

/// Build chat room window
Widget _buildChatComponents(
  CustomColors customColors,
  BuildContext context,
  RoomLoaded room,
) {
  return Column(
    children: [
      if (showAudioPlayer)
        EnhancedAudioPlayer(controller: _audioPlayerController),
      // Chat content window
      Expanded(
        child: BlocConsumer<ChatMessageBloc, ChatMessageState>(
          listener: (context, state) {
            if (state is ChatAnywhereInited) {
              setState(() {
                chatId = state.chatId;
              });
            }

            // Display error message
            if (state is ChatMessagesLoaded && state.error != null) {
              showErrorMessageEnhanced(context, state.error);
            } else if (state is ChatMessageUpdated) {
              // Scroll the chat content window to the bottom
              if (!state.processing && _scrollController.hasClients) {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                );
              }

              if (state.processing && _inputEnabled.value) {
                // When replying to a chat, disable input box editing
                setState(() {
                  _inputEnabled.value = false;
                });
              } else if (!state.processing && !_inputEnabled.value) {
                // When chat reply is complete, cancel input box editing restriction
                setState(() {
                  _inputEnabled.value = true;
                });
              }
            }
          },
          buildWhen: (prv, cur) => cur is ChatMessagesLoaded,
          builder: (context, state) {
            if (state is ChatMessagesLoaded) {
              return _buildChatPreviewArea(
                state,
                room.examples ?? [],
                room,
                customColors,
                _chatPreviewController.selectMode,
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),

      // Chat input window
      if (!_chatPreviewController.selectMode)
        Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            color: customColors.chatInputPanelBackground,
          ),
          child: BlocBuilder<FreeCountBloc, FreeCountState>(
            builder: (context, freeState) {
              var hintText = '有问题尽管问我';
              if (freeState is FreeCountLoadedState) {
                final matched = freeState.model(room.room.model);
                if (matched != null &&
                    matched.leftCount > 0 &&
                    matched.maxCount > 0) {
                  hintText += '（今日还可免费畅享${matched.leftCount}次）';
                }
              }
              return SafeArea(
                child: ChatInput(
                  enableNotifier: _inputEnabled,
                  onSubmit: _handleSubmit,
                  enableImageUpload: false,
                  hintText: hintText,
                  onVoiceRecordTappedEvent: () {
                    _audioPlayerController.stop();
                  },
                ),
              );
            },
          ),
        ),

      // Select mode toolbar
      if (_chatPreviewController.selectMode)
        buildSelectModeToolbars(
          context,
          _chatPreviewController,
          customColors,
        ),
    ],
  );
}

/// Build chat content window
Widget _buildChatPreviewArea(
  ChatMessagesLoaded loadedState,
  List<ChatExample> examples,
  RoomLoaded room,
  CustomColors customColors,
  bool selectMode,
) {
  final loadedMessages = loadedState.messages as List<Message>;
  if (room.room.initMessage != null &&
      room.room.initMessage != '' &&
      loadedMessages.isEmpty) {
    loadedMessages.add(
      Message(
        Role.receiver,
        room.room.initMessage!,
        type: MessageType.initMessage,
      ),
    );
  }

  // When chat content is empty, show the example page
  if (loadedMessages.isEmpty) {
    return EmptyPreview(
      examples: examples,
      onSubmit:

 _handleSubmit,
    );
  }

  final messages = loadedMessages.map((e) {
    final stateMessage =
        room.states[widget.stateManager.getKey(e.roomId ?? 0, e.id ?? 0)] ??
            MessageState();
    return MessageWithState(e, stateMessage);
  }).toList();

  _chatPreviewController.setAllMessageIds(messages);

  return ChatPreview(
    messages: messages,
    scrollController: _scrollController,
    controller: _chatPreviewController,
    stateManager: widget.stateManager,
    robotAvatar: selectMode ? null : _buildAvatar(room.room),
    onDeleteMessage: (id) {
      handleDeleteMessage(context, id, chatHistoryId: chatId);
    },
    onResentEvent: (message) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 500), curve: Curves.easeOut);

      _handleSubmit(message.text, messagetType: message.type);
    },
    onSpeakEvent: (message) {
      _audioPlayerController.playAudio(message.text);
    },
    helpWidgets: loadedState.processing || loadedMessages.last.isInitMessage()
        ? null
        : [HelpTips(onSubmitMessage: _handleSubmit)],
  );
}

/// Submit a new message
void _handleSubmit(String text, {messagetType = MessageType.text}) {
  setState(() {
    _inputEnabled.value = false;
  });

  context.read<ChatMessageBloc>().add(
        ChatMessageSendEvent(
          Message(
            Role.sender,
            text,
            user: 'me',
            ts: DateTime.now(),
            model: widget.model,
            type: messagetType,
            chatHistoryId: chatId,
          ),
        ),
      );

  context.read<NotifyBloc>().add(NotifyResetEvent());
  context
      .read<RoomBloc>()
      .add(RoomLoadEvent(chatAnywhereRoomId, cascading: false));
}

Widget _buildAvatar(Room room) {
  if (room.avatarUrl != null && room.avatarUrl!.startsWith('http')) {
    return RemoteAvatar(avatarUrl: room.avatarUrl!, size: 30);
  }

  return const LocalAvatar(assetName: 'assets/app.png', size: 30);
}