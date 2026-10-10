# Changelog

## 1.5.0-rc.21

- Apply ending-ellipsis truncation to custom text on action buttons with or without an icon; retain the configured `Text`, callback behavior, dimensions, and public API.
- Add five approved live rc.21 screenshots near the matching Quickstart, Controls, Key Systems, Loading, and Notifications guidance. Captions describe visible UI only and make no claim about key validation, clipboard behavior, keyboard interaction, or touch behavior.
- Official Luau compilation passed for the module, demo, and both visual suites (4 files, 13 KLOC, 746 KB bytecode). On Roblox client 67516 generation 1, ten suites passed 1,132 checks: Regression 10, Visual 68, Native Visual 9, Layout 34, Navigation 64, Key 95, Loading 67, Notifications 32, Icons 725, and Design 28.
- Add beginner guides for connecting an AI tool to the published MCP documentation and giving coding agents repository context; add the contextual Copy/MCP/Cursor/VS Code page menu and navigation entries. The public endpoint returned HTTP 200 for `initialize` with server name `GabibouUI`; 27-page Mintlify validation and four guide Luau-block compilations passed.
- Expand the existing icon catalogue with Outline previews for all 96 stable names and IDs, using unchanged exported PNGs. The IDs are library identifiers, not Roblox image asset IDs.
- Test-only corrections added 1e-5 float tolerance, adjusted navigation overflow/fit fixture sizes and cap, reset a progress option, verified close-glyph containment within its 40 px target, and removed an arbitrary Settings-density threshold. The module source did not change. Plain-button long-label rendering is not directly asserted; physical phone/tablet and touch checks remain outstanding.

## 1.5.0-rc.20

- Keep custom Get key, Discord, Cancel, and Verify labels intact and truncate only their displayed text with an ending ellipsis when button space is limited.
- Retain existing label length limits and default text; add no public API or font-scaling setting. Offline geometry checks pass; Roblox runtime and rendered-text validation are pending.

## 1.5.0-rc.19

- Improve centered-loader fit: crowded cards automatically omit the logo when less than 12 px would remain before the status area; title and subtitle stay centered.
- Keep the loader API and default layout unchanged. The source-extracted geometry harness passed 37 cases; Roblox runtime and rendered-layout validation are pending.

## 1.5.0-rc.18

- Adapt notifications to narrow and short viewports by clamping card/text/close geometry and hiding the badge, body text, or progress bar when space is insufficient.
- Keep normal desktop defaults and the existing notification API unchanged; runtime validation is pending.

## 1.5.0-rc.17

- Quiet the window header, control and section surfaces, and Rail navigation; use a 16 px tab icon with 1.5 px icon stroke, a 2 px selection marker, and neutral selected tile.
- Reorder the key gate so its credential well follows input and precedes Verify; retain 44 px secondary actions and existing automatic card heights.
- Refine notifications with a 40 px state badge, 16 px outer insets, a 44 px dismiss target, and a neutral card border without a vertical accent stripe.
- Existing public APIs remain available. Roblox runtime results are pending.

## 1.5.0-rc.16

- Refine Rail hover, keyboard-focus, and press states, preserving visible focus after the pointer leaves; animate button stroke and toggle track/knob states through the motion policy.
- Animate programmatic and keyboard slider changes while direct dragging tracks the pointer.
- Add toned key-status surfaces and focused-input transitions that follow Roblox's reduced-motion setting.
- Add a 0.2-second loader card/text entrance that settles before option updates and completion; progress can update during the entrance, and reduced motion skips it.
- Retouch ten primary Outline icons (home, sliders, search, close, settings, user, refresh, farm, minimize, and maximize); catalogue IDs remain unchanged. Export all 288 PNG and 288 SVG assets across three variants.
- Offline motion state-helper checks passed 8/8; connected-client runtime results are pending.

## 1.5.0-rc.15

- Add the opt-in Atelier preset and Rail navigation, with a distinct selected icon tile, neutral label track, and page-facing marker.
- Update the demo to show Atelier with Rail navigation and add a guide for the new options.
- Add an optional Quickstart preset comparison and Atelier window example, with a note about the published remote's candidate compatibility.
- Offline navigation logic checks pass; connected-client runtime validation remains pending.

## 1.5.0-rc.14

- Reduce main-window GUI depth and quiet Soft navigation states.
- Correct key-gate and loader avatar frames, theme-token borders and status surfaces, and developer override geometry.
- Expand the Quickstart with a callback connected to project state and an example of updating a saved control handle.
- Runtime validation is pending for this release candidate.

## 1.5.0-rc.13

- Add persistent key-gate part layout overrides with `SetPartLayout` and `ResetPartLayout`; responsive reflow and `Update` retain overrides until reset.
- Keep moved content reachable by expanding the key gate's scroll area for finite layouts; reject unbounded vertical extents before applying an override.
- Refine loading-screen mark, accent-rule, and compact-layout geometry while preserving dimmer and card transparency defaults.
- Add beginner Design-guide and API-reference examples for key-gate positioning and reset.

## 1.5.0-rc.12

- Add `Variant` to buttons: `Primary` (default), `Secondary`, and `Subtle`, each bound to the existing theme tokens.
- Refine notifications with a raised card, clearer status badge and text hierarchy, and a 2 px progress rule.
- Extend the Design guide with an executable example that uses primary and supporting actions.

## 1.5.0-rc.11

