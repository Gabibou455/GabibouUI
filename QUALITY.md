# Quality status: 1.5.0-rc.21 release candidate

The rc.21 button-label change applies ending-ellipsis truncation to custom action-button text whether or not an icon is present. The configured `Text`, callback behavior, button dimensions, and public API are unchanged. The integrated module, demo, and both visual test files passed official Luau compilation (4 files; 13 KLOC, 746 KB bytecode). Module SHA-256: `5407c1d6a40422005d292289e55740dbb55f9982d52227206db6cdd03e57d6f5`.

## Local validation and pending Roblox checks

- Official Luau compilation passed for the integrated module, demo, and both visual test files (4 files; 13 KLOC, 746 KB bytecode).
- On Roblox client 67516, generation 1, ten suites passed 1,132 checks: Regression 10/10, Visual 68/68, Native Visual 9/9, Layout 34/34, Navigation 64/64, Key 95/95, Loading 67/67, Notifications 32/32, Icons 725/725, and Design 28/28. These checks validate their listed assertions; they do not directly verify rendered long-label ellipsis behavior for the new plain-button case.
- Test-only updates added a 1e-5 tolerance to float expectations (.42/.62/.66/.72), adjusted the navigation fixture to test overflow at 360 px and fit at 420 px with a 220 px cap, reset a progress option between checks, checked close-glyph containment within the 40 px dismiss target, and removed an arbitrary 30-primitive Settings-density threshold. These are test corrections; the integrated UI module did not change.
- The earlier Design evaluation timeout is retained in the evidence; an instrumented bounded run later completed all 28 assertions in under one second. The timeout did not establish a module defect.
- Quickstart and Controls include the approved live rc.21 controls capture (`controls-examples.png`, SHA-256 `2962f42beebdf386a7049e988897bdceb2ddfe64dca8707548a8168db5847b64`). Controls, Key Systems, Loading, and Notifications also include approved rc.21 screenshots. They document visible rendering only; the key image does not establish key validation or clipboard behavior, and none of the images establishes keyboard or touch interaction.
- Full Mintlify validation passed for 27 MDX pages and 27 navigation pages, with zero broken links. The AI/MCP guide and AI agent guide compiled; four guide Luau blocks passed official compilation. The public MCP endpoint previously returned HTTP 200 to `initialize` with server name `GabibouUI`. The icon catalogue now previews all 96 names and IDs using unchanged Outline exports.
- Physical phone/tablet touch, virtual keyboard behavior, Studio execution, and environment compatibility beyond the tested Windows client remain unverified.

## Previous release candidate: rc.20 (historical)

The rc.20 key-gate label-containment change is a pre-release candidate. Get key and Discord labels retain their configured strings (up to 48 characters); Cancel and Verify labels retain theirs (up to 32), with only rendered button text receiving an ending ellipsis when space is limited. Defaults and public APIs are unchanged. Official Luau compilation passed for the integrated module, demo, and key-system test file (3 files; 13 KLOC, 770 KB bytecode). An offline geometry harness passed 8 layout cases after verifying the exact extracted placement logic against the integrated source. It uses UDim math and does not test Roblox text rendering, font measurement, or visible ellipsis behavior. Roblox runtime/rendered-UI results are pending.

## Local validation and pending Roblox checks

- Official Luau compilation passed for the integrated module, demo, and key-system test file (3 files; 13 KLOC, 770 KB bytecode).
- The exact key layout placement logic passed 8 offline geometry cases; details and limitations are recorded in `evidence/rc20_key_label_layout_harness.proof.txt`.
- Full Mintlify validation passed for 25 MDX pages and 25 navigation pages, with no broken internal links.
- Quickstart and Controls now include four existing reference images; the overview visibly identifies rc.5, and the control images are labeled as earlier references. They are not claimed as current rc.20 runtime captures.
- The Design guide adds an Atelier transparency recipe; its Luau example compiled with the official compiler and was not run in Roblox.
- Roblox runtime and rendered-text validation are pending.

