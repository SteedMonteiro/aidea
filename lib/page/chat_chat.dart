import 'dart:math';

import 'package:askaide/bloc/chat_chat_bloc.dart';
import 'package:askaide/bloc/free_count_bloc.dart';
import 'package:askaide/helper/ability.dart';
import 'package:askaide/helper/color.dart';
import 'package:askaide/helper/haptic_feedback.dart';
import 'package:askaide/helper/helper.dart';
import 'package:askaide/helper/cache.dart';
import 'package:askaide/lang/lang.dart';
import 'package:askaide/page/component/background_container.dart';
import 'package:askaide/page/component/chat/empty.dart';
import 'package:askaide/page/component/chat/voice_record.dart';
import 'package:askaide/page/component/column_block.dart';
import 'package:askaide/page/component/enhanced_textfield.dart';
import 'package:askaide/page/component/model_indicator.dart';
import 'package:askaide/page/component/notify_message.dart';
import 'package:askaide/page/component/sliver_component.dart';
import 'package:askaide/page/dialog.dart';
import 'package:askaide/page/theme/custom_size.dart';
import 'package:askaide/page/theme/custom_theme.dart';
import 'package:askaide/repo/api_server.dart';
import 'package:askaide/repo/model/chat_history.dart';
import 'package:askaide/repo/settings_repo.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:go_router/go_router.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ChatChatScreen extends StatefulWidget {
  final SettingRepository setting;
  final bool showInitialDialog;
  final int? reward;
  const ChatChatScreen({
    super.key,
    required this.setting,
    this.showInitialDialog = false,
    this.reward,
  });

  @override
  State<ChatChatScreen> createState() => _ChatChatScreenState();
}

class ChatModel {
  String id;
  String name;
  Color backgroundColor;
  String backgroundImage;

  ChatModel({
    required this.id,
    required this.name,
    required this.backgroundColor,
    required this.backgroundImage,
  });
}

class _ChatChatScreenState extends State<ChatChatScreen> {
  final TextEditingController _textController = TextEditingController();

  ModelIndicatorInfo? currentModel;

  List<ModelIndicatorInfo> models = [
    ModelIndicatorInfo(
      modelId: "gpt-3.5-turbo",
      modelName: 'GPT-3.5',
      description: 'Fast speed, low cost',
      icon: Icons.bolt,
      activeColor: Colors.green,
    ),
    ModelIndicatorInfo(
      modelId: "gpt-4",
      modelName: 'GPT-4',
      description: 'Strong ability, more accurate',
      icon: Icons.auto_awesome,
      activeColor: const Color.fromARGB(255, 120, 73, 223),
    ),
  ];

  /// Whether to show the prompt message dialog
  bool showFreeModelNotifyMessage = false;

  /// Promotion event
  PromotionEvent? promotionEvent;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    context.read<ChatChatBloc>().add(ChatChatLoadRecentHistories());

    if (Ability().homeModels.isNotEmpty) {
      models = Ability()
          .homeModels
          .map((e) => ModelIndicatorInfo(
                modelId: e.modelId,
                modelName: e.name,
                description: e.desc,
                icon: e.powerful ? Icons.auto_awesome : Icons.bolt,
                activeColor: stringToColor(e.color),
              ))
          .toList();
    }

    // Whether to show free model prompt message
    Cache().boolGet(key: 'show_home_free_model_message').then((show) async {
      if (show) {
        final promotions = await APIServer().notificationPromotionEvents();
        if (promotions['chat_page'] == null ||
            promotions['chat_page']!.isEmpty) {
          return;
        }

        // If there are multiple promotion events, randomly select one
        promotionEvent = promotions['chat_page']![
            Random().nextInt(promotions['chat_page']!.length)];
      }

      setState(() {
        showFreeModelNotifyMessage = show;
      });
    });

    _textController.addListener(() {
      setState(() {});
    });

    setState(() {
      currentModel = models[0];
    });

    // Load the remaining usage times of the free model
    if (currentModel != null) {
      context
          .read<FreeCountBloc>()
          .add(FreeCountReloadEvent(model: currentModel!.modelId));
    }

