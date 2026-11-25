import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '/models/playling_from.dart';
import '/models/thumbnail.dart';
import '../../../services/downloader.dart';
import '../../player/player_controller.dart';
import '../../widgets/cover_gradient_background.dart';
import '../../widgets/snackbar.dart';
import 'album_screen_controller.dart';

const spotifyGreen = Color(0xFF1DB954);

/// Spotify-like album header: cover, title, artist, meta line and action row.
class AlbumHeader extends StatelessWidget {
  const AlbumHeader({super.key, required this.controller});
  final AlbumScreenController controller;

  @override
  Widget build(BuildContext context) {
    final player = Get.find<PlayerController>();
    final textTheme = Theme.of(context).textTheme;
    return Obx(() {
      final album = controller.album.value;
      final artists = album.artists?.map((e) => e['name']).join(", ") ?? "";
      final type = (album.description ?? "Album").isEmpty
          ? "Album"
          : album.description!;
      final meta = album.year == null ? type : "$type • ${album.year}";
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CoverArtHeader(imageUrl: album.thumbnailUrl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              album.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleLarge!
                  .copyWith(fontSize: 30, fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(children: [
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: Thumbnail(album.thumbnailUrl).medium,
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const SizedBox(width: 24, height: 24),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(artists,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium!
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(meta, style: textTheme.titleSmall),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
            child: Row(children: [
              // small cover thumb (like Spotify)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: Thumbnail(album.thumbnailUrl).medium,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const SizedBox(width: 44, height: 44),
                ),
              ),
              const SizedBox(width: 14),
              // add / added to library
              IconButton(
                tooltip: controller.isAddedToLibrary.isFalse
                    ? "addToLibrary".tr
                    : "removeFromLibrary".tr,
                onPressed: () {
                  final add = controller.isAddedToLibrary.isFalse;
                  controller
                      .addNremoveFromLibrary(album, add: add)
                      .then((ok) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(snackbar(
                        context,
                        ok
                            ? (add
                                ? "albumBookmarkAddAlert".tr
                                : "albumBookmarkRemoveAlert".tr)
                            : "operationFailed".tr,
                        size: SanckBarSize.MEDIUM));
                  });
                },
                icon: controller.isAddedToLibrary.isTrue
                    ? Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                            color: spotifyGreen, shape: BoxShape.circle),
                        child: const Icon(Icons.check,
                            size: 18, color: Colors.black),
                      )
                    : const Icon(Icons.add_circle_outline, size: 30),
              ),
              // download
              GetX<Downloader>(builder: (dl) {
                final id = album.browseId;
                final downloading = dl.playlistQueue.containsKey(id);
                return IconButton(
                  tooltip: "downloadAlbumSongs".tr,
                  onPressed: () {
                    if (controller.isDownloaded.isTrue) return;
                    dl.downloadPlaylist(id, controller.songList.toList());
                  },
                  icon: controller.isDownloaded.isTrue
                      ? Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                              color: spotifyGreen, shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_downward,
                              size: 18, color: Colors.black),
                        )
                      : downloading
                          ? const SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: spotifyGreen))
                          : const Icon(Icons.arrow_circle_down, size: 30),
                );
              }),
              // more
              IconButton(
                onPressed: () => _showMore(context, controller, player),
                icon: const Icon(Icons.more_vert),
              ),
              const Spacer(),
              // shuffle
              IconButton(
                tooltip: "shuffle".tr,
                onPressed: () {
                  final songs = List<MediaItem>.from(controller.songList)
                    ..shuffle();
                  if (songs.isEmpty) return;
                  player.playPlayListSong(songs, 0,
                      playfrom: PlaylingFrom(
                          name: album.title, type: PlaylingFromType.ALBUM));
                },
                icon: const Icon(Icons.shuffle, color: spotifyGreen, size: 28),
              ),
              // big green play
              GestureDetector(
                onTap: () {
                  if (controller.songList.isEmpty) return;
                  player.playPlayListSong(
                      List<MediaItem>.from(controller.songList), 0,
                      playfrom: PlaylingFrom(
                          name: album.title, type: PlaylingFromType.ALBUM));
                },
                child: Container(
                  width: 58,
                  height: 58,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: const BoxDecoration(
                      color: spotifyGreen, shape: BoxShape.circle),
                  child:
                      const Icon(Icons.play_arrow, color: Colors.black, size: 36),
                ),
              ),
            ]),
          ),
        ],
      );
    });
  }

  void _showMore(BuildContext context, AlbumScreenController c,
      PlayerController player) {
    showModalBottomSheet(
      constraints: const BoxConstraints(maxWidth: 500),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(10.0))),
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.merge),
            title: Text("enqueueAlbumSongs".tr),
            onTap: () {
              Navigator.of(ctx).pop();
              player.enqueueSongList(c.songList.toList()).whenComplete(() {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(snackbar(
                      context, "songEnqueueAlert".tr,
                      size: SanckBarSize.MEDIUM));
                }
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: Text("shareAlbum".tr),
            onTap: () {
              Navigator.of(ctx).pop();
              Share.share(
                  "https://youtube.com/playlist?list=${c.album.value.audioPlaylistId}");
            },
          ),
        ]),
      ),
    );
  }
}
