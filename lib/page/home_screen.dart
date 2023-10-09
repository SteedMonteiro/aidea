import 'package:askaide/helper/event.dart';
import 'package:askaide/lang/lang.dart';
import 'package:askaide/bloc/room_bloc.dart';
import 'package:askaide/page/component/background_container.dart';
import 'package:askaide/page/component/enhanced_button.dart';
import 'package:askaide/page/component/enhanced_error.dart';
import 'package:askaide/page/component/loading.dart';
import 'package:askaide/page/component/room_card.dart';
import 'package:askaide/page/component/sliver_component.dart';
import 'package:askaide/page/component/weak_text_button.dart';
import 'package:askaide/page/dialog.dart';
import 'package:askaide/page/rooms.dart';
import 'package:askaide/page/theme/custom_size.dart';
import 'package:askaide/page/theme/custom_theme.dart';
import 'package:askaide/repo/api/room_gallery.dart';
import 'package:askaide/repo/settings_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:go_router/go_router.dart';

class CharactersScreen extends StatefulWidget {
  final SettingRepository setting;
  const CharactersScreen({super.key, required this.setting}) : super(key: key);

  @override
  State<CharactersScreen> createState() => _CharactersScreenState();
}

class _CharactersScreenState extends State<CharactersScreen> {
  @override
  void initState() {
    context.read<RoomBloc>().add(RoomsLoadEvent());

    super.initState();
  }

  List<RoomGallery> selectedSuggestions = [];

  @override
  Widget build(BuildContext context) {
    var customColors = Theme.of(context).extension<CustomColors>()!;
    return BackgroundContainer(
      setting: widget.setting,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BlocConsumer<RoomBloc, RoomState>(
          listener: (context, state) {
            if (state is RoomsLoaded) {
              if (state.rooms.isNotEmpty) {
                selectedSuggestions.clear();
                setState(() {});
                GlobalEvent().emit('showBottomNavigatorBar');
              }
            }

            if (state is RoomCreateError) {
              showErrorMessageEnhanced(context, state.error);
            }
          },
          buildWhen: (previous, current) =>
              current is RoomsLoading || current is RoomsLoaded,
          builder: (context, state) {
            if (state is RoomsLoaded) {
              if (state.error != null) {
                return EnhancedErrorWidget(error: state.error);
              }

              return SliverComponent(
                actions: [
                  if (selectedSuggestions.isEmpty)
                    IconButton(
                      onPressed: () {
                        context.push('/create-room').whenComplete(() {
                          context.read<RoomBloc>().add(RoomsLoadEvent());
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                ],
                centerTitle: state.suggests.isEmpty,
                titlePadding: state.suggests.isEmpty
                    ? null
                    : const EdgeInsets.only(left: 0),
                title: state.suggests.isEmpty
                    ? Text(
                        AppLocale.homeTitle.getString(context),
                        style: TextStyle(
                          fontSize: CustomSize.appBarTitleSize,
                          color: customColors.backgroundInvertedColor,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 10, left: 10),
                            child: Text(
                              'Hot Recommendations',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: customColors.backgroundInvertedColor,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(
                                top: 0, left: 10, bottom: 10),
                            child: Text(
                              'Choose your exclusive partner',
                              style: TextStyle(
                                color: customColors.weakTextColorPlus,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                backgroundImage: Image.asset(
                  customColors.appBarBackgroundImageForRoom!,
                  fit: BoxFit.cover,
                ),
                child: RefreshIndicator(
                  color: customColors.linkColor,
                  onRefresh: () async {
                    context
                        .read<RoomBloc>()
                        .add(RoomsLoadEvent(forceRefresh: true));
                  },
                  displacement: 20,
                  child: buildBody(customColors, state, context),
                ),
              );
            }

            return const Center(
              child: LoadingIndicator(),
            );
          },
        ),
        bottomNavigationBar: selectedSuggestions.isNotEmpty
            ? SafeArea(
                child: Container(
                  height: 70,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      WeakTextButton(
                        title: 'Cancel',
                        onPressed: () {
                          selectedSuggestions.clear();
                          setState(() {});
                          GlobalEvent().emit('showBottomNavigatorBar');
                        },
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: EnhancedButton(
                            title: 'Add as Exclusive Partner',
                            onPressed: () {
                              context.read<RoomBloc>().add(GalleryRoomCopyEvent(
                                  selectedSuggestions
                                      .map((e) => e.id)
                                      .toList()));
                              showSuccessMessage(
                                  AppLocale.operateSuccess.getString(context));
                            }),
                      )
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget buildBody(
      CustomColors customColors, RoomsLoaded state, BuildContext context) {
    if (state.rooms.isEmpty && state.suggests.isEmpty) {
      return Center(
        // Empty list of characters
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            WeakTextButton(
              title: AppLocale.createRoom.getString(context),
              onPressed: () {
                context.push('/create-room').whenComplete(() {
                  context.read<RoomBloc>().add(RoomsLoadEvent());
                });
              },
              icon: Icons.add_circle,
            )
          ],
        ),
      );
    }

    if (state.suggests.isNotEmpty && state.rooms.isEmpty) {
      return SafeArea(
        top: false,
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: _calculateSuggestCrossAxisCount(),
          childAspectRatio: 0.8,
          padding: const EdgeInsets.all(10),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            ...state.suggests
                .map((item) => RoomCard(
                      item: item,
                      onItemSelected: onItemSelected,
                      selected: selectedSuggestions.contains(item),
                      selectedCheck: () {
                        if (selectedSuggestions.isNotEmpty) {
                          return;
                        }

                        GlobalEvent().emit('showBottomNavigatorBar');
                      },
                    ))
                .toList(),
            InkWell(
              onTap: () {
                if (selectedSuggestions.isNotEmpty) {
                  return;
                }

                context.push('/create-room').whenComplete(() {
                  context.read<RoomBloc>().add(RoomsLoadEvent());
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset('assets/transport.png'),
                          Icon(
                            Icons.interests,
                            size: 70,
                            color: customColors.weakLinkColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'View More',
                    style: TextStyle(
                      color: customColors.weakTextColor,
                      fontSize: 13,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      );
    }

    return SafeArea(
      top: false,
      child: ListView.builder(
        padding: const EdgeInsets.all(5),
        itemCount: state.rooms.length,
        itemBuilder: (context, index) {
          final room = state.rooms[index];

          return RoomItem(room: room);
        },
      ),
    );
  }

  void onItemSelected(RoomGallery item) {
    if (selectedSuggestions.contains(item)) {
      selectedSuggestions.remove(item);
    } else {
      selectedSuggestions.add(item);
    }

    setState(() {});

    if (selectedSuggestions.isEmpty) {
      GlobalEvent().emit('showBottomNavigatorBar');
    } else {
      GlobalEvent().emit('hideBottomNavigatorBar');
    }
  }

  int _calculateSuggestCrossAxisCount() {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = (width / 120).floor();
    return crossAxisCount > 7 ? 7 : crossAxisCount;
  }
}