import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/ui/screens/Home/home_screen_controller.dart';

/// Bottom navigation styled after Spotify's: near-black translucent bar,
/// no selection indicator, white active item and grey inactive items.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  static const _inactive = Color(0xFFB3B3B3);

  @override
  Widget build(BuildContext context) {
    final homeScreenController = Get.find<HomeScreenController>();
    return Obx(() => NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith((states) =>
              TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: states.contains(WidgetState.selected)
                      ? Colors.white
                      : _inactive)),
          iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              size: 26,
              color: states.contains(WidgetState.selected)
                  ? Colors.white
                  : _inactive)),
        ),
        child: NavigationBar(
            onDestinationSelected: homeScreenController.onBottonBarTabSelected,
            selectedIndex: homeScreenController.tabIndex.toInt(),
            backgroundColor: const Color(0xFF121212).withOpacity(0.96),
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            indicatorColor: Colors.transparent,
            elevation: 0,
            height: 62,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                selectedIcon: const Icon(Icons.home_rounded),
                icon: const Icon(Icons.home_outlined),
                label: modifyNgetlabel('home'.tr),
              ),
              NavigationDestination(
                selectedIcon: const Icon(Icons.search_rounded),
                icon: const Icon(Icons.search_rounded),
                label: modifyNgetlabel('search'.tr),
              ),
              NavigationDestination(
                selectedIcon: const Icon(Icons.library_music_rounded),
                icon: const Icon(Icons.library_music_outlined),
                label: modifyNgetlabel('library'.tr),
              ),
              NavigationDestination(
                selectedIcon: const Icon(Icons.settings_rounded),
                icon: const Icon(Icons.settings_outlined),
                label: modifyNgetlabel('settings'.tr),
              ),
            ])));
  }

  String modifyNgetlabel(String label) {
    if (label.length > 9) {
      return "${label.substring(0, 8)}..";
    }
    return label;
  }
}
