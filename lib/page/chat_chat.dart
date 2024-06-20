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
  if (promotionEvent!.clickValue != null &&
      promotionEvent!.clickValue!.isNotEmpty) {
    launchUrlString(promotionEvent!.clickValue!,
        mode: LaunchMode.externalApplication);
  }
  break;
  case PromotionEventClickButtonType.inAppRoute:
  if (promotionEvent!.clickValue != null &&
      promotionEvent!.clickValue!.isNotEmpty) {
    context.push(promotionEvent!.clickValue!);
  }
  break;
  case PromotionEventClickButtonType.none:
  }if (promotionEvent!.clickValue != null &&
    promotionEvent!.clickValue!.isNotEmpty) {
  launchUrlString(promotionEvent!.clickValue!,
      mode: LaunchMode.externalApplication);
}
break;
case PromotionEventClickButtonType.inAppRoute:
if (promotionEvent!.clickValue != null &&
    promotionEvent!.clickValue!.isNotEmpty) {
  context.push(promotionEvent!.clickValue!);
}
break;
case PromotionEventClickButtonType.none:
}
},
child: Row(
children: [
Text(
  'Details',
  style: TextStyle(
    color: stringToColor(
        promotionEvent!.clickButtonColor ?? 'FFFFFFFF'),
    fontSize: 14,
  ),
),
const SizedBox(width: 5),
Icon(
  Icons.keyboard_double_arrow_right,
  size: 16,
  color: stringToColor(
      promotionEvent!.clickButtonColor ?? 'FFFFFFFF'),
),
],
),
),
],
),
);

/// Build send or voice button
Widget _buildSendOrVoiceButton(
BuildContext context,
CustomColors customColors,
) {
return Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
crossAxisAlignment: CrossAxisAlignment.center,
children: [
InkWell(
onTap: () {
HapticFeedbackHelper.mediumImpact();

openModalBottomSheet(
  context,
  (context) {
    return VoiceRecord(
      onFinished: (text) {
        _textController.text = _textController.text + text;
        Navigator.pop(context);
      },
      onStart: () {},
    );
  },
  isScrollControlled: false,
  heightFactor: 0.8,
);
},
child: Icon(
Icons.mic,
color: customColors.chatInputPanelText,
size: 28,
),
),
BlocBuilder<FreeCountBloc, FreeCountState>(
buildWhen: (previous, current) => current is FreeCountLoadedState,
builder: (context, state) {
if (state is FreeCountLoadedState) {
  if (currentModel != null) {
    final matched = state.model(currentModel!.modelId);
    if (matched != null &&
        matched.leftCount > 0 &&
        matched.maxCount > 0) {
      return Text(
        'Today you can still enjoy ${matched.leftCount} times for free',
        style: TextStyle(
          color: customColors.weakTextColor?.withAlpha(120),
          fontSize: 11,
        ),
      );
    }
  }
}
return const SizedBox();
},
),
InkWell(
onTap: () {
if (_textController.text.trim().isEmpty) {
  return;
}

onSubmit(context, _textController.text.trim());
},
child: Icon(
Icons.send,
color: _textController.text.trim().isNotEmpty
    ? customColors.linkColor ??
        const Color.fromARGB(255, 70, 165, 73)
    : customColors.chatInputPanelText,
size: 26,
),
)
],
);
}

void onSubmit(BuildContext context, String text) {
context
.push(Uri(path: '/chat-anywhere', queryParameters: {
'init_message': text,
'model': currentModel?.modelId,
}).toString())
.whenComplete(() {
_textController.clear();
FocusScope.of(context).requestFocus(FocusNode());
context.read<ChatChatBloc>().add(ChatChatLoadRecentHistories());
});
}
}

class ChatHistoryItem extends StatelessWidget {
const ChatHistoryItem({
super.key,
required this.history,
required this.customColors,
required this.onTap,
});

final ChatHistory history;
final CustomColors customColors;
final VoidCallback onTap;

@override
Widget build(BuildContext context) {
return Container(
margin: const EdgeInsets.symmetric(
horizontal: 15,
vertical: 5,
),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(10),
),
child: Slidable(
endActionPane: ActionPane(
motion: const ScrollMotion(),
children: [
const SizedBox(width: 10),
SlidableAction(
label: AppLocale.delete.getString(context),
borderRadius: BorderRadius.circular(10),
backgroundColor: Colors.red,
icon: Icons.delete,
onPressed: (_) {
openConfirmDialog(
  context,
  AppLocale.confirmDelete.getString(context),
  () {
    context
        .read<ChatChatBloc>()
        .add(ChatChatDeleteHistory(history.id!));
  },
  danger: true,
);
},
),
],
),
child: Material(
color: customColors.backgroundColor?.withAlpha(200),
borderRadius: BorderRadius.all(
Radius.circular(customColors.borderRadius ?? 8),
),
child: InkWell(
child: ListTile(
contentPadding:
const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
shape: RoundedRectangleBorder(
borderRadius:
    BorderRadius.circular(customColors.borderRadius ?? 8),
),
title: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Expanded(
  child: Text(
    (history.title ?? 'Unnamed').trim(),
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      color: customColors.weakTextColor,
      fontSize: 15,
    ),
    maxLines: 1,
  ),
),
Text(
  humanTime(history.updatedAt),
  style: TextStyle(
    color: customColors.weakTextColor?.withAlpha(65),
    fontSize: 12,
  ),
),
],
),
dense: true,
subtitle: Padding(
padding: const EdgeInsets.only(top: 5),
child: Text(
  (history.lastMessage ?? 'No content yet').trim().replaceAll("\n", " "),
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(
    color: customColors.weakTextColor?.withAlpha(150),
    fontSize: 12,
    overflow: TextOverflow.ellipsis,
  ),
),
),
onTap: () {
HapticFeedbackHelper.lightImpact();
onTap();
},
),
),
),
),
);
}
}