## Previous release candidate: rc.19 (historical)

The rc.19 standalone module hash `19565a40b9fe5389571a1b029b9890f420664921fc45690f23ebb14298139eed` is a pre-release candidate. Official Luau compilation passed for the integrated module, demo, and loading test file (3 files; 13 KLOC, 748 KB bytecode). The exact extracted `Loader:_Layout` helper passed 37 offline geometry cases; it omits the logo when a centered layout would leave less than 12 px before the status area and keeps text centered. The loader API and default layout are unchanged. This harness uses geometry stubs and does not validate Roblox fonts, rendering, or interaction. Full Mintlify validation passed for 25 MDX pages and 25 navigation pages with no broken internal links. Roblox runtime/rendered-layout checks are pending.

## Local validation and pending Roblox checks

- Official Luau compilation passed for the integrated module, demo, and loading test file (3 files; 13 KLOC, 748 KB bytecode).
- Loader geometry harness passed 37 source-extracted cases; source/method/harness hashes, threshold probes, and stub limits are recorded in `evidence/rc19_loader_layout_harness.proof.txt`.
- Full Mintlify validation passed for 25 MDX pages and 25 navigation pages, with no broken internal links.
- Roblox runtime and rendered-layout validation are pending.

## Previous release candidate: rc.18 (historical)

The rc.18 standalone module hash `f055baff148b06727f3ec9284dbf49e717b90b6f59108205a5f5acc1df552384` is a pre-release candidate. Official Luau compilation passed for the integrated module, demo, and notification test file (3 files; 13 KLOC, 733 KB bytecode). An offline harness passed 16 notification-layout geometry cases using the exact extracted `Window:_LayoutNotifications` method. The harness checks four anchor positions, minimum configured width, narrow and tiny viewports, body/title/progress separation, and close-glyph containment with deterministic stubs. It does not verify Roblox font measurement, rendering, or UI interaction. The fallback keeps the existing notification API and desktop geometry when at least 220 px is available; configured `Width` remains 220–600 px while the rendered card may be narrower to fit the viewport. Roblox runtime and rendered-UI results are not available and are not claimed.

## Local validation and pending Roblox checks

- Official Luau compilation passed for the integrated module, demo, and notification test file (3 files; 13 KLOC, 733 KB bytecode).
- Offline layout harness passed 16/16 cases against the exact extracted `Window:_LayoutNotifications` method. Source/method/harness hashes and stub limitations are recorded in `evidence/rc18_notifications_layout_harness.proof.txt`.
- The harness uses deterministic stubs; it is not Roblox font measurement, rendered UI, or interaction testing.
- Full Mintlify validation passed for 25 MDX pages and 25 navigation pages, with no broken internal links.
- Roblox runtime and rendered-UI validation are pending.

## Previous release candidate: rc.17 (historical)

The rc.17 standalone module hash `076675ec1733dbc0fe694853852f4fb71f6e726a5a4d3377f87cb914c3969baf` is a pre-release candidate. Official Luau compilation passed for the integrated module, demo, and nine changed test files (11 files total; 8 KLOC, 535 KB bytecode). Seven focused key-layout cases and eight state-helper checks passed offline. These checks validate geometry/state logic, not rendered UI. Roblox runtime suites and rendered-UI checks are pending.

## Verified for rc.17 candidate

- Official Luau compilation passed for the integrated module, demo, and nine test files (11 files total; 8 KLOC, 535 KB bytecode).
- Seven focused key-geometry cases and eight state-helper checks passed offline. A full `SetBranding` smoke check also passed with UI stubs; it does not verify rendering.
- The new horizontal category-caption centering test compiled but was not executed.
- Full Mintlify validation passed for 25 MDX pages and 25 navigation pages, with no broken internal links.
- Existing APIs are preserved; connected-client validation remains pending.

## Previous release candidate: rc.16 (historical)