    if (widget.showInitialDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showBeautyDialog(
          context,
          type: QuickAlertType.info,
          text:
              'Congratulations, your account has been successfully created! ${(widget.reward != null && widget.reward! > 0) ? '\n\nTo celebrate this moment, we have added ${widget.reward} wisdom fruits to your account.' : ''}',
          confirmBtnText: 'Start using',
          onConfirmBtnTap: () {
            context.pop();
          },
        );
      });
    } else {
      // Version check
      APIServer().versionCheck().then((resp) {
        final lastVersion = widget.setting.get('last_server_version');
        if (resp.serverVersion == lastVersion && !resp.forceUpdate) {
          return;
        }

        if (resp.hasUpdate) {
          showBeautyDialog(
            context,
            type: QuickAlertType.success,
            text: resp.message,
            confirmBtnText: 'Update',
            onConfirmBtnTap: () {
              launchUrlString(resp.url, mode: LaunchMode.externalApplication);
            },
            cancelBtnText: 'Update later',
            showCancelBtn: true,
          );
        }

        widget.setting.set('last_server_version', resp.serverVersion);
      });
    }

    super.initState();
  }

  Map<String, Widget> buildModelIndicators() {
    Map<String, Widget> map = {};
    for (var model in models) {
      map[model.modelId] = ModelIndicator(
        model: model,
        selected: model.modelId == currentModel?.modelId,
      );
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    var customColors = Theme.of(context).extension<CustomColors>()!;
    return BackgroundContainer(
      setting: widget.setting,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BlocBuilder<ChatChatBloc, ChatChatState>(
          buildWhen: (previous, current) =>
              current is ChatChatRecentHistoriesLoaded,
          builder: (context, state) {
            if (state is ChatChatRecentHistoriesLoaded) {
              return SliverSingleComponent(
                title: Text(
                  AppLocale.chatAnywhere.getString(context),
                  style: TextStyle(
                    fontSize: CustomSize.appBarTitleSize,
                    color: customColors.backgroundInvertedColor,
                  ),
                ),
                backgroundImage: Image.asset(
                  customColors.appBarBackgroundImage!,
                  fit: BoxFit.cover,
                ),
                appBarExtraWidgets: () {
                  return [
                    SliverStickyHeader(
                      header: SafeArea(
                        top: false,
                        child:
                            buildChatComponents(customColors, context, state),
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == 0) {
                              return SafeArea(
                                top: false,
                                bottom: false,
                                child: Container(
                                  margin:
                                      const EdgeInsets.only(top: 20, left: 15),
                                  child: Text(
                                    'History',
                                    style: TextStyle(
                                      color: customColors.weakTextColor
                                          ?.withAlpha(100),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return SafeArea(
                              top: false,
                              bottom: false,
                              child: ChatHistoryItem(
                                history: state.histories[index - 1],
                                customColors: customColors,
                                onTap: () {
                                  context
                                      .push(
                                          '/chat-anywhere?chat_id=${state.histories[index - 1].id}')
                                      .whenComplete(() {
                                    FocusScope.of(context)
                                        .requestFocus(FocusNode());
                                    context
                                        .read<ChatChatBloc>()
                                        .add(ChatChatLoadRecentHistories());
                                  });
                                },
                              ),
                            );
                          },
                          childCount: state.histories.isNotEmpty
                              ? state.histories.length + 1
                              : 0,
                        ),
                      ),
                    ),
                  ];
                },
              );
            } else {
              return const SizedBox();
            }
          },
        ),
      ),
    );
  }

  Container buildChatComponents(
    CustomColors customColors,
    BuildContext context,
    ChatChatRecentHistoriesLoaded state,
  ) {
    return Container(
      color: customColors.backgroundContainerColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Home notification message component
          if (showFreeModelNotifyMessage && promotionEvent != null)
            buildNotifyMessageWidget(context),
          // Model selection
          Container(
            margin: const EdgeInsets.only(
              left: 10,
              right: 10,
            ),
            padding: const EdgeInsets.only(
              left: 5,
              right: 5,
              top: 10,
            ),
            child: CustomSlidingSegmentedControl<String>(
              children: buildModelIndicators(),
              padding: 0,
              isStretch: true,
              height: 60,
              innerPadding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: customColors.columnBlockBackgroundColor?.withAlpha(150),
                borderRadius: BorderRadius.circular(8),
              ),
              thumbDecoration: BoxDecoration(
                color: currentModel?.activeColor ?? customColors.linkColor,
                borderRadius: BorderRadius.circular(6),
              ),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInToLinear,
              onValueChanged: (value) {
                currentModel =
                    models.firstWhere((element) => element.modelId == value);

                // Reload the free usage count of the model
                context
                    .read<FreeCountBloc>()
                    .add(FreeCountReloadEvent(model: value));

                setState(() {});
              },
            ),
          ),
          // Chat content input box
          Padding(
            padding: const EdgeInsets.only(
              left: 10,
              right: 10,
              top: 10,
            ),
            child: ColumnBlock(
              padding: const EdgeInsets.only(
                top: 5,
                bottom: 5,
                left: 15,
                right: 15,
              ),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chat question input box
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (currentModel != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 12,
                              right: 4,
                            ),
                            child: Icon(
                              Icons.circle,
                              color: currentModel!.activeColor,
                              size: 10,
                            ),
                          ),
                        Expanded(
                          child: EnhancedTextField(
                            controller: _textController,
                            customColors: customColors,
                            maxLines: 10,
                            minLines: 6,
                            hintText:
                                AppLocale.askMeAnyQuestion.getString(context),
                            maxLength: 150000,
                            showCounter: false,
                            hintColor: customColors.textfieldHintDeepColor,
                            hintTextSize: 15,
                          ),
                        ),
                      ],
                    ),
                    // Chat control toolbar
                    Container(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: _buildSendOrVoiceButton(
                        context,
                        customColors,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          // Question example
          if (state.examples != null &&
              state.examples!.isNotEmpty &&
              state.histories.isEmpty)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              padding:
                  const EdgeInsets.only(top: 5, left: 10, right: 10, bottom: 3),
              margin: const EdgeInsets.all(10),
              height: 260,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/app-256-transparent.png',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        AppLocale.askMeLikeThis.getString(context),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: customColors.textfieldHintDeepColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(0),
                      itemCount: state.examples!.length > 4
                          ? 4
                          : state.examples!.length,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return ListTextItem(
                          title: state.examples![index].title,
                          onTap: () {
                            onSubmit(
                              context,
                              state.examples![index].text,
                            );
                          },
                          customColors: customColors,
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return Divider(
                          color:
                              customColors.chatExampleItemText?.withAlpha(20),
                        );
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: ButtonStyle(
                        overlayColor:
                            MaterialStateProperty.all(Colors.transparent),
                      ),
                      onPressed: () {
                        setState(() {
                          state.examples!.shuffle();
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.refresh,
                            color: customColors.weakTextColor,
                            size: 16,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            AppLocale.refresh.getString(context),
                            style: TextStyle(
                              color: customColors.weakTextColor,
                            ),
                            textScaleFactor: 0.9,
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  NotifyMessageWidget buildNotifyMessageWidget(BuildContext context) {
    return NotifyMessageWidget(
      title: promotionEvent!.title != null
          ? Text(
              promotionEvent!.title!,
              style: TextStyle(
                color: stringToColor(promotionEvent!.textColor ?? 'FFFFFFFF'),
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
      backgroundImageUrl: promotionEvent!.backgroundImage,
      height: 85,
      closeable: promotionEvent!.closeable,
      onClose: () {
        setState(() {
          showFreeModelNotifyMessage = false;
        });

        Cache().setBool(
          key: 'show_home_free_model_message',
          value: false,
          duration: Duration(days: promotionEvent!.maxCloseDurationInDays ?? 7),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              promotionEvent!.content,
              style: TextStyle(
                color: stringToColor(promotionEvent!.textColor ?? 'FFFFFFFF'),
                fontSize: 14,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 2,
            ),
          ),
          if (promotionEvent!.clickButtonType !=
                  PromotionEventClickButtonType.none &&
              promotionEvent!.clickValue != null &&
              promotionEvent!.clickValue!.isNotEmpty)
            InkWell(
              onTap: () {
                switch (promotionEvent!.clickButtonType) {
                  case PromotionEventClickButtonType.url:
