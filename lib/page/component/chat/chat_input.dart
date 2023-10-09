import 'package:askaide/helper/ability.dart';
import 'package:askaide/helper/haptic_feedback.dart';
import 'package:askaide/helper/platform.dart';
import 'package:askaide/helper/upload.dart';
import 'package:askaide/lang/lang.dart';
import 'package:askaide/page/component/chat/voice_record.dart';
import 'package:askaide/page/dialog.dart';
import 'package:askaide/page/theme/custom_size.dart';
import 'package:askaide/repo/settings_repo.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:askaide/page/theme/custom_theme.dart';

class ChatInput extends StatefulWidget {
  final Function(String value) onSubmit;
  final ValueNotifier<bool> enableNotifier;
  final Widget? toolbar;
  final bool enableImageUpload;
  final Function()? onNewChat;
  final String hintText;
  final Function()? onVoiceRecordTappedEvent;

  const ChatInput({
    super.key,
    required this.onSubmit,
    required this.enableNotifier,
    this.enableImageUpload = true,
    this.toolbar,
    this.onNewChat,
    this.hintText = '',
    this.onVoiceRecordTappedEvent,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _textController = TextEditingController();

  /// Used to listen for keyboard events, implement sending messages on Enter, and line break on Shift+Enter
  late final FocusNode _focusNode = FocusNode(
    onKey: (node, event) {
      if (!event.isShiftPressed && event.logicalKey.keyLabel == 'Enter') {
        if (event is RawKeyDownEvent) {
          _handleSubmited(_textController.text.trim());
        }

        return KeyEventResult.handled;
      } else {
        return KeyEventResult.ignored;
      }
    },
  );

  final maxLength = 150000;

  @override
  void initState() {
    super.initState();

    _textController.addListener(() {
      setState(() {});
    });

    // Automatically focus on the input field after the robot finishes replying
    if (!PlatformTool.isAndroid() && !PlatformTool.isIOS()) {
      widget.enableNotifier.addListener(() {
        if (widget.enableNotifier.value) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: customColors.backgroundColor,
        // borderRadius: const BorderRadius.only(
        //   topLeft: Radius.circular(10),
        //   topRight: Radius.circular(10),
        // ),
        // boxShadow: const [
        //   BoxShadow(
        //     color: Color.fromARGB(31, 161, 161, 161),
        //     blurRadius: 5,
        //     spreadRadius: 0,
        //     offset: Offset(0, -5),
        //   ),
        // ],
      ),
      child: Builder(builder: (context) {
        final setting = context.read<SettingRepository>();
        if (widget.enableNotifier.value) {
          return Column(
            children: [
              // Toolbar
              if (widget.toolbar != null)
                Row(
                  children: [
                    Expanded(child: widget.toolbar!),
                    Text(
                      "${_textController.text.length}/$maxLength",
                      textScaleFactor: 0.8,
                      style: TextStyle(
                        color: customColors.chatInputPanelText,
                      ),
                    ),
                  ],
                ),
              // if (widget.toolbar != null)
              const SizedBox(height: 8),
              // Chat input area
              SingleChildScrollView(
                child: Slidable(
                  startActionPane: widget.onNewChat != null
                      ? ActionPane(
                          extentRatio: 0.3,
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              autoClose: true,
                              label: AppLocale.newChat.getString(context),
                              backgroundColor: Colors.blue,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(20)),
                              onPressed: (_) {
                                widget.onNewChat!();
                              },
                            ),
                            const SizedBox(width: 10),
                          ],
                        )
                      : null,
                  child: Row(
                    children: [
                      // Chat functionality buttons
                      Row(
                        children: [
                          if (widget.enableImageUpload &&
                              Ability().supportImageUploader())
                            _buildImageUploadButton(
                                context, setting, customColors),
                        ],
                      ),
                      // Chat input field
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: customColors.chatInputAreaBackground,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  enabled: widget.enableNotifier.value,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.newline,
                                  maxLines: 5,
                                  minLines: 1,
                                  maxLength: maxLength,
                                  focusNode: _focusNode,
                                  controller: _textController,
                                  // onSubmitted: _handleSubmited,
                                  decoration: InputDecoration(
                                    hintText: widget.hintText,
                                    hintStyle: const TextStyle(
                                      fontSize: CustomSize.defaultHintTextSize,
                                    ),
                                    border: InputBorder.none,
                                    counterText: '',
                                  ),
                                ),
                              ),
                              // Chat send button
                              _buildSendOrVoiceButton(context, customColors),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        /// Loading animation while replying
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingAnimationWidget.flickr(
              leftDotColor: const Color.fromARGB(255, 0, 214, 187),
              rightDotColor: const Color.fromARGB(255, 243, 133, 0),
              size: 40,
            ),
          ],
        );
      }),
    );
  }

  /// Build send or voice button
  Widget _buildSendOrVoiceButton(
    BuildContext context,
    CustomColors customColors,
  ) {
    return _textController.text == ''
        ? InkWell(
            onTap: () {
              HapticFeedbackHelper.mediumImpact();

              openModalBottomSheet(
                context,
                (context) {
                  return VoiceRecord(
                    onFinished: (text) {
                      _textController.text = text;
                      Navigator.pop(context);
                    },
                    onStart: () {
                      widget.onVoiceRecordTappedEvent?.call();
                    },
                  );
                },
                isScrollControlled: false,
                heightFactor: 0.8,
              );
            },
            child: Icon(
              Icons.mic,
              color: customColors.chatInputPanelText,
            ),
          )
        : IconButton(
            onPressed: () => _handleSubmited(_textController.text.trim()),
            icon: Icon(
              Icons.send,
              color: _textController.text.trim().isNotEmpty
                  ? const Color.fromARGB(255, 70, 165, 73)
                  : null,
            ),
            splashRadius: 20,
            tooltip: AppLocale.send.getString(context),
            color: customColors.chatInputPanelText,
          );
  }

  /// Build image upload button
  Widget _buildImageUploadButton(
    BuildContext context,
    SettingRepository setting,
    CustomColors customColors,
  ) {
    return IconButton(
      onPressed: () async {
        HapticFeedbackHelper.mediumImpact();
        FilePickerResult? result =
            await FilePicker.platform.pickFiles(type: FileType.image);
        if (result != null && result.files.isNotEmpty) {
          var cancel = BotToast.showCustomLoading(
              toastBuilder: (void Function() cancelFunc) {
            return Container(
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocale.uploading.getString(context),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  const CircularProgressIndicator(
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
            );
          });

          var upload = ImageUploader(setting).upload(result.files.single.path!);

          upload.then((value) {
_handleSubmited(
  '![${value.name}](${value.url})',
  notSend: true,
);
}).onError((error, stackTrace) {
  showErrorMessageEnhanced(context, error!);
}).whenComplete(() => cancel());
}
},
icon: const Icon(Icons.camera_alt),
color: customColors.chatInputPanelText,
splashRadius: 20,
tooltip: AppLocale.uploadImage.getString(context),
);
}

/// Handle input box submission
void _handleSubmited(String text, {bool notSend = false}) {
if (notSend) {
var cursorPos = _textController.selection.base.offset;
if (cursorPos < 0) {
  _textController.text = text;
} else {
  String suffixText = _textController.text.substring(cursorPos);
  String prefixText = _textController.text.substring(0, cursorPos);
  _textController.text = prefixText + text + suffixText;
  _textController.selection = TextSelection(
    baseOffset: cursorPos + text.length,
    extentOffset: cursorPos + text.length,
  );
}

_focusNode.requestFocus();

return;
}

if (text != '') {
widget.onSubmit(text);
_textController.clear();
}

_focusNode.requestFocus();
}
}
