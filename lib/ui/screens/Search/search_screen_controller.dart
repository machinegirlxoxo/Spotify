import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/models/media_Item_builder.dart';
import '/utils/app_link_controller.dart' show ProcessLink;
import '/services/music_service.dart';

class SearchScreenController extends GetxController with ProcessLink {
  final textInputController = TextEditingController();
  final musicServices = Get.find<MusicServices>();
  final suggestionList = [].obs;
  final historyQuerylist = [].obs;
  late Box<dynamic> queryBox;
  final urlPasted = false.obs;

  /// Songs matching the current text, shown under the suggestions
  final songResults = <MediaItem>[].obs;
  final isSongsLoading = false.obs;

  /// false: landing page (white search bar), true: search page with Recents
  final isSearchMode = false.obs;

  /// Songs played from search, newest first
  final recents = <MediaItem>[].obs;
  Timer? _songDebounce;
  String _lastSongQuery = '';

  // Desktop search bar related
  final focusNode = FocusNode();
  final isSearchBarInFocus = false.obs;

  @override
  onInit() {
    _init();
    super.onInit();
  }

  _init() async {
    if(GetPlatform.isDesktop){
      focusNode.addListener((){
        isSearchBarInFocus.value = focusNode.hasFocus;
      });
    }
    _loadRecents();
    queryBox = await Hive.openBox("searchQuery");
    historyQuerylist.value = queryBox.values.toList().reversed.toList();
  }

  void _loadRecents() {
    final raw = Hive.box("AppPrefs").get("searchRecents");
    if (raw is List) {
      recents.value = raw
          .map<MediaItem?>((e) {
            try {
              return MediaItemBuilder.fromJson(e);
            } catch (_) {
              return null;
            }
          })
          .whereType<MediaItem>()
          .toList();
    }
  }

  void _saveRecents() {
    Hive.box("AppPrefs").put("searchRecents",
        recents.map((e) => MediaItemBuilder.toJson(e)).toList());
  }

  void addRecent(MediaItem song) {
    recents.removeWhere((e) => e.id == song.id);
    recents.insert(0, song);
    if (recents.length > 30) recents.removeRange(30, recents.length);
    _saveRecents();
  }

  void removeRecent(String id) {
    recents.removeWhere((e) => e.id == id);
    _saveRecents();
  }

  void openSearch() => isSearchMode.value = true;

  /// back to screen 1 without touching focus (used when switching tabs)
  void resetToLanding() {
    isSearchMode.value = false;
    textInputController.clear();
    suggestionList.clear();
    _songDebounce?.cancel();
    _lastSongQuery = '';
    songResults.clear();
    isSongsLoading.value = false;
  }

  void closeSearch() {
    reset();
    FocusManager.instance.primaryFocus?.unfocus();
    isSearchMode.value = false;
  }

  Future<void> onChanged(String text) async {
    if(text.contains("https://")){
      urlPasted.value = true; 
      return;
    }
    urlPasted.value = false;
    _searchSongsDebounced(text);
    suggestionList.value = await musicServices.getSearchSuggestion(text);
  }

  void _searchSongsDebounced(String text) {
    _songDebounce?.cancel();
    final query = text.trim();
    if (query.length < 2) {
      _lastSongQuery = '';
      songResults.clear();
      isSongsLoading.value = false;
      return;
    }
    isSongsLoading.value = true;
    _songDebounce = Timer(const Duration(milliseconds: 400), () async {
      _lastSongQuery = query;
      try {
        final res =
            await musicServices.search(query, filter: 'songs', limit: 20);
        // ignore stale responses
        if (_lastSongQuery != query) return;
        songResults.value =
            ((res['Songs'] as List?) ?? []).whereType<MediaItem>().toList();
      } catch (_) {
        if (_lastSongQuery == query) songResults.clear();
      } finally {
        if (_lastSongQuery == query) isSongsLoading.value = false;
      }
    });
  }

  Future<void> suggestionInput(String txt) async {
    textInputController.text = txt;
    textInputController.selection =
        TextSelection.collapsed(offset: textInputController.text.length);
    await onChanged(txt);
  }

  Future<void> addToHistryQueryList(String txt) async {
    if (historyQuerylist.length > 9) {
      final queryForRemoval = queryBox.getAt(0);
      await queryBox.deleteAt(0);
      historyQuerylist.removeWhere((element) => element == queryForRemoval);
    }
    if (!historyQuerylist.contains(txt)) {
      await queryBox.add(txt);
      historyQuerylist.insert(0, txt);
    }

    //reset current query and suggestionlist
    reset();
  }

  void reset() {
    urlPasted.value = false;
    textInputController.text = "";
    suggestionList.clear();
    _songDebounce?.cancel();
    _lastSongQuery = '';
    songResults.clear();
    isSongsLoading.value = false;
  }

  Future<void> removeQueryFromHistory(String txt) async {
    final index = queryBox.values.toList().indexOf(txt);
    await queryBox.deleteAt(index);
    historyQuerylist.remove(txt);
  }

  @override
  void dispose() {
    _songDebounce?.cancel();
    focusNode.dispose();
    textInputController.dispose();
    queryBox.close();
    super.dispose();
  }
}
