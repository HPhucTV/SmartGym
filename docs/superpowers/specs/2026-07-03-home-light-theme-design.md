# Home Light Theme Design

## Goal

Restyle the existing action-first Home screen to match the approved gym design system without changing its data, navigation, or content hierarchy.

## Palette

- Page background: white `#FFFFFF`.
- Primary text and structural emphasis: navy `#14213D`.
- Primary workout action: orange `#F97316`.
- Completion and progress: green `#22C55E`.
- Supporting surfaces: light gray `#F3F4F6`.
- Borders: neutral gray `#E5E7EB`.
- Muted text: slate `#64748B`.

Blue-neon accents, glow effects, dark page backgrounds, and gradients are removed from Home.

## Composition

- Preserve the current full-width vertical layout and all existing actions.
- Keep one navy workout hero as the dominant surface.
- Render the header, status cards, and secondary action cards on white or light-gray surfaces.
- Use orange for the workout CTA and active action emphasis.
- Use green for completion values and progress, with text labels so meaning does not rely only on color.

## Boundaries

- Do not change `HomeUiState`, repository calculations, or navigation routes.
- Do not redesign other screens.
- Preserve empty states, test tags, touch targets, and Vietnamese copy.
- Update Compose assertions to verify the Home background and key surface colors.

## Verification

- Compile and run the focused Home Compose tests when a device is available.
- Run the full JVM test suite.
- Build the debug APK.
- Confirm no dark-neon Home palette constants remain.
