import 'package:flutter/material.dart';

import '../../cards/card_shape.dart';
import '../../core/app_theme.dart';
import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../data/bible_repository.dart';
import '../../services/auth_service.dart';
import '../../services/services.dart';
import '../../widgets/arch_sheet.dart';
import '../../widgets/circle_button.dart';
import '../../widgets/cobalt_header.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/pill_toggle.dart';
import '../../widgets/snippet_switch.dart';
import '../library/library_screen.dart';
import 'profile_card.dart';
import 'settings_row.dart';
import 'settings_section.dart';

/// Account, preferences and about.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _pickShape(BuildContext context) async {
    final settings = Services.of(context).settings;
    final shape = await showArchSheet<CardShape>(
      context,
      builder: (ctx) {
        final c = ctx.colors;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Default shape',
              style: SnippetFonts.display(24, color: c.ink, letterSpacing: -1),
            ),
            const SizedBox(height: 12),
            for (final s in CardShape.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${s.label} ${s.ratioLabel}',
                  style: SnippetFonts.body(15, color: c.ink),
                ),
                trailing: s == settings.defaultShape
                    ? Icon(Icons.check_rounded, color: c.cobalt)
                    : null,
                onTap: () => Navigator.of(ctx).pop(s),
              ),
          ],
        );
      },
    );
    if (shape != null) settings.defaultShape = shape;
  }

  Future<void> _deleteAll(BuildContext context) async {
    final s = Services.of(context);
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account and data?'),
        content: const Text(
          'This removes every saved card and signs you out. It cannot be '
          'undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!(ok ?? false)) return;
    await s.library.clear();
    await s.auth.signOut();
    navigator.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = Services.of(context);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CobaltHeader(
            child: Row(
              children: [
                CircleButton(
                  tooltip: 'Back',
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 8),
                Text(
                  'Profile',
                  style: SnippetFonts.display(
                    21,
                    color: c.white,
                    letterSpacing: -0.7,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<AppUser?>(
              stream: s.auth.authStateChanges,
              initialData: s.auth.currentUser,
              builder: (context, snap) => ListenableBuilder(
                listenable: Listenable.merge([s.settings, s.library]),
                builder: (context, _) => _body(context, snap.data),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, AppUser? user) {
    final c = context.colors;
    final s = Services.of(context);
    final settings = s.settings;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        20,
        16,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      children: [
        if (user != null) ProfileCard(user: user),
        const SizedBox(height: 28),
        SettingsSection(
          title: 'Your cards',
          children: [
            SettingsRow(
              label: 'Saved cards',
              value: s.library.isLoaded ? '${s.library.cards.length}' : '',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LibraryScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SettingsSection(
          title: 'Preferences',
          children: [
            SettingsRow(
              label: 'Default translation',
              trailing: PillToggle<String>(
                semanticLabel: 'Default translation',
                options: s.bible.translationIds,
                selected: settings.defaultTranslationId,
                onChanged: (id) => settings.defaultTranslationId = id,
                labelOf: (id) => BibleRepository.shortNames[id] ?? id,
                track: c.surfaceDark,
                selectedFill: c.cobalt,
                selectedText: c.white,
                text: c.mist,
                segmentWidth: 40,
                height: 28,
              ),
            ),
            SettingsRow(
              label: 'Default shape',
              value:
                  '${settings.defaultShape.label} ${settings.defaultShape.ratioLabel}',
              onTap: () => _pickShape(context),
            ),
            SettingsRow(
              label: 'Small Snippet mark on exports',
              trailing: _switch(
                context,
                'Small Snippet mark on exports',
                settings.showMark,
                (v) => settings.showMark = v,
              ),
            ),
            SettingsRow(
              label: 'Swipe hints',
              trailing: _switch(
                context,
                'Swipe hints',
                settings.swipeHints,
                (v) => settings.swipeHints = v,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const SettingsSection(
          title: 'About',
          children: [
            SettingsRow(
              label: 'Bible texts',
              value: 'KJV & WEB, public domain',
            ),
            SettingsRow(label: 'Version', value: AppTheme.version),
          ],
        ),
        const SizedBox(height: 32),
        if (user != null) ...[
          PillButton(
            key: const Key('sign-out'),
            label: 'Sign out',
            icon: Icons.logout_rounded,
            onPressed: () async {
              final navigator = Navigator.of(context);
              await s.auth.signOut();
              navigator.popUntil((r) => r.isFirst);
            },
            foreground: c.white,
            height: 50,
            fontSize: 12.7,
            borderWidth: 1,
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => _deleteAll(context),
              child: Text(
                'Delete account and data',
                style: SnippetFonts.body(
                  10.7,
                  color: c.mist,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _switch(
    BuildContext context,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final c = context.colors;
    return SnippetSwitch(
      semanticLabel: label,
      value: value,
      onChanged: onChanged,
      onTrack: c.lime,
      onThumb: c.ink,
      offTrack: c.surfaceDark,
      offThumb: c.mist,
    );
  }
}
