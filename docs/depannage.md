# Troubleshooting

## The interface does not appear

| Symptom | Check |
|---|---|
| Nothing in Studio edit mode | Start Play; a LocalScript creates the menu. |
| `WaitForChild("GabibouUI")` waits forever | Check the exact ModuleScript name and placement in `ReplicatedStorage`. |
| `loadstring` or `HttpGet` error in Studio | Use the ModuleScript loader in [Getting started](demarrer.md). |
| Require or compile error | Copy the entire standalone module, not a partial source file. |
| Remote download fails | Check the module URL, network access and required client functions. |
| A visible window disappeared | Use `window:Show()` or the Open button after minimizing. Recreate destroyed windows. |

Read the first error in Output; later ones may follow from it.

## Unexpected control behavior

| Symptom | Cause or fix |
|---|---|
| Callback does not run during creation | Expected. Initialize project behavior explicitly. |
| `Set(value)` does not run callbacks | Use `Set(value, true)`; the value must change. |
| Duplicate ID | Give each control a unique ID; do not paste both alternative versions of an example. |
| Dropdown rejects a value | Value must exactly match an option. |
| Slider rejects parameters | Require `Min < Max`, `Step > 0`, finite numbers. |
| Shortcut fails | Leave text entry and provide a visible button if your environment intercepts the key. |
| Action shows an error notification | Read `window.LastError` and Output for the full callback error. |

## Profiles disappear after restarting

Memory is the default. Supply `Storage.Read/Write` and configure `StorageKey` before creating profiles. See [Values and profiles](valeurs-profils.md).

## Mobile content overflows

Start with `Responsive = {TouchTarget = 48}` and automatic layout. Custom content and `SetPartLayout` overrides must account for available width. Test portrait, landscape, keyboard visibility and minimize/restore. Geometry checks do not replace native device tests.

## A documented method is missing

Print `UI.Version` and check the installed source. Documentation follows `main`; pinned tags and old Studio copies may be behind. Update the module if needed and restart your test session.

## Report a reproducible problem

Include your loader, `UI.Version`, the first error and the smallest failing script. For layout issues include screen size and orientation. See [API methods](reference/api.md) and [defaults](reference/options.md).
