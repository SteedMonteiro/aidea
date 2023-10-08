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
  AppBar _buildAppBar