The rc.16 standalone module hash `acf0ab70d921b5413abb9efd7f6d866efe8d9f632697b0af41317055f8c29375` is a pre-release candidate. Official Luau compilation passed for the integrated module, demo, and six changed test files (8 KLOC, 505 KB bytecode across all eight files). Offline validation passed 8 of 8 extracted state-helper checks; saved proof confirms both helper texts match the final sources. This validates helper logic only, not rendered UI. Full Mintlify validation passed for 25 MDX pages and 25 navigation pages with no broken links. Roblox runtime suites and rendered-UI checks were not run because the Real server was unavailable.

## Verified for rc.16 candidate

- Official Luau compilation passed for the integrated module, demo, and six changed test files (8 KLOC, 505 KB bytecode).
- Extracted state-helper validation passed 8/8 checks. Both helper source texts match the final module; SHA-256 values and the proof are recorded in `evidence/rc16_state_helpers_proof.txt`.
- Mintlify validation passed for 25 MDX pages and 25 navigation pages, with no broken internal links.
- Icon QA confirmed ten primary Outline retouches; catalogue IDs are unchanged. All 288 PNG and 288 SVG exports across three variants passed zero-length and out-of-bounds checks. Root reviewed the icons at 18 px.
- Motion review found no remaining concrete defect. These checks do not certify rendered transitions.
- Connected-client runtime suites and rendered-UI validation remain pending because the Real server is unavailable.

## Previous release candidate: rc.15 (historical)

The rc.15 standalone module hash `653d8b73e9d6d238efc10fe68da818a8806eceecea9b9752db3e53fa36af75be` is a pre-release candidate. Official Luau compilation passed for the integrated module, demo, and four changed test files (13 KLOC, 762 KB bytecode across all six files). Full Mintlify validation passed for 25 MDX pages and 25 navigation pages with no broken links. The offline `navigation_for` harness passed 11 of 11 assertions; this validates navigation logic only and is not a rendered-UI or connected-client result. Real runtime validation is pending because the Real server is unavailable.

## Verified for rc.15 candidate

- Offline `navigation_for` harness: 11/11 assertions passed. No rendered UI was tested.
- Official Luau compilation passed for the integrated module, demo, and four changed test files (13 KLOC, 762 KB bytecode across all six files).
- Mintlify validation passed for 25 MDX pages and 25 navigation pages, with no broken internal links.
- The optional Quickstart preset example compiled with official Luau and uses the local rc.15 `CreateWindow` design option. The example was not run in Roblox.
- Real runtime suites were not run because the Real server was unavailable.
- The new opt-in Atelier preset and Rail navigation variant are documented; existing presets and navigation variants remain available.

## Previous release candidate: rc.14 (historical)

The rc.14 standalone module hash `d7a803bc4ba5d8395f1a915580506baaaa95865ef5fd11a4d0afe643da4c5b87` is a pre-release candidate. Official Luau compilation passed for the integrated module and demo (12 KLOC, 691 KB bytecode), and an isolated background demo load returned `Ready` for rc.14. Runtime suites were not started because the connected client was lost before the test job began. No rc.14 runtime assertion results are available.

## Verified for rc.14 candidate

- Official Luau compilation passed for the integrated module and demo at the rc.14 hash.
- An isolated background demo load returned `Ready` at rc.14.
- Mintlify validation passed for 25 MDX pages with no broken internal links; 10 code snippets parsed. The beginner harness was prepared but not executed.
- The new Quickstart callback and saved-control example parsed as MDX and compiled with the official Luau compiler. It demonstrates connecting a control callback to project state and updating the returned handle; it was not run in Roblox.
- The main window GUI depth was reduced and Soft navigation states were quieted. Key-gate and loader avatar frames, theme-token borders and status surfaces, and developer override geometry were corrected.
- No rc.14 runtime suites ran. Connected-client testing remains pending.

## Previous release candidate: rc.13 (historical)

