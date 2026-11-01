import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../data/bible_models.dart';
import '../../data/bible_repository.dart';
import '../../services/services.dart';
import '../../services/verse_reminder_sync.dart';
import '../../widgets/pill_toggle.dart';
import '../../widgets/toast.dart';
import '../shell/shell_controller.dart';

/// Resolves the same passage in another version without changing its design.
class SwipeTranslationToggle extends StatefulWidget {
  const SwipeTranslationToggle({super.key, required this.passage});

  final Passage passage;

  @override
  State<SwipeTranslationToggle> createState() => _SwipeTranslationToggleState();
}

class _SwipeTranslationToggleState extends State<SwipeTranslationToggle> {
  int _request = 0;

  Future<void> _select(String id) async {
    final request = ++_request;
    if (id == widget.passage.translationId) return;
    final s = Services.of(context);
    final shell = ShellScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final range = widget.passage.range;
    try {
      final passage = await s.bible.passage(id, range);
      if (!mounted || request != _request || widget.passage.range != range) {
        return;
      }
      if (passage == null) {
        showToast(messenger, 'This passage is unavailable in that version.');
        return;
      }
      s.settings.defaultTranslationId = id;
      shell.setPassage(passage);
      syncAppVerseReminders(s);
    } catch (_) {
      if (mounted && request == _request) {
        showToast(messenger, 'Could not load this version. Try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PillToggle<String>(
      key: const Key('swipe-translation-toggle'),
      semanticLabel: 'Bible version',
      options: Services.of(context).bible.translationIds,
      selected: widget.passage.translationId,
      onChanged: _select,
      labelOf: (id) => BibleRepository.shortNames[id] ?? id,
      track: c.surfaceDark,
      selectedFill: c.cobalt,
      selectedText: c.white,
      text: c.mist,
      segmentWidth: 40,
      height: 28,
    );
  }
}
