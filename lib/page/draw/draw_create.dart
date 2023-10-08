import 'dart:math';

import 'package:askaide/helper/constant.dart';
import 'package:askaide/helper/haptic_feedback.dart';
import 'package:askaide/helper/upload.dart';
import 'package:askaide/lang/lang.dart';
import 'package:askaide/page/component/background_container.dart';
import 'package:askaide/page/component/column_block.dart';
import 'package:askaide/page/component/enhanced_button.dart';
import 'package:askaide/page/component/enhanced_input.dart';
import 'package:askaide/page/component/enhanced_textfield.dart';
import 'package:askaide/page/component/item_selector_search.dart';
import 'package:askaide/page/component/loading.dart';
import 'package:askaide/page/component/prompt_tags_selector.dart';
import 'package:askaide/page/creative_island/content_preview.dart';
import 'package:askaide/page/creative_island/creative_island_result.dart';
import 'package:askaide/page/dialog.dart';
import 'package:askaide/page/draw/components/image_selector.dart';
import 'package:askaide/page/draw/components/image_size.dart';
import 'package:askaide/page/draw/components/image_style_selector.dart';
import 'package:askaide/page/theme/custom_size.dart';
import 'package:askaide/page/theme/custom_theme.dart';
import 'package:askaide/repo/api/creative.dart';
import 'package:askaide/repo/api_server.dart';
import 'package:askaide/repo/settings_repo.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:quickalert/models/quickalert_type.dart';

class DrawCreateScreen extends StatefulWidget {
  final SettingRepository setting;
  final int? galleryCopyId;
  final String mode;
  final String id;
  const DrawCreateScreen({
    super.key,
    required this.id,
    required this.setting,
    this.galleryCopyId,
    required this.mode,
  });

  @override
  State<DrawCreateScreen> createState() => _DrawCreateScreenState();
}

class _DrawCreateScreenState extends State<DrawCreateScreen> {
  String? selectedImagePath;
  Uint8List? selectedImageData;

  bool enableAIRewrite = true;
  int generationImageCount = 1;
  CreativeIslandVendorModel? selectedModel;
  String? upscaleBy;
  String selectedImageSize = '1:1';
  bool showAdvancedOptions = false;
  CreativeIslandImageFilter? selectedStyle;
  double? imageStrength = 0.5;

  /// Whether to stop periodic query task execution status
  var stopPeriodQuery = false;
  CreativeIslandCapacity? capacity;

  TextEditingController promptController = TextEditingController();
  TextEditingController negativePromptController = TextEditingController();
  TextEditingController seedController = TextEditingController();

  /// Whether to forcibly show negativePrompt
  bool forceShowNegativePrompt = false;

