import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../widgets/async_tap.dart';
import '../../widgets/circle_button.dart';
import '../../widgets/profile_button.dart';

/// Back, the current reference (tap to change verse), and Profile.
class SwipeHeader extends StatelessWidget {
  const SwipeHeader({
    super.key,
    required this.reference,
    required this.translation,
    required this.onBack,
    required this.onProfile,
  });

  final String reference;
  final String translation;
  final VoidCallback onBack;
  final TapAction onProfile;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        CircleButton(
          tooltip: 'Back to verses',
          icon: Icons.arrow_back_rounded,
          onPressed: onBack,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Material(
            color: c.cobaltDeep,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onBack,
              child: SizedBox(
                height: 40,
                child: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          reference,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SnippetFonts.serifText(
                            17,
                            color: c.white,
                            height: 1,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: ShapeDecoration(
                          color: c.lime,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          translation,
                          style: SnippetFonts.display(
                            8,
                            weight: FontWeight.w700,
                            color: c.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.expand_more_rounded, color: c.white, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        ProfileButton(onPressed: onProfile),
      ],
    );
  }
}
