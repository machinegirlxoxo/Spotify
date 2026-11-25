import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'components/search_item.dart';
import 'components/search_song_tile.dart';
import '/ui/screens/Settings/settings_screen_controller.dart';
import '../../widgets/modified_text_field.dart';
import '/ui/navigator.dart';
import 'search_screen_controller.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  @override
  void initState() {
    super.initState();
    // always start on screen 1 (white bar), never on the old screen 2
    final c = Get.put(SearchScreenController());
    c.isSearchMode.value = false;
    c.textInputController.clear();
    c.suggestionList.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SearchScreenController>();
    final settingsScreenController = Get.find<SettingsScreenController>();
    final topPadding = context.isLandscape ? 50.0 : 80.0;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Obx(
        () => Row(
          children: [
            settingsScreenController.isBottomNavBarEnabled.isFalse
                ? Container(
                    width: 60,
                    color:
                        Theme.of(context).navigationRailTheme.backgroundColor,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: topPadding),
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios_new,
                              color: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .color,
                            ),
                            onPressed: () {
                              Get.nestedKey(ScreenNavigationSetup.id)!
                                  .currentState!
                                  .pop();
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: 0),
            Expanded(
              child: Obx(() => c.isSearchMode.isTrue
                  ? _SearchPage(c: c, topPadding: topPadding)
                  : _SearchLanding(c: c, topPadding: topPadding)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen 1: "Search" title, white tappable bar and browse tiles.
class _SearchLanding extends StatelessWidget {
  const _SearchLanding({required this.c, required this.topPadding});
  final SearchScreenController c;
  final double topPadding;

  static const _tiles = <(String, Color)>[
    ("Pop", Color(0xFFDC148C)),
    ("Hip-Hop", Color(0xFFBA5D07)),
    ("Rock", Color(0xFFE91429)),
    ("Chill", Color(0xFF477D95)),
    ("Workout", Color(0xFF503750)),
    ("Party", Color(0xFF8D67AB)),
    ("K-pop", Color(0xFF1E3264)),
    ("Arabic", Color(0xFF006450)),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 16, 16, 300),
      children: [
        Text("search".tr,
            style: Theme.of(context)
                .textTheme
                .titleLarge!
                .copyWith(fontSize: 30, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: c.openSearch,
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(6)),
            child: Row(children: [
              const Icon(Icons.search, color: Colors.black, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text("searchDes".tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 22),
        Text("Browse all",
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: _tiles
              .map((t) => GestureDetector(
                    onTap: () {
                      Get.toNamed(ScreenNavigationSetup.searchResultScreen,
                          id: ScreenNavigationSetup.id, arguments: t.$1);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: t.$2, borderRadius: BorderRadius.circular(8)),
                      child: Text(t.$1,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

/// Screen 2: back arrow + input, Recents when empty, predictions + songs
/// while typing.
class _SearchPage extends StatelessWidget {
  const _SearchPage({required this.c, required this.topPadding});
  final SearchScreenController c;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // top bar like Spotify: arrow + field + clear
        Container(
          color: Color.lerp(theme.canvasColor, Colors.white, 0.1),
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: SizedBox(
            height: 64,
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: c.closeSearch),
            Expanded(
              child: ModifiedTextField(
                textCapitalization: TextCapitalization.sentences,
                controller: c.textInputController,
                textInputAction: TextInputAction.search,
                onChanged: c.onChanged,
                onSubmitted: (val) {
                  if (val.contains("https://")) {
                    c.filterLinks(Uri.parse(val));
                    c.reset();
                    return;
                  }
                  Get.toNamed(ScreenNavigationSetup.searchResultScreen,
                      id: ScreenNavigationSetup.id, arguments: val);
                  c.addToHistryQueryList(val);
                },
                autofocus: true,
                cursorColor: theme.textTheme.bodySmall!.color,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: "searchDes".tr,
                  suffixIcon: IconButton(
                    onPressed: c.reset,
                    icon: const Icon(Icons.close),
                    splashRadius: 18,
                  ),
                ),
              ),
            ),
          ]),
          ),
        ),
        Expanded(
          child: Obx(() {
            final text = c.textInputController.text;
            final typing = c.suggestionList.isNotEmpty && text != "";
            return ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 400),
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              children: c.urlPasted.isTrue
                  ? [
                      InkWell(
                        onTap: () {
                          c.filterLinks(Uri.parse(c.textInputController.text));
                          c.reset();
                        },
                        child: SizedBox(
                          width: double.maxFinite,
                          height: 80,
                          child: Center(
                              child: Text("urlSearchDes".tr,
                                  style: theme.textTheme.titleMedium)),
                        ),
                      )
                    ]
                  : typing
                      ? [
                          ...c.suggestionList.toList().map((item) =>
                              SearchItem(
                                  queryString: item, isHistoryString: false)),
                          if (text.trim().length > 1) ...[
                            const SizedBox(height: 8),
                            if (c.isSongsLoading.isTrue && c.songResults.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                    child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))),
                              ),
                            ...c.songResults.map((song) => SearchSongTile(
                                key: ValueKey(song.id),
                                song: song,
                                queue: c.songResults.toList(),
                                onPlayed: () => c.addRecent(song))),
                          ],
                        ]
                      : _recents(context),
            );
          }),
        ),
      ],
    );
  }

  List<Widget> _recents(BuildContext context) {
    if (c.recents.isEmpty) {
      // nothing played yet: fall back to text query history
      return c.historyQuerylist
          .toList()
          .map((item) => SearchItem(queryString: item, isHistoryString: true))
          .toList();
    }
    final list = c.recents.toList();
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Text("Recents",
            style: Theme.of(context)
                .textTheme
                .titleLarge!
                .copyWith(fontSize: 24, fontWeight: FontWeight.w800)),
      ),
      ...list.map((song) => SearchSongTile(
            key: ValueKey("recent_${song.id}"),
            song: song,
            queue: list,
            onPlayed: () => c.addRecent(song),
            onRemove: () => c.removeRecent(song.id),
          )),
    ];
  }
}
