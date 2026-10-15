import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../core/theme/snippet_motion.dart';
import '../../widgets/circle_button.dart';

/// A short message from Remote Config, above the verse of the day.
///
/// Set [message] to null to hide it: the last message fades and the
/// banner collapses, so Home doesn't jump.
class AnnouncementBanner extends StatefulWidget {
  const AnnouncementBanner({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  final String? message;
  final VoidCallback onDismiss;

  @override
  State<AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends State<AnnouncementBanner> {
  /// Kept while collapsing, after [AnnouncementBanner.message] goes null.
  String? _shown;

  @override
  void initState() {
    super.initState();
    _shown = widget.message;
  }

  @override
  void didUpdateWidget(AnnouncementBanner old) {
    super.didUpdateWidget(old);
    if (widget.message != null) _shown = widget.message;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final visible = widget.message != null;
    final duration = SnippetMotion.reduce(context)
        ? SnippetMotion.reduced
        : SnippetMotion.exit;
    final text = _shown;
    if (text == null) return const SizedBox.shrink();
    return ClipRect(
      child: AnimatedAlign(
        alignment: Alignment.topCenter,
        heightFactor: visible ? 1 : 0,
        duration: duration,
        curve: SnippetMotion.easeOut,
        // Once collapsed, leave the tree entirely.
        onEnd: () {
          if (widget.message == null) setState(() => _shown = null);
        },
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: duration,
          curve: SnippetMotion.easeOut,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Semantics(
              container: true,
              label: 'Announcement',
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                decoration: BoxDecoration(
                  color: c.surfaceDark,
                  border: Border.all(color: c.lineDark),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: c.lime,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        text,
                        key: const Key('announcement-text'),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: SnippetFonts.body(
                          13,
                          color: c.white,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    CircleButton(
                      key: const Key('announcement-dismiss'),
                      tooltip: 'Dismiss',
                      icon: Icons.close_rounded,
                      size: 36,
                      foreground: c.mist,
                      background: c.surfaceDark,
                      borderColor: c.surfaceDark,
                      onPressed: visible ? widget.onDismiss : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