The rc.13 standalone module hash `225eab5825d8ef9732af0ace9dd4c15394cf6043b145f3c114bde6308a05dcac` passed five targeted runtime suites in the connected Roblox client on 2026-10-10 (client 5160, generation 2). These 252 assertions apply to that hash only; they are not rc.14 results.

## Verified for rc.13

| Runtime suite | Assertions | Result |
|---|---:|---|
| key system | 86 | Passed |
| loading | 57 | Passed |
| design | 26 | Passed |
| launch | 34 | Passed |
| visual | 49 | Passed |
| **Total** | **252** | **Passed** |

- Official Luau compilation passed for the integrated module and demo at the final rc.13 hash (12 KLOC, 691 KB bytecode).
- Mintlify validation passed for 25 MDX pages and navigation entries, with no broken internal links. The newly added key-layout example was parsed with Luau; it was not fully compiled.
- All five targeted runtime suites completed through the background job. An earlier direct evaluation timed out without a result; no cause is established.
- Root reviewed the final loader capture, including its 56 px mark, centered header accent, clear footer, and transparent card.
- No physical phone was tested.

## Previous candidate: rc.12 (historical)

The rc.12 standalone module hash `f3e3462b691995abd3644dd5166ab677417b096e9d933c89ec40f742c16c7276` passed three targeted runtime suites in the connected Roblox client on 2026-10-09 (client 5160, generation 1). These 104 assertions apply to that hash only.

| Runtime suite | Assertions | Result |
|---|---:|---|
| design | 26 | Passed |
| engine | 53 | Passed |
| notifications | 25 | Passed |
| **Total** | **104** | **Passed** |

- Official Luau compilation passed for the integrated module and demo.
- Mintlify validation passed for 25 MDX pages and navigation entries, with no broken internal links.
- The Overview screenshot showed Primary, Secondary, and Subtle action hierarchy; the final notification toast was not captured.
- The visual suite timed out twice and has no passing result for rc.12.
- No physical phone was tested.

## Previous candidate: rc.11 (historical)

The rc.11 standalone module hash `b8c65a8d2bcfd0ada0a9e3642366ecccc3a736db24a5c63c125a8489083c1074` passed ten targeted runtime suites in the connected Roblox client on 2026-10-09. The suites total 440 assertions. These results apply to this hash only and are not rc.12 results.

### Verified for rc.11

| Runtime suite | Assertions | Result |
|---|---:|---|
| design | 26 | Passed |
| engine | 51 | Passed |
| convenience | 50 | Passed |
| launch | 34 | Passed |
| navigation | 43 | Passed |
| layout | 34 | Passed |
| visual | 48 | Passed |
| loading | 51 | Passed |
| key_system | 77 | Passed |
| branding | 26 | Passed |
| **Total** | **440** | **Passed** |

- Official Luau compilation passed for the integrated module and demo.
- Mintlify validation passed for 25 MDX pages and navigation entries, with no broken internal links; all six Lua examples on the Design guide compiled with the official Luau compiler.
- An initial visual-suite attempt ended because its demo window had been destroyed before the gallery assertions; reloading the valid fixture at the same source hash made the full Visual suite pass.
- No physical phone was tested.

## Previous candidate: rc.10 (historical)

The rc.10 standalone module hash `eb2e7ef8797a203b5feca7ed3b1dee2ea919432c5a42097575898f5518c66472` passed ten targeted runtime suites in the connected Roblox client on 2026-10-09. The suites total 436 assertions. These results apply to this hash and are separate from the historical rc.9 run below.

## Verified for rc.10

| Runtime suite | Assertions | Result |
|---|---:|---|
| design | 22 | Passed |
| engine | 51 | Passed |
| convenience | 50 | Passed |
| launch | 34 | Passed |
| navigation | 43 | Passed |
| layout | 34 | Passed |
| visual | 48 | Passed |
| loading | 51 | Passed |
| key_system | 77 | Passed |
| branding | 26 | Passed |
| **Total** | **436** | **Passed** |

