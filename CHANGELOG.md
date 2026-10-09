# Changelog

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
