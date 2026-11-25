import 'package:audio_service/audio_service.dart' show MediaItem;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:widget_marquee/widget_marquee.dart';

import '../../models/playlist.dart';
import '../player/player_controller.dart';
import '../screens/Settings/settings_screen_controller.dart';
import 'add_to_playlist.dart';
import 'image_widget.dart';
import 'snackbar.dart';
import 'songinfo_bottom_sheet.dart';

class SongListTile extends StatelessWidget with RemoveSongFromPlaylistMixin {
  const SongListTile(
      {super.key,
      this.onTap,
      required this.song,
      this.playlist,
      this.isPlaylistOrAlbum = false,
      this.thumbReplacementWithIndex = false,
      this.compact = false,
      this.showThumb = false,
      this.index});
  final Playlist? playlist;
  final MediaItem song;
  final VoidCallback? onTap;
  final bool isPlaylistOrAlbum;

  /// Spotify-like row: no thumbnail/number, always shows the 3-dot menu
  final bool compact;

  /// with [compact]: keep a small thumbnail (playlists), albums hide it
  final bool showThumb;

  /// Valid for Album songs
  final bool thumbReplacementWithIndex;
  final int? index;

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();
    return Listener(
        onPointerDown: (PointerDownEvent event) {
          if (event.buttons == kSecondaryMouseButton) {
            //show songinfobotomsheet
            showModalBottomSheet(
              constraints: const BoxConstraints(maxWidth: 500),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
              ),
              isScrollControlled: true,
              context: playerController.homeScaffoldkey.currentState!.context,
              barrierColor: Colors.transparent.withAlpha(100),
              builder: (context) => SongInfoBottomSheet(
                song,
                playlist: playlist,
              ),
            ).whenComplete(() => Get.delete<SongInfoController>());
          }
        },
        child: Slidable(
          enabled:
              Get.find<SettingsScreenController>().slidableActionEnabled.isTrue,
          startActionPane: ActionPane(motion: const DrawerMotion(), children: [
            SlidableAction(
              onPressed: (context) {
                showDialog(
                  context: context,
                  builder: (context) => AddToPlaylist([song]),
                ).whenComplete(() => Get.delete<AddToPlaylistController>());
              },
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).textTheme.titleMedium!.color,
              icon: Icons.playlist_add,
              //label: 'Add to playlist',
            ),
            if (playlist != null && !playlist!.isCloudPlaylist)
              SlidableAction(
                onPressed: (context) {
                  removeSongFromPlaylist(song, playlist!);
                },
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).textTheme.titleMedium!.color,
                icon: Icons.delete,
                //label: 'delete',
              ),
          ]),
          endActionPane: ActionPane(motion: const DrawerMotion(), children: [
            SlidableAction(
              onPressed: (context) {
                playerController.enqueueSong(song).whenComplete(() {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(snackbar(
                      context, "songEnqueueAlert".tr,
                      size: SanckBarSize.MEDIUM));
                });
              },
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).textTheme.titleMedium!.color,
              icon: Icons.merge,
              //label: 'Enqueue',
            ),
            SlidableAction(
              onPressed: (context) {
                playerController.playNext(song);
                ScaffoldMessenger.of(context).showSnackBar(snackbar(
                    context, "${"playnextMsg".tr} ${(song).title}",
                    size: SanckBarSize.BIG));
              },
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).textTheme.titleMedium!.color,
              icon: Icons.next_plan_outlined,
              //label: 'Play Next',
            ),
          ]),
          child: ListTile(
            onTap: onTap,
            onLongPress: () async {
              showModalBottomSheet(
                constraints: const BoxConstraints(maxWidth: 500),
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(10.0)),
                ),
                isScrollControlled: true,
                context: playerController.homeScaffoldkey.currentState!.context,
                //constraints: BoxConstraints(maxHeight:Get.height),
                barrierColor: Colors.transparent.withAlpha(100),
                builder: (context) => SongInfoBottomSheet(
                  song,
                  playlist: playlist,
                ),
              ).whenComplete(() => Get.delete<SongInfoController>());
            },
            contentPadding: EdgeInsets.only(
                top: 0, left: compact ? 15 : 5, right: compact ? 4 : 30),
            dense: compact,
            visualDensity:
                compact ? const VisualDensity(horizontal: 0, vertical: -2) : null,
            minVerticalPadding: compact ? 2 : null,
            leading: compact
                ? (showThumb ? ImageWidget(size: 48, song: song) : null)
                : thumbReplacementWithIndex
                ? SizedBox(
                    width: 27.5,
                    height: 55,
                    child: Center(
                      child: Text(
                        "$index.",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  )
                : ImageWidget(
                    size: 55,
                    song: song,
                  ),
            title: Marquee(
              delay: const Duration(milliseconds: 300),
              duration: const Duration(seconds: 5),
              id: song.title.hashCode.toString(),
              child: Obx(() {
                final playing = isPlaylistOrAlbum &&
                    playerController.currentSong.value?.id == song.id;
                return Text(
                  song.title.length > 50
                      ? song.title.substring(0, 50)
                      : song.title,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontSize: compact ? 15.5 : null,
                      color: playing ? const Color(0xFF1DB954) : null,
                      fontWeight: playing
                          ? FontWeight.w700
                          : (compact ? FontWeight.w400 : null)),
                );
              }),
            ),
            subtitle: Text(
              "${song.artist}",
              maxLines: 1,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(fontSize: compact ? 13 : null),
            ),
            trailing: compact
                ? IconButton(
                    splashRadius: 20,
                    onPressed: () {
                      showModalBottomSheet(
                        constraints: const BoxConstraints(maxWidth: 500),
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(10.0)),
                        ),
                        isScrollControlled: true,
                        context: playerController
                            .homeScaffoldkey.currentState!.context,
                        barrierColor: Colors.transparent.withAlpha(100),
                        builder: (context) => SongInfoBottomSheet(
                          song,
                          playlist: playlist,
                        ),
                      ).whenComplete(() => Get.delete<SongInfoController>());
                    },
                    icon: const Icon(Icons.more_vert))
                : SizedBox(
              width: Get.size.width > 800 ? 80 : 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isPlaylistOrAlbum)
                        Obx(() =>
                            playerController.currentSong.value?.id == song.id
                                ? const Icon(
                                    Icons.equalizer,
                                  )
                                : const SizedBox.shrink()),
                      Text(
                        song.extras!['length'] ?? "",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  if (GetPlatform.isDesktop)
                    IconButton(
                        splashRadius: 20,
                        onPressed: () {
                          showModalBottomSheet(
                            constraints: const BoxConstraints(maxWidth: 500),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(10.0)),
                            ),
                            isScrollControlled: true,
                            context: playerController
                                .homeScaffoldkey.currentState!.context,
                            //constraints: BoxConstraints(maxHeight:Get.height),
                            barrierColor: Colors.transparent.withAlpha(100),
                            builder: (context) => SongInfoBottomSheet(
                              song,
                              playlist: playlist,
                            ),
                          ).whenComplete(
                              () => Get.delete<SongInfoController>());
                        },
                        icon: const Icon(Icons.more_vert))
                ],
              ),
            ),
          ),
        ));
  }
}
