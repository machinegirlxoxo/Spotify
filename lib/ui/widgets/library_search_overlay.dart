import 'package:flutter/material.dart';

import 'modified_text_field.dart';

/// Spotify-style "Search Your Library" tab.
///
/// Instead of an inline bar it opens a full-width top bar (back arrow + grey
/// field). While the field is empty a "Find your favorites" page covers the
/// library; once you type, the filtered library list shows underneath.
class LibrarySearchOverlay {
  LibrarySearchOverlay._();

  static OverlayEntry? _entry;
  static VoidCallback? _onClose;

  /// space the tab's list must leave for the top bar while searching
  static double spacerHeight = 0;

  static bool get isOpen => _entry != null;

  static void open(
    BuildContext context, {
    required TextEditingController textController,
    required void Function(String) onChanged,
    required VoidCallback onClose,
  }) {
    if (_entry != null) return;
    final overlay = Overlay.of(context);
    final route = ModalRoute.of(context);
    final statusBar = MediaQuery.of(context).padding.top;
    final barHeight = statusBar + 64;

    double top = 0;
    final box = context.findRenderObject();
    if (box is RenderBox && box.attached) top = box.localToGlobal(Offset.zero).dy;
    spacerHeight = (barHeight - top).clamp(0.0, 400.0);

    _onClose = onClose;
    textController.clear();
    _entry = OverlayEntry(
      builder: (ctx) => _Layer(
        textController: textController,
        onChanged: onChanged,
        barHeight: barHeight,
        onBack: close,
      ),
    );
    final entries = route?.overlayEntries;
    overlay.insert(_entry!,
        above: (entries != null && entries.isNotEmpty) ? entries.last : null);
  }

  static void close() {
    final entry = _entry;
    final cb = _onClose;
    _entry = null;
    _onClose = null;
    if (entry == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    entry.remove();
    cb?.call();
  }
}

class _Layer extends StatefulWidget {
  const _Layer(
      {required this.textController,
      required this.onChanged,
      required this.barHeight,
      required this.onBack});
  final TextEditingController textController;
  final void Function(String) onChanged;
  final double barHeight;
  final VoidCallback onBack;

  @override
  State<_Layer> createState() => _LayerState();
}

class _LayerState extends State<_Layer> {
  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.textController.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final isEmpty = widget.textController.text.isEmpty;
    final textTheme = Theme.of(context).textTheme;
    const radius = BorderRadius.all(Radius.circular(6));
    const none = OutlineInputBorder(
        borderSide: BorderSide.none, borderRadius: radius);
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // "Find your favorites" page, hides the library while empty
          if (isEmpty)
            Positioned.fill(
              child: ColoredBox(
                color: bg,
                child: Padding(
                  padding: EdgeInsets.only(top: widget.barHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Find your favorites",
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge!.copyWith(
                                  fontSize: 26, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 12),
                          Text(
                              "Search everything you've saved, followed, or created.",
                              textAlign: TextAlign.center,
                              style: textTheme.titleMedium!
                                  .copyWith(fontWeight: FontWeight.w400)),
                          SizedBox(height: widget.barHeight),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // top bar: back arrow + grey rounded field
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: widget.barHeight,
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top, right: 16),
              decoration: BoxDecoration(color: bg, boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 4)
              ]),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 24),
                    onPressed: widget.onBack,
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ModifiedTextField(
                        controller: widget.textController,
                        autofocus: true,
                        textAlignVertical: TextAlignVertical.center,
                        textInputAction: TextInputAction.search,
                        onChanged: widget.onChanged,
                        cursorColor: textTheme.bodySmall!.color,
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Color.lerp(bg, Colors.white, 0.12),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: none,
                          enabledBorder: none,
                          focusedBorder: none,
                          disabledBorder: none,
                          errorBorder: none,
                          focusedErrorBorder: none,
                          hintText: "Search Your Library",
                          hintStyle: textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.w700,
                              color: textTheme.titleSmall!.color),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
