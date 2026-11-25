import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:palette_generator/palette_generator.dart';
import '/utils/helper.dart';

class ThemeController extends GetxController {
  final primaryColor = Colors.deepPurple[400].obs;
  final textColor = Colors.white24.obs;
  final themedata = Rxn<ThemeData>();

  /// The method channel for setting the title bar color on Windows.
  final platform = const MethodChannel('win_titlebar_color');
  String? currentSongId;
  late Brightness systemBrightness;

  ThemeController() {
    systemBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;

    primaryColor.value =
        Color(Hive.box('appPrefs').get("themePrimaryColor") ?? 4278199603);

    changeThemeModeType(
        ThemeType.values[Hive.box('appPrefs').get("themeModeType") ?? 0]);

    _listenSystemBrightness();

    super.onInit();
  }

  void _listenSystemBrightness() {
    final platformDispatcher = WidgetsBinding.instance.platformDispatcher;
    platformDispatcher.onPlatformBrightnessChanged = () {
      systemBrightness = platformDispatcher.platformBrightness;
      changeThemeModeType(
          ThemeType.values[Hive.box('appPrefs').get("themeModeType")],
          sysCall: true);
    };
  }

  void changeThemeModeType(dynamic value, {bool sysCall = false}) {
    if (value == ThemeType.system) {
      themedata.value = _createThemeData(
          null,
          systemBrightness == Brightness.light
              ? ThemeType.light
              : ThemeType.dark);
    } else {
      if (sysCall) return;
      themedata.value = _createThemeData(
          value == ThemeType.dynamic
              ? _createMaterialColor(primaryColor.value!)
              : null,
          value);
    }
    setWindowsTitleBarColor(themedata.value!.scaffoldBackgroundColor);
  }

  void setTheme(ImageProvider imageProvider, String songId) async {
    if (songId == currentSongId) return;
    PaletteGenerator generator = await PaletteGenerator.fromImageProvider(
        ResizeImage(imageProvider, height: 200, width: 200));
    //final colorList = generator.colors;
    final paletteColor = generator.dominantColor ??
        generator.darkMutedColor ??
        generator.darkVibrantColor ??
        generator.lightMutedColor ??
        generator.lightVibrantColor;
    primaryColor.value = paletteColor!.color;
    textColor.value = paletteColor.bodyTextColor;
    // printINFO(paletteColor.color.computeLuminance().toString());0.11 ref
    if (paletteColor.color.computeLuminance() > 0.10) {
      primaryColor.value = paletteColor.color.withLightness(0.10);
      textColor.value = Colors.white54;
    }
    final primarySwatch = _createMaterialColor(primaryColor.value!);
    themedata.value = _createThemeData(primarySwatch, ThemeType.dynamic,
        textColor: textColor.value,
        titleColorSwatch: _createMaterialColor(textColor.value));
    currentSongId = songId;
    Hive.box('appPrefs').put("themePrimaryColor", (primaryColor.value!).toARGB32());
    setWindowsTitleBarColor(themedata.value!.scaffoldBackgroundColor);
  }

