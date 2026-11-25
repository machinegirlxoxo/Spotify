import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/models/album.dart';
import 'package:harmonymusic/models/artist.dart';

import 'package:harmonymusic/ui/screens/Artists/artist_screen.dart';
import 'package:harmonymusic/ui/screens/Home/home_screen.dart';

import 'screens/Album/album_screen.dart';
import 'screens/Playlist/playlist_screen.dart';
import 'screens/Search/search_result_screen.dart';
import 'screens/Search/search_screen.dart';

/// Old page fades to black, then the new page fades in (no slide).
class FadeThroughBlackTransition extends CustomTransition {
  @override
  Widget buildTransition(
      BuildContext context,
      Curve? curve,
      Alignment? alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    final fadeIn = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut));
    final fadeOut = ReverseAnimation(CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));
    return FadeTransition(
      opacity: fadeIn,
      child: ColoredBox(
        color: Colors.black,
        child: FadeTransition(opacity: fadeOut, child: child),
      ),
    );
  }
}

class ScreenNavigationSetup {
  ScreenNavigationSetup._();

  static const id = 1;
  static const homeScreen = '/homeScreen';
  static const searchScreen = '/searchScreen';
  static const searchResultScreen = '/searchResultScreen';
  static const artistScreen = '/artistScreen';
  static const albumScreen = '/albumScreen';
  static const playlistScreen = '/playlistScreen';
}

class ScreenNavigation extends StatelessWidget {
  const ScreenNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
        key: Get.nestedKey(ScreenNavigationSetup.id),
        initialRoute: '/homeScreen',
        onGenerateRoute: (settings) {
          Get.routing.args = settings.arguments;
          switch (settings.name) {

            case ScreenNavigationSetup.homeScreen:
              return GetPageRoute(
                  page: () => const HomeScreen(), settings: settings,
                  customTransition: FadeThroughBlackTransition(),
                  transitionDuration: const Duration(milliseconds: 350));
            
            case ScreenNavigationSetup.albumScreen:
              final id = (settings.arguments as (Album?, String)).$2;
              return GetPageRoute(
                  page: () => AlbumScreen(
                        key: Key(id),
                      ),
                  settings: settings,
                  customTransition: FadeThroughBlackTransition(),
                  transitionDuration: const Duration(milliseconds: 350));
            
            case ScreenNavigationSetup.playlistScreen:
             final id = (settings.arguments as List)[1] as String;
              return GetPageRoute(
                  page: () => PlaylistScreen(
                        key: Key(id),
                      ),
                  settings: settings,
                  customTransition: FadeThroughBlackTransition(),
                  transitionDuration: const Duration(milliseconds: 350));
            
            case ScreenNavigationSetup.searchScreen:
              return GetPageRoute(
                  page: () => const SearchScreen(), settings: settings,
                  customTransition: FadeThroughBlackTransition(),
                  transitionDuration: const Duration(milliseconds: 350));
            
            case ScreenNavigationSetup.searchResultScreen:
              return GetPageRoute(
                  page: () => const SearchResultScreen(), settings: settings,
                  customTransition: FadeThroughBlackTransition(),
                  transitionDuration: const Duration(milliseconds: 350));
            
            case ScreenNavigationSetup.artistScreen:
              final args = settings.arguments as List;
              final id = args[0] ? args[1] : (args[1] as Artist).browseId;
              return GetPageRoute(
                  page: () => ArtistScreen(
                        key: Key(id),
                      ),
                  settings: settings,
                  customTransition: FadeThroughBlackTransition(),
                  transitionDuration: const Duration(milliseconds: 350));
            
            default:
              return null;
          }
        });
  }
}