- Add `UI:RegisterDesign`, `UI:Design`, `UI:GetDesignNames`, and `UI:UnregisterDesign` for named reusable custom brand schemas.
- Keep built-in presets protected, reject duplicate registrations, clone registered schemas and returned lists, and support exact case-sensitive lookup.
- Permit human-readable UTF-8 names with spaces and hyphens while rejecting blank-only names and control characters.
- Expand the single Design guide with a complete named-brand setup and a short explanation of Roblox's reusable styling-token approach, linked to official Creator Hub documentation.

## 1.5.0-rc.10

- Add `UI:Design(options)` for reusable `Studio`, `Minimal`, and `Command` presets across windows, key gates, and loaders.
- Tune accent, panel/card transparency, corner radius, spacing density, tab placement, and navigation style through one validated design schema.
- Add a dedicated Design docs tab with a complete beginner setup, concise preset variations, responsive guidance, key/loading reuse, and extension examples.
- Existing constructor options keep precedence over design values; live changes continue through the existing setters.

## 1.5.0-rc.9

- Give the default Graphite shell a stronger original hierarchy: a raised navigation rail, a pale selected tab with dark text, clearer section headers, and contrasting primary actions.
- Keep the monochrome palette, theme-token binding, mobile tab layout, and minimum 44 px action targets.
- Expose the loader's `StatusPanel` through `GetParts()` and allow its position, size, anchor, and visibility to be configured with `SetPartLayout`.

## 1.5.0-rc.8

- Refine the Graphite window header and tab rail with a clearer title hierarchy, a restrained selection marker, and quieter surface states.
- Add `Layout.PanelTransparency` for the main window surface, separate from loader and key-gate card transparency.
- Add independent `CardTransparency` controls for loader and key-gate panels while keeping `BackgroundTransparency` for their full-screen dimmers.
- Explain panel and dimmer transparency separately in the customization guides.

## 1.5.0-rc.7

- Add `UI:KeyProvider` adapters for explicitly supplied Luarmor and VampAuth SDKs, a KeyAuth SDK bridge, and custom validators while keeping `Validate` callbacks compatible.
- Require a separate Luarmor SDK instance per `ScriptId` and fail closed if its ID changes after provider setup.
- Share KeyAuth initialization between simultaneous checks, retry failed initialization, and reject ambiguous responses.
- Add an optional server-side HTTP validation example that keeps provider credentials in Roblox Secrets and documents its provider-specific contract.
- Document external provider setup and client-side credential limitations; no provider service is called by the library automatically.

## 1.5.0-rc.6

- Add `ShowWatermark` and `SetWatermark` so developers can hide the library name/version while keeping the desktop hide-key hint and existing branding.
- Return unused mobile footer space to the content when its text is hidden.
- Keep first-use examples focused on the short window, tab, and callback flow.

## 1.5.0-rc.5

- Group navigation tabs with `window:Category("Workspace")` and `category:Tab("Home", "home")`.
- Category headings follow all four navigation positions, hide when empty or filtered, and participate in search.
- Rename or destroy categories, or assign a named category through table and declarative tab options.
- Add explained category examples and API references.

## 1.5.0-rc.4

- Added short constructors for windows, tabs, sections and controls, while preserving the full options-table API.
- Simplified onboarding around one-line remote loading and practical examples for every control.
- Use the fixed archive name `GabibouUI.zip` for distribution.

- Cancel library-managed Button, `Changed`, and `Connect` callback tasks when their control or window owner is destroyed; suppress errors and notifications from stale callbacks.
- Track yielding loader `OnError` callbacks and cancel them on `Destroy()`, including when an error callback starts another `Run()` attempt.
- Mark a `Launch` session destroyed and clean it up if its window is destroyed during a custom build; do not report `Ready` or call `OnReady` afterward.
- Do not call `KeySystem.OnCancel` when cancelling a launch session after key authentication has succeeded; the session-level `OnCancel` callback remains available.

## 1.5.0-rc.3

- The access screen now shows the local player's avatar by default and uses "Verify key" for its primary action. Custom images and monograms remain configurable.
- Added an English Mintlify documentation source with structured guides, API references and complete examples.
- Added a configurable Get key action with a provider link, custom callbacks and manual-copy fallback.

## 1.5.0-rc.2
- Redesigned the access screen with clearer key entry, validation state and actions.
- Added an optional blue Discord copy button with a local logo, custom copy handler and manual-copy fallback.
- Added Compact, Centered and Minimal loading layouts, progress thickness, persistent part overrides and custom content with owned cleanup.
- Refined window navigation, dialogs and control presentation.
- Added a complete English developer guide and focused loading/key examples.
- Fixed theme/style bindings disappearing under allocation pressure by retaining targets until explicit cleanup; destroyed targets release their listeners.

## 1.5.0-rc.1

Release candidate. See [QUALITY.md](QUALITY.md) for checks and remaining validation.

- Expanded original icon catalogue from 71 to 96 entries. Existing IDs 1-71 are preserved; new entries occupy 72-96.
- Redrawn navigation, gardening and utility glyphs with more consistent silhouettes and curves.
- Opaque Soft primitives keep overlapping curve segments at a consistent weight.
- Refined navigation states, notification layout and window styling.
- Removed the vertical accent line from notifications.
- Prepared a GitHub repository layout, tagged remote loading example and publishing guide.

## 1.4.1

- Added 32 icons for a total of 71.
- Rebuilt Refresh as two continuous arrowed arcs and fixed rounded segment joins.
- Made the Duotone gradient continuous along connected line segments.
- Split the demo gallery into batches to fit mobile component height limits.