  @override
  void dispose() {
    promptController.dispose();
    negativePromptController.dispose();
    seedController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    APIServer()
        .creativeIslandCapacity(mode: widget.mode, id: widget.id)
        .then((cap) {
      setState(() {
        capacity = cap;
      });

      if (widget.galleryCopyId != null && widget.galleryCopyId! > 0) {
        APIServer()
            .creativeGalleryItem(id: widget.galleryCopyId!)
            .then((gallery) {
          if (gallery.prompt != null && gallery.prompt!.isNotEmpty) {
            promptController.text = gallery.prompt!;
          }

          if (gallery.negativePrompt != null &&
              gallery.negativePrompt!.isNotEmpty) {
            if (gallery.negativePrompt != null &&
                gallery.negativePrompt!.isNotEmpty) {
              forceShowNegativePrompt = true;
            }

            negativePromptController.text = gallery.negativePrompt!;
          }

          if (gallery.metaMap['model_id'] != null &&
              gallery.metaMap['model_id'] != '') {
            final matchedModels = capacity!.vendorModels.where((e) =>
                e.id == gallery.metaMap['model_id'] ||
                e.id == 'model-${gallery.metaMap['model_id']}');
            if (matchedModels.isNotEmpty) {
              selectedModel = matchedModels.first;
            }
          }

          if (gallery.metaMap['image_ratio'] != null &&
              gallery.metaMap['image_ratio'] != '') {
            selectedImageSize = gallery.metaMap['image_ratio']!;
          }

          if (gallery.metaMap['filter_id'] != null &&
              gallery.metaMap['filter_id'] > 0) {
            final matchedStyles = capacity!.filters
                .where((e) => e.id == gallery.metaMap['filter_id']);
            if (matchedStyles.isNotEmpty) {
              selectedStyle = matchedStyles.first;
            }
          }

          if (gallery.metaMap['real_prompt'] != null &&
              gallery.metaMap['real_prompt'] != '') {
            promptController.text = gallery.metaMap['real_prompt']!;
          }

          if (gallery.metaMap['negative_prompt'] != null &&
              gallery.metaMap['negative_prompt'] != '') {
            negativePromptController.text = gallery.metaMap['negative_prompt']!;
          }

          if (gallery.metaMap['real_negative_prompt'] != null &&
              gallery.metaMap['real_negative_prompt'] != '') {
            negativePromptController.text =
                gallery.metaMap['real_negative_prompt']!;
          }

          // When creating the same style, AI optimization is turned off by default, unless the same style includes ai_rewrite settings
          enableAIRewrite = false;
          if ((gallery.metaMap['real_prompt'] == null ||
                  gallery.metaMap['real_prompt'] == '') &&
              gallery.metaMap['ai_rewrite'] != null &&
              gallery.metaMap['ai_rewrite']) {
            enableAIRewrite = gallery.metaMap['ai_rewrite'];
          }

          setState(() {});
        });
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mode == 'image-to-image'
              ? AppLocale.imageToImage.getString(context)
              : AppLocale.textToImage.getString(context),
          style: const TextStyle(fontSize: CustomSize.appBarTitleSize),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
        toolbarHeight: CustomSize.toolbarHeight,
        backgroundColor: customColors.backgroundContainerColor,
      ),
      backgroundColor: customColors.backgroundContainerColor,
      body: BackgroundContainer(
        setting: widget.setting,
        enabled: true,
        maxWidth: CustomSize.smallWindowSize,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          height: double.infinity,
          child: SingleChildScrollView(
            child: buildEditPanel(context, customColors),
          ),
        ),
      ),
    );
  }

  Widget buildEditPanel(BuildContext context, CustomColors customColors) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ColumnBlock(
            innerPanding: 10,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            children: [
              // Upload image
              if (widget.mode == 'image-to-image')
                ImageSelector(
                  onImageSelected: ({path, data}) {
                    if (path != null) {
                      setState(() {
                        selectedImagePath = path;
                      });
                    }

                    if (data != null) {
                      setState(() {
                        selectedImageData = data;
                      });
                    }
                  },
                  selectedImagePath: selectedImagePath,
                  selectedImageData: selectedImageData,
                  title: AppLocale.referenceImage.getString(context),
                  height: _calImageSelectorHeight(context),
                  titleHelper: InkWell(
                    onTap: () {
                      showBeautyDialog(
                        context,
                        type: QuickAlertType.info,
                        text: AppLocale.referenceImageNote.getString(context),
                        confirmBtnText: AppLocale.gotIt.getString(context),
                        showCancelBtn: false,
                      );
                    },
                    child: Icon(
                      Icons.help_outline,
                      size: 16,
                      color: customColors.weakLinkColor?.withAlpha(150),
                    ),
                  ),
                ),

              // Image style
              if (capacity != null &&
                  capacity!.showStyle &&
                  capacity!.filters.isNotEmpty)
                ImageStyleSelector(
                  styles: capacity!.filters,
                  onSelected: (style) {
                    setState(() {
                      selectedStyle = style;
                    });
                  },
                  selectedStyle: selectedStyle,
                ),
            ],
          ),
          ColumnBlock(
            innerPanding: 10,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            children: [
              // Generate content
              if (widget.mode == 'text-to-image')
                ...buildPromptField(customColors),
              // AI optimization configuration
              if (capacity != null &&
                  capacity!.showAIRewrite &&
                  widget.mode != 'image-to-image')
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          AppLocale.smartOptimization.getString(context