  ThemeData _createThemeData(MaterialColor? primarySwatch, ThemeType themeType,
      {MaterialColor? titleColorSwatch, Color? textColor}) {
    if (themeType == ThemeType.dynamic) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.light,
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.white.withValues(alpha: 0.002),
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.light,
            systemStatusBarContrastEnforced: false,
            systemNavigationBarContrastEnforced: true),
      );

      final baseTheme = ThemeData(
          useMaterial3: false,
          primaryColor: primarySwatch![500],
          colorScheme: ColorScheme.fromSwatch(
              accentColor: primarySwatch[200],
              brightness: Brightness.dark,
              backgroundColor: primarySwatch[700],
              primarySwatch: primarySwatch),
          //accentColor: primarySwatch[200],
          dialogTheme: DialogThemeData(backgroundColor: primarySwatch[700]),
          cardColor: primarySwatch[600],
          primaryColorLight: primarySwatch[400],
          primaryColorDark: primarySwatch[700],
          //secondaryHeaderColor: primarySwatch[50],
          canvasColor: primarySwatch[700],
          //scaffoldBackgroundColor: primarySwatch[700],
          bottomSheetTheme: BottomSheetThemeData(
              backgroundColor: primarySwatch[600],
              modalBarrierColor: primarySwatch[400]),
          textTheme: TextTheme(
            titleLarge: const TextStyle(
                fontSize: 23, fontWeight: FontWeight.bold, color: Colors.white),
            titleMedium: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white),
            titleSmall: TextStyle(color: primarySwatch[100]),
            bodyMedium: TextStyle(color: primarySwatch[100]),
            labelMedium: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 23,
                color: textColor ?? primarySwatch[50]),
            labelSmall: TextStyle(
                fontSize: 15,
                color: titleColorSwatch != null
                    ? titleColorSwatch[900]
                    : primarySwatch[100],
                letterSpacing: 0,
                fontWeight: FontWeight.bold),
          ),
          tabBarTheme: const TabBarThemeData(indicatorColor: Colors.white),
          progressIndicatorTheme: ProgressIndicatorThemeData(
              linearTrackColor: (primarySwatch[300])!.computeLuminance() > 0.3
                  ? Colors.black54
                  : Colors.white70,
              color: textColor),
          navigationRailTheme: NavigationRailThemeData(
              backgroundColor: primarySwatch[700],
              selectedIconTheme: const IconThemeData(color: Colors.white),
              unselectedIconTheme: IconThemeData(color: primarySwatch[100]),
              selectedLabelTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
              unselectedLabelTextStyle: TextStyle(
                  color: primarySwatch[100], fontWeight: FontWeight.bold)),
          sliderTheme: SliderThemeData(
            inactiveTrackColor: primarySwatch[300],
            activeTrackColor: textColor,
            valueIndicatorColor: primarySwatch[400],
            thumbColor: Colors.white,
          ),
          textSelectionTheme: TextSelectionThemeData(
              cursorColor: primarySwatch[200],
              selectionColor: primarySwatch[200],
              selectionHandleColor: primarySwatch[200])
          //scaffoldBackgroundColor: primarySwatch[700]
          );
      return baseTheme.copyWith(
          textTheme: GoogleFonts.figtreeTextTheme(baseTheme.textTheme));
    } else if (themeType == ThemeType.dark) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.light,
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.white.withValues(alpha: 0.002),
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.light,
            systemStatusBarContrastEnforced: false,
            systemNavigationBarContrastEnforced: true),
      );
      final baseTheme = ThemeData(
          useMaterial3: false,
          brightness: Brightness.dark,
          // Near-black base with lighter elevated surfaces and a green accent.
          canvasColor: const Color(0xFF121212),
          scaffoldBackgroundColor: const Color(0xFF121212),
          cardColor: const Color(0xFF181818),
          primaryColor: Colors.black,
          primaryColorDark: Colors.black,
          primaryColorLight: const Color(0xFF282828),
          colorScheme: ColorScheme.fromSwatch(
              accentColor: const Color(0xFF1ED760),
              brightness: Brightness.dark),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: Color(0xFF1ED760), linearTrackColor: Colors.white),
          textTheme: const TextTheme(
              titleLarge: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              titleMedium: TextStyle(
                fontWeight: FontWeight.bold,
              ),
              titleSmall: TextStyle(color: Color(0xFFB3B3B3)),
              labelMedium: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 23,
              ),
              labelSmall: TextStyle(
                  fontSize: 15, letterSpacing: 0, fontWeight: FontWeight.bold),
              bodyMedium: TextStyle(color: Color(0xFFB3B3B3))),
          navigationRailTheme: const NavigationRailThemeData(
              backgroundColor: Colors.black,
              selectedIconTheme: IconThemeData(
                color: Colors.white,
              ),
              unselectedIconTheme: IconThemeData(color: Color(0xFFB3B3B3)),
              selectedLabelTextStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
              unselectedLabelTextStyle: TextStyle(
                  color: Color(0xFFB3B3B3), fontWeight: FontWeight.bold)),
          bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Color(0xFF181818),
              modalBarrierColor: Colors.black),
          sliderTheme: const SliderThemeData(
            //base bar color
            inactiveTrackColor: Color(0xFF4D4D4D),
            //buffered progress
            activeTrackColor: Colors.white,
            //progress bar color
            valueIndicatorColor: Colors.black38,
            thumbColor: Colors.white,
          ),
          textSelectionTheme: const TextSelectionThemeData(
              cursorColor: Color(0xFF1ED760),
              selectionColor: Color(0x551ED760),
              selectionHandleColor: Color(0xFF1ED760)),
          dialogTheme: DialogThemeData(
              backgroundColor: const Color(0xFF282828),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          dividerColor: const Color(0x1AFFFFFF),
          iconTheme: const IconThemeData(color: Colors.white),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          chipTheme: ChipThemeData(
              backgroundColor: const Color(0xFF2A2A2A),
              selectedColor: const Color(0xFF1ED760),
              labelStyle: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
              secondaryLabelStyle: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.w600),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50))),
          switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? Colors.black
                      : const Color(0xFFB3B3B3)),
              trackColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? const Color(0xFF1ED760)
                      : const Color(0xFF3E3E3E))),
          elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1ED760),
                  foregroundColor: Colors.black,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700))),
          textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.white)),
          inputDecorationTheme: const InputDecorationTheme(
              focusColor: Colors.white,
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white))));
      return baseTheme.copyWith(
          textTheme: GoogleFonts.figtreeTextTheme(baseTheme.textTheme));
    } else {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.dark,
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.white.withValues(alpha: 0.002),
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.dark,
            systemStatusBarContrastEnforced: false,
            systemNavigationBarContrastEnforced: false),
      );
      final baseTheme = ThemeData(
          useMaterial3: false,
          brightness: Brightness.light,
          canvasColor: Colors.white,
          colorScheme: ColorScheme.fromSwatch(
              accentColor: Colors.grey[400],
              backgroundColor: Colors.white,
              cardColor: Colors.white,
              brightness: Brightness.light),
          primaryColor: Colors.white,
          primaryColorLight: Colors.grey[300],
          progressIndicatorTheme: ProgressIndicatorThemeData(
              linearTrackColor: Colors.grey[700], color: Colors.grey[400]),
          textTheme: TextTheme(
              titleLarge: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
              titleMedium: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              titleSmall: const TextStyle(),
              labelMedium: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 23,
              ),
              labelSmall: const TextStyle(
                  fontSize: 15, letterSpacing: 0, fontWeight: FontWeight.bold),
              bodyMedium: TextStyle(color: Colors.grey[700])),
          navigationRailTheme: NavigationRailThemeData(
              backgroundColor: Colors.white,
              selectedIconTheme: const IconThemeData(color: Colors.black),
              unselectedIconTheme: IconThemeData(color: Colors.grey[800]),
              selectedLabelTextStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
              unselectedLabelTextStyle: TextStyle(
                  color: Colors.grey[800], fontWeight: FontWeight.bold)),
          bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Colors.white, modalBarrierColor: Colors.white),
          sliderTheme: SliderThemeData(
            //base bar color
            inactiveTrackColor: Colors.black38,
            //buffered progress
            activeTrackColor: Colors.grey[800],
            //progress bar color
            valueIndicatorColor: Colors.white38,
            thumbColor: Colors.grey[800],
          ),
          textSelectionTheme: TextSelectionThemeData(
              cursorColor: Colors.grey[400],
              selectionColor: Colors.grey[400],
              selectionHandleColor: Colors.grey[400]),
          dialogTheme: DialogThemeData(backgroundColor: Colors.grey[200]),
          inputDecorationTheme: const InputDecorationTheme(
              focusColor: Colors.black,
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black))));
      return baseTheme.copyWith(
          textTheme: GoogleFonts.figtreeTextTheme(baseTheme.textTheme));
    }
  }

  MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.r8, g = color.g8, b = color.b8;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.toARGB32(), swatch);
  }

  Future<void> setWindowsTitleBarColor(Color color) async {
    if (!GetPlatform.isWindows) return;
    try {
      Future.delayed(
          const Duration(milliseconds: 350),
          () async => await platform.invokeMethod('setTitleBarColor', {
                'r': color.r8,
                'g': color.g8,
                'b': color.b8,
              }));
    } on PlatformException catch (e) {
      printERROR("Failed to set title bar color: ${e.message}");
    }
  }
}