- Official Luau compilation passed for the integrated module and demo.
- Mintlify validation passed for 25 MDX pages and navigation entries, with no broken internal links; all six Lua examples on the Design guide compiled with the official Luau compiler.
- The primary agent reviewed the Command preset with the Soft radius in the connected Roblox client on desktop. No physical phone was tested.
- The final console showed only the expected warning from a deliberately failing loader test.

## Previous candidate: rc.9 (historical)

The rc.9 standalone module hash `a1dd4bb0f3dd9fbc99ee97b7d6d70ce2382f1ab2959df169bdb6c037fec6bdc3` passed six targeted runtime suites in the connected Roblox client on 2026-10-09. The suites total 279 assertions; this is not a rerun of the earlier 19-suite baseline.

## Verified for rc.9

| Runtime suite | Assertions | Result |
|---|---:|---|
| navigation | 43 | Passed |
| layout | 34 | Passed |
| visual | 48 | Passed |
| loading | 51 | Passed |
| key_system | 77 | Passed |
| branding | 26 | Passed |
| **Total** | **279** | **Passed** |

- Official Luau compilation passed for the integrated module and demo.
- Mintlify local validation passed for 24 MDX pages and 24 navigation entries, with no broken internal links.
- The primary agent reviewed desktop and centered simulated 360 px captures of the key gate and loader; their cards fit at 336 × 462 px and 336 × 300 px. The main-window capture at 360 × 560 px predates the final off-toggle contrast correction; that correction passed rendered-property and section-contrast checks, but no fresh pixel capture was available afterward. No physical phone was tested.

## Previous candidate: rc.8 (historical)

The rc.8 source hash `fca235c395c48a26b9b9dd984d5405e3812796c3a4eeb4a1b97810fab8b281fa` passed six targeted runtime suites in the connected Windows Roblox client on 2026-10-09. These 275 assertions apply only to rc.8; the separate 19-suite run below is the historical rc.7 baseline.

### Verified for rc.8

| Runtime suite | Assertions | Result |
|---|---:|---|
| navigation | 43 | Passed |
| layout | 33 | Passed |
| loading | 51 | Passed |
| key_system | 77 | Passed |
| branding | 26 | Passed |
| visual | 45 | Passed |
| **Total** | **275** | **Passed** |

- The integrated rc.8 module and demo compiled with the official Luau compiler.
- Mintlify configuration validation passed for 24 MDX pages and 24 navigation entries, with no broken internal links. The transparency examples in the appearance, loader, and key-gate guides compiled with the official Luau compiler.
- The primary agent visually reviewed desktop captures of the main window, key gate, and loader. The key gate and loader fit a centered, simulated 360 px viewport at 336 × 462 px and 336 × 300 px respectively; the main window was reviewed at 360 × 560 px. These are Roblox-client viewport simulations, not physical-phone tests.

### Previous baseline: rc.7 (historical)

The checks in this section describe earlier builds and are retained for context. They do not certify the rc.8 source hash above.

