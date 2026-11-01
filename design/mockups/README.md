# Snippet mockup directions

Generated with the built-in image generation tool. These are concept boards, not individual 1080×2400 screen exports.

A — The Commonplace Book: ivory paper, oxblood, brass; literary serif with humanist sans UI.
B — Verse / Press: acid yellow, black, white, cobalt; condensed grotesk and mono labels.
C — Afterlight: midnight teal, seafoam, glacier cyan; rounded humanist sans and atmospheric photography.

## Shared screen prompt

Use case: ui-mockup. Create a high-fidelity Android mobile app design presentation for Snippet, a Bible verse quote-card PNG maker. Show EIGHT COMPLETE DISTINCT screens in a disciplined 4-column by 2-row grid, ordered left to right. Each screen has exact 1080:2400 portrait proportions, designed for 1080x2400 Android. Use very large high-resolution presentation canvas, crisp readable typography, tiny unobtrusive device outline, Android status/gesture areas, no perspective, no overlap. Number and label all eight screens outside the screen. All screens must be fully visible. Include a ninth small app icon concept next to the title. This is a comprehensive product design board with real functional UI, not wireframes. Maintain one exact design system throughout each board. Screens:
1 Home / verse picker: Snippet title, small outlined signed-out profile icon, KJV / WEB segmented translation toggle, Book Psalms dropdown, Chapter 46 stepper, verse range From 10 To 10, selected verse, Create card CTA, verse of the day. Home opens immediately without login.
2 Card editor: large live card preview with "Be still, and know that I am God." and "PSALM 46:10 · KJV". Controls labelled Background, Font, Color, Alignment with meaningful swatches/thumbnails, Save to library secondary action, Export primary action.
3 Export sheet: preview same card, aspect-ratio choices 1:1, 4:5, 9:16 with 4:5 selected, Save PNG and Share buttons. No auth required.
4 Optional sign-in bottom sheet over visibly dimmed editor, triggered specifically by Save to library: "Keep your inspiration" / "Sign in to save snippets and publish templates. Creating and exporting are always available." Continue with Google with Google G, Not now explicit button. Never a login wall.
5 My Library: Snippets / Templates tabs, a small saved snippet and a saved template shown as switching-state mini inset if needed, MAIN view clear empty state "Your collection starts here" / "Save a snippet you love." / Create a snippet. Make saved previews and empty state distinguishable as alternate states, not contradictory.
6 Template gallery: browse published community templates, 2-column large preview grid, creator names Maya Chen, Jordan Ellis, Ana Rivera. Each template has Use template and overflow with a visible Report template menu. Realistic short verse previews "The Lord is my shepherd; I shall not want." Psalm 23:1 KJV; "Let all that you do be done in love." 1 Corinthians 16:14 WEB.
7 Publish template flow: same styled preview, editable Name "Stillness", Description "A quiet space for words that matter.", note "Your style is shared, not your personal library.", Publish template primary CTA. Small confirmation overlay/state "Template published" / "Others can now use Stillness." Show this as a distinct completion inset. Signed-out tap Publish invokes same optional Google sheet, publication requires sign-in.
8 Profile / settings: clearly signed-in state, avatar Avery Morgan / avery@example.com / Connected with Google, settings Default translation KJV, Export quality High, About Snippet, Sign out.
Persistent bottom navigation Home / Templates / Library on primary destinations; editor/export back/close. Large accessible touch targets. Verse quotes must be accurate, never fabricated. Avoid generic purple gradient, tiny illegible UI, repeated layouts, decorative graphs. Board title clearly identifies option.

## Behavior

Open directly into Home. Picking verses, editing, exporting and using community templates require no sign-in. Save to library and Publish template present the optional Google bottom sheet to signed-out users. Not now dismisses it and preserves the current work. Publishing resumes after successful authentication and requires an explicit Publish template tap. My Library has mutually exclusive populated and empty states for each tab. Template overflow offers Report template; selecting it opens a reason sheet and an explicit Submit report action.

