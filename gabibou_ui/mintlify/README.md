# Gabibou UI Mintlify docs

This folder is a self-contained Mintlify documentation root for Gabibou UI. It contains `docs.json` and all MDX pages referenced by its navigation. The pages do not link to source files outside this folder.

## Preview locally

Install the Mintlify CLI by following the [official installation guide](https://mintlify.com/docs/quickstart). From this folder, run `mint dev`; the CLI serves a local preview using `docs.json` and the MDX pages.

## Connect a deployment

The documentation site is [gabibou-ui.mintlify.app](https://gabibou-ui.mintlify.app), connected to `Gabibou455/GabibouUI`, branch `main`, directory `gabibou_ui/mintlify`. To reproduce this setup, open [Git Settings](https://app.mintlify.com/settings/deployment/git-settings), enable **docs.json is in a subdirectory**, and enter `/gabibou_ui/mintlify` without a trailing slash. See Mintlify's [monorepo guide](https://raw.githubusercontent.com/mintlify/docs/main/deploy/monorepo.mdx).

The docs describe release candidate `1.5.0-rc.6`. Beginner examples use the fixed `main` module URL and short constructors; a reviewed release tag can replace `main` when a project needs a fixed version. The Quality page lists verified checks and remaining validation.

## Structure

- `docs.json` configures the Mint theme, monochrome colors, dark appearance, and four navigation groups, including the landing page.
- `getting-started/` introduces installation and the first window.
- `customization/` covers controls, data, appearance, icons, loading, key gates, lifecycle, animation, components, and notifications.
- `reference/` contains the API map, full customization defaults, all 96 icon IDs, and current quality status.
- `examples/` contains complete Luau examples for quickstart, loading, Discord key validation, server validation, and remote loading.
