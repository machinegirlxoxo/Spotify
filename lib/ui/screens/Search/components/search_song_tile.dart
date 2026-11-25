import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/models/media_Item_builder.dart';
import '/models/playling_from.dart';
import '/ui/player/player_controller.dart';
import '/ui/widgets/image_widget.dart';
import '/ui/widgets/songinfo_bottom_sheet.dart';

const _green = Color(0xFF1DB954);

/// Spotify-style search song row: cover, title/artist, 3-dot menu,
/// add (+) / added (green check) toggle. Tap plays the song.
class SearchSongTile extends StatefulWidget {
  const SearchSongTile(
      {super.key,
      required this.song,
      required this.queue,
      this.onPlayed,
      this.onRemove});
  final MediaItem song;

  /// all songs of the result list, so playback continues with the next ones
  final List<MediaItem> queue;

  /// called when the row is tapped to play (used to store Recents)
  final VoidCallback? onPlayed;

  /// when set, an X button is shown (Recents list)
  final VoidCallback? onRemove;

  @override
  State<SearchSongTile> createState() => _SearchSongTileState();
}

class _SearchSongTileState extends State<SearchSongTile> {
  bool _isFav = false;

  @override
  void initState() {
    super.initState();
    _loadFav();
  }

  Future<void> _loadFav() async {
    final box = await Hive.openBox("LIBFAV");
    if (mounted) setState(() => _isFav = box.containsKey(widget.song.id));
  }

  Future<void> _toggleFav() async {
    final box = await Hive.openBox("LIBFAV");
    if (_isFav) {
      await box.delete(widget.song.id);
    } else {
      await box.put(widget.song.id, MediaItemBuilder.toJson(widget.song));
    }
    if (mounted) setState(() => _isFav = !_isFav);
  }

  @override
  Widget build(BuildContext context) {
    final player = Get.find<PlayerController>();
    final song = widget.song;
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 10, right: 4),
      onTap: () {
        widget.onPlayed?.call();
        final index = widget.queue.indexWhere((e) => e.id == song.id);
        player.playPlayListSong(List<MediaItem>.from(widget.queue),
            index < 0 ? 0 : index,
            playfrom: PlaylingFrom(
                name: "search".tr, type: PlaylingFromType.SELECTION));
      },
      leading: ImageWidget(size: 55, song: song),
      title: Obx(() {
        final playing = player.currentSong.value?.id == song.id;
        return Text(song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium!.copyWith(
                color: playing ? _green : null,
                fontWeight: playing ? FontWeight.w700 : null));
      }),
      subtitle: Text("Song • ${song.artist ?? ""}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleSmall),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (widget.onRemove == null)
        IconButton(
          splashRadius: 20,
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            showModalBottomSheet(
              constraints: const BoxConstraints(maxWidth: 500),
              shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(10.0))),
              isScrollControlled: true,
              context: player.homeScaffoldkey.currentState!.context,
              barrierColor: Colors.transparent.withAlpha(100),
              builder: (context) => SongInfoBottomSheet(song),
            ).whenComplete(() {
              Get.delete<SongInfoController>();
              _loadFav();
            });
          },
        ),
        IconButton(
          splashRadius: 20,
          onPressed: _toggleFav,
          icon: _isFav
              ? Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                      color: _green, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 17, color: Colors.black),
                )
              : const Icon(Icons.add_circle_outline, size: 28),
        ),
        if (widget.onRemove != null)
          IconButton(
            splashRadius: 20,
            onPressed: widget.onRemove,
            icon: const Icon(Icons.close, size: 26),
          ),
      ]),
    );
  }
}