extension ColorChannels8 on Color {
  int get a8 => (a * 255.0).round().clamp(0, 255);
  int get r8 => (r * 255.0).round().clamp(0, 255);
  int get g8 => (g * 255.0).round().clamp(0, 255);
  int get b8 => (b * 255.0).round().clamp(0, 255);
}

extension ComplementaryColor on Color {
  Color get complementaryColor => getComplementaryColor(this);
  Color getComplementaryColor(Color color) {
    int r = 255 - color.r8;
    int g = 255 - color.g8;
    int b = 255 - color.b8;
    return Color.fromARGB(color.a8, r, g, b);
  }
}

extension ColorWithHSL on Color {
  HSLColor get hsl => HSLColor.fromColor(this);

  Color withSaturation(double saturation) {
    return hsl.withSaturation(clampDouble(saturation, 0.0, 1.0)).toColor();
  }

  Color withLightness(double lightness) {
    return hsl.withLightness(clampDouble(lightness, 0.0, 1.0)).toColor();
  }

  Color withHue(double hue) {
    return hsl.withHue(clampDouble(hue, 0.0, 360.0)).toColor();
  }
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${a8.toRadixString(16).padLeft(2, '0')}'
      '${r8.toRadixString(16).padLeft(2, '0')}'
      '${g8.toRadixString(16).padLeft(2, '0')}'
      '${b8.toRadixString(16).padLeft(2, '0')}';
}

enum ThemeType {
  dynamic,
  system,
  dark,
  light,
}
