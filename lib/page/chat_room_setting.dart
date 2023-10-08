import 'dart:io';
import 'dart:math';

import 'package:askaide/helper/ability.dart';
import 'package:askaide/helper/model.dart';
import 'package:askaide/helper/upload.dart';
import 'package:askaide/lang/lang.dart';
import 'package:askaide/page/chat_room_create.dart';
import 'package:askaide/page/component/avatar_selector.dart';
import 'package:askaide/page/component/background_container.dart';
import 'package:askaide/page/component/column_block.dart';
import 'package:askaide/page/component/enhanced_button.dart';
import 'package:askaide/page/component/enhanced_input.dart';
import 'package:askaide/page/component/enhanced_textfield.dart';
import 'package:askaide/page/component/image.dart';
import 'package:askaide/page/component/item_selector_search.dart';
import 'package:askaide/page/component/loading.dart';
import 'package:askaide/page/component/random_avatar.dart';
import 'package:askaide/page/theme/custom_size.dart';
import 'package:askaide/page/theme/custom_theme.dart';
import 'package:askaide/bloc/room_bloc.dart';
import 'package:askaide/page/dialog.dart';
import 'package:askaide/repo/api_server.dart';
import 'package:askaide/repo/model/model.dart' as mm;
import 'package:askaide/repo/settings_repo.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:go_router/go_router.dart';

class ChatRoomSettingScreen extends StatefulWidget {
  final int roomId;
  final SettingRepository setting;
  const ChatRoomSettingScreen(
      {super.key, required this.roomId, required this.setting});

  @override
  State<ChatRoomSettingScreen> createState() => _ChatRoomSettingScreenState();
}

class _ChatRoomSettingScreenState extends State<ChatRoomSettingScreen> {
  final _nameController = TextEditingController();
  final _promptController = TextEditingController(text: '');
  final _initMessageController = TextEditingController(text: '');

  final randomSeed = Random().nextInt(10000);

  String? _originalAvatarUrl;
  int? _originalAvatarId;

  String? _avatarUrl;
  int? _avatarId;

  List<String> avatarPresets = [];

  int maxContext = 5;

  List<ChatMemory> validMemories = [
    ChatMemory('No Memory', 1, description: 'Each conversation is independent, suitable for one-time Q&A'),
    ChatMemory('Basic', 5, description: 'Remember the last 5 conversations'),
    ChatMemory('Medium', 10, description: 'Remember the last 10 conversations'),
    ChatMemory('Deep', 20, description: 'Remember the last 20 conversations'),
  ];

  bool showAdvancedOptions = false;

  mm.Model? _selectedModel;

  @override
  void initState() {
    super.initState();

    BlocProvider.of<RoomBloc>(context)
        .add(RoomLoadEvent(widget.roomId, cascading: false));

    // Get preset avatars
    if (Ability().supportAPIServer()) {
      APIServer().avatars().then((value) {
        avatarPresets = value;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocale.roomSetting.getString(context),
          style: const TextStyle(fontSize: CustomSize.appBarTitleSize),
        ),
        centerTitle: true,
        elevation: 0,
        toolbarHeight: CustomSize.toolbarHeight,
      ),
      backgroundColor: customColors.backgroundContainerColor,
      body: BackgroundContainer(
        setting: widget.setting,
        enabled: false,
        child: BlocConsumer<RoomBloc, RoomState>(
          listener: (context, state) {
            if (state is RoomLoaded) {
              _nameController.text = state.room.name;
              _promptController.text = state.room.systemPrompt ?? '';
              maxContext = state.room.maxContext;
              _initMessageController.text = state.room.initMessage ?? '';

              ModelAggregate.model(state.room.model).then((value) {
                setState(() {
                  _selectedModel = value;
                });
              });

              if (state.room.avatarUrl != null && state.room.avatarUrl != '') {
                setState(() {
                  _avatarUrl = state.room.avatarUrl;
                  _avatarId = null;

                  _originalAvatarUrl = state.room.avatarUrl;
                  _originalAvatarId = null;
                });
              } else if (state.room.avatarId != null &&
                  state.room.avatarId != 0) {
                setState(() {
                  _avatarId = state.room.avatarId