- A full run passed 1258 assertions across 19 runtime suites in the connected Windows Roblox client; this run preceded the final Luarmor SDK ownership guard.
- After that guard, 4 focused Luarmor SDK checks passed against the final rc.7 demo (same-ID reuse, validation, cross-ID rejection and changed-ID fail-closed behavior).
- 42 isolated logic checks and 4 quick-start checks (1308 assertions across these runtime, logic and quick-start checks).
- Standalone module and managed demo static analysis: zero errors and zero warnings. Official Luau compilation passed for the module and supplied examples.
- Deterministic standalone rebuild; source hash: `888a5f4309cd90c8e50341db9181c81f931b66382892b92b9dd3efffccae1ddf`.
- 96 original icon names and IDs; IDs 1-71 preserved. All three variants render natively.
- 288 PNG/SVG pairs checked for valid files, dimensions, transparency, nonempty artwork and unclipped bounds. Exported geometry matches the current icon source.
- Desktop and narrow 360 px layout assertions passed in the Roblox client. Resizing preserves the selected tab in the visible navigation area.
- The key dialog was visually reviewed at desktop and narrow widths.
- Native clicks exercised the Discord button with an injected copier, typed key entry and successful verification. Tests did not write to the system clipboard.
- The key screen displays the local player's thumbnail by default and uses "Verify key". Custom images, monograms, avatar updates and pending-task cleanup passed.
- Loading presets, persistent part overrides, custom animation ownership and external destruction were checked.
- Short constructors for windows, tabs, sections and controls passed callback, value, input-validation and options-ownership checks. The original options-table API passed the same runtime suites.
- Yielding Button, Changed and Connect callbacks stop when their owner is destroyed. Hide/Show preserves callbacks, and a callback that destroys its own control can finish its current invocation. Loader error handlers and restarted sequences stop on destruction. Launch does not reach Ready after its window is destroyed during construction, and cancellation after key acceptance does not call the key gate's OnCancel.
- Get key URL/callback actions, manual-copy fallback, single-flight behavior, stale results and native clicks passed. The key layout has a 420 px default width and automatic heights of 332/394/404/462 px.
- Luarmor and VampAuth adapters passed fake-SDK success, rejection and exception checks. The KeyAuth bridge passed fake initialization, shared initialization, retry and strict response-shape checks. These tests do not connect to provider services or validate live credentials.
- Mintlify configuration passed local validation for 23 MDX routes with no broken links. The previous 48 Luau documentation blocks compiled; the 6 new provider/server-example blocks passed parse-only checks. The 12 blocks in the controls walkthrough ran together in the connected client. Hosted availability is checked separately after publication.
- Remote example compiled the actual standalone source through `loadstring`, created working controls, cleaned up, and handled HTTP/compile/invalid-response errors. HTTP was supplied by a local test shim.

| Runtime suite | Assertions | Result |
|---|---:|---|
| engine | 51 | Passed |
| regression | 10 | Passed |
| extensions | 67 | Passed |
| robustness | 15 | Passed |
| input | 13 | Passed |
| native_extensions | 9 | Passed |
| loading | 47 | Passed |
| branding | 18 | Passed |
| navigation | 29 | Passed |
| icons | 727 | Passed |
| layout | 30 | Passed |
| notifications | 21 | Passed |
| key_system | 74 | Passed |
| key_provider_guard | 4 | Passed on final rc.7 build |
| launch | 34 | Passed |
| native_access | 4 | Passed |
| visual | 45 | Passed |
| native_visual | 6 | Passed |
| remote | 8 | Passed |
| convenience | 50 | Passed |

## rc.7 session observations (historical)

One native slider gesture failed during the preceding candidate session, followed by a passing input suite and ten passing dedicated drags. An intermittent style/animation failure was reproduced under allocation pressure: the old weak-key registry lost its target in all eight comparisons, leaving the tween running and the style unapplied. Explicit target ownership passed all eight comparisons; separate checks verify cleanup when a subtree or window is destroyed. The final suite retains detailed diagnostics. MCP transport timeouts interrupted some requests; unfinished suites were resumed.

Expected warning messages from deliberately failing hooks, cleanup callbacks and loaders are part of the tests. The final console check distinguishes these from unexpected problems.

A native reopen check initially failed while the preview key modal remained open above the test window. Closing that test fixture restored the passing check; this required no production change.

## Remaining validation for rc.13

- Physical phone/tablet touch gestures, virtual keyboard behavior and hardware performance.
- Standard Studio client execution and the sample key-validation server/client flow in a project you own.
- Network and executor compatibility beyond the tested Windows client.
- Your review of appearance, intended target environments and the prepared MIT license.

The rc.13 targeted Visual suite passed in the connected client. Physical phone/tablet use and the final notification toast capture remain outstanding. Keep rc.13 marked as a pre-release until the intended environments have been checked. For publishing steps, see [PUBLISHING.md](PUBLISHING.md).
