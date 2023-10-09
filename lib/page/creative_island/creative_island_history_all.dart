import 'package:askaide/bloc/creative_island_bloc.dart';
import 'package:askaide/helper/constant.dart';
import 'package:askaide/helper/helper.dart';
import 'package:askaide/helper/image.dart';
import 'package:askaide/lang/lang.dart';
import 'package:askaide/page/component/background_container.dart';
import 'package:askaide/page/component/button.dart';
import 'package:askaide/page/component/image.dart';
import 'package:askaide/page/component/loading.dart';
import 'package:askaide/page/dialog.dart';
import 'package:askaide/page/draw/data/draw_history_datasource.dart';
import 'package:askaide/page/theme/custom_size.dart';
import 'package:askaide/page/theme/custom_theme.dart';
import 'package:askaide/repo/api/creative.dart';
import 'package:askaide/repo/api_server.dart';
import 'package:askaide/repo/settings_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_more_list/loading_more_list.dart';

class CreativeIslandHistoriesAllScreen extends StatefulWidget {
  final SettingRepository setting;
  final String mode;
  const CreativeIslandHistoriesAllScreen(
      {super.key, required this.setting, required this.mode});

  @override
  State<CreativeIslandHistoriesAllScreen> createState() =>
      _CreativeIslandHistoriesAllScreenState();
}

class _CreativeIslandHistoriesAllScreenState
    extends State<CreativeIslandHistoriesAllScreen> {
  final DrawHistoryDatasource datasource = DrawHistoryDatasource();

  @override
  void dispose() {
    datasource.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Creations',
          style: TextStyle(fontSize: CustomSize.appBarTitleSize),
        ),
        centerTitle: true,
        toolbarHeight: CustomSize.toolbarHeight,
      ),
      backgroundColor: customColors.backgroundContainerColor,
      body: BackgroundContainer(
        setting: widget.setting,
        enabled: false,
        maxWidth: 0,
        child: SafeArea(
          child: RefreshIndicator(
            color: customColors.linkColor,
            onRefresh: () async {
              context.read<CreativeIslandBloc>().add(
                  CreativeIslandHistoriesAllLoadEvent(
                      forceRefresh: true, mode: widget.mode));
            },
            child: LoadingMoreList(
              ListConfig<CreativeItemInServer>(
                extendedListDelegate:
                    SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _calCrossAxisCount(context),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, item, index) {
                  return Material(
                    // color: customColors.chatExampleItemBackground,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(10),
                    ),
                    // color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        context.push(
                            '/creative-island/${item.islandId}/history/${item.id}?show_error=true');
                      },
                      onLongPress: () {
                        openModalBottomSheet(
                          context,
                          (context) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(height: 20),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Button(
                                      title: 'View Creation',
                                      onPressed: () {
                                        context.push(
                                            '/creative-island/${item.islandId}/history/${item.id}?show_error=true');
                                        context.pop();
                                      },
                                      size: const ButtonSize.full(),
                                      color: customColors.weakLinkColor,
                                      backgroundColor: const Color.fromARGB(
                                          36, 222, 222, 222),
                                    ),
                                    const SizedBox(height: 10),
                                    Button(
                                      title: 'Delete Creation',
                                      onPressed: () {
                                        onItemDelete(
                                          context,
                                          item,
                                          index,
                                          onFinished: () {
                                            context.pop();
                                          },
                                        );
                                      },
                                      size: const ButtonSize.full(),
                                      color: customColors.weakLinkColor,
                                      backgroundColor: const Color.fromARGB(
                                          36, 222, 222, 222),
                                    ),
                                    const SizedBox(height: 10),
                                    Button(
                                      title:
                                          AppLocale.cancel.getString(context),
                                      backgroundColor: const Color.fromARGB(
                                          36, 222, 222, 222),
                                      color: customColors.dialogDefaultTextColor
                                          ?.withAlpha(150),
                                      onPressed: () {
                                        context.pop();
                                      },
                                      size: const ButtonSize.full(),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ],
                            );
                          },
                          heightFactor: 0.25,
                        );
                      },
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              _buildAnswerImagePreview(context, item),
                              // TODO Style name, for testing purposes
                              if (item.filterName != null &&
                                  item.filterName!.isNotEmpty)
                                Positioned(
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      item.filterName!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              if (item.isShared)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Public',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                buildIslandTypeText(customColors, item),
                                Text(
                                  humanTime(item.createdAt, withTime: true),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: customColors.weakTextColor
                                        ?.withAlpha(150),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                sourceList: datasource,
                padding: const EdgeInsets.all(10),
                indicatorBuilder: (context, status) {
                  String msg = '';
                  switch (status) {
                    case IndicatorStatus.noMoreLoad:
                      msg = '~ No more ~';
                      break;
                    case IndicatorStatus.loadingMoreBusying:
                      msg = 'Loading...';
                      break;
                    case IndicatorStatus.error:
                      msg = 'Failed to load, please try again later';
                      break;
                    case IndicatorStatus.empty:
                      msg = 'You have not created any creations yet';
                      break;
                    default:
                      return const Center(child: LoadingIndicator());
                  }
                  return Container(
                    padding: const EdgeInsets.all(15),
                    alignment: Alignment.center,
                    child: Text(
                      msg,
                      style: TextStyle(
                        color: customColors.weakTextColor,
                        fontSize: 14,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildIslandTypeText(
      CustomColors customColors, CreativeItemInServer item) {
    return Text(
      item.islandTitle ?? '',
      style: TextStyle(
        color: customColors.weakTextColor?.withAlpha(150),
        fontSize: 12,
      ),
    );
  }

  void onItemDelete(BuildContext context, CreativeItemInServer item, int index,
      {Function? onFinished}) {
    openConfirmDialog(context, AppLocale.confirmDelete.getString(context), () {
      APIServer()
          .deleteCreativeHistoryItem(item.islandId, hisId: item.id)
          .then((value) {
        // datasource.refresh(true);
        datasource.removeAt(index);
        setState(() {});
        showSuccessMessage(AppLocale.operateSuccess.getString(context));
        onFinished?.call();
      });
    });
  }

  Widget _buildAnswerImagePreview(
    BuildContext context,
    CreativeItemInServer item,
  ) {
    if (item.isImageType && item.images.isNotEmpty) {
      return ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 100,
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: CachedNetworkImageEnhanced(
                imageUrl:
                    imageURL(item.images.first, qiniuImageTypeThumbMedium),
                fit: BoxFit.cover,
              ),
            ),
            if (item.params['image'] != null && item.params['image'] != '')
              Positioned(
                left: 8,
                bottom: 8,
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImageEnhanced(
                      imageUrl:
                          imageURL(item.params['image'], qiniuImageTypeAvatar),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (item.isFailed) {
      return ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 150,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red,
              ),
              SizedBox(height: 10),
              Text('Création échouée', style: TextStyle(color: Colors.red))
            ],
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 150,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_bottom,
              size: 40,
              color: Colors.blue[700],
            ),
            const SizedBox(height: 10),
            Text('En cours de création', style: TextStyle(color: Colors.blue[700]))
          ],
        ),
      ),
    );
  }

  int _calCrossAxisCount(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    if (width > CustomSize.maxWindowSize) {
      width = CustomSize.maxWindowSize;
    }

    return (width / 220).round();
  }
}
