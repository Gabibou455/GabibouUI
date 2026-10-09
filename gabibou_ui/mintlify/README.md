# Gabibou UI Mintlify docs

This folder is a self-contained Mintlify documentation root for Gabibou UI. It contains `docs.json` and all MDX pages referenced by its navigation. The pages do not link to source files outside this folder.

## Preview locally

Install the Mintlify CLI by following the [official installation guide](https://mintlify.com/docs/quickstart). From this folder, run `mint dev`; the CLI serves a local preview using `docs.json` and the MDX pages.

## Connect a deployment

To configure a monorepo deployment, connect the GitHub repository and open [Git Settings](https://app.mintlify.com/settings/deployment/git-settings). Enable **docs.json is in a subdirectory**, enter `/gabibou_ui/mintlify` (without a trailing slash), and choose the intended branch. Saving these settings triggers deployment. This README documents the steps only; no deployment has been configured here. See Mintlify's [monorepo guide](https://raw.githubusercontent.com/mintlify/docs/main/deploy/monorepo.mdx) for the provider's current instructions.

The repository is `Gabibou455/GabibouUI`. The local docs describe the unreleased `1.5.0-rc.4` candidate and its lifecycle corrections; the public `v1.5.0-rc.3` tag remains pinned in remote-loading examples and does not include those local changes. Confirm the published release and raw-file URL before reporting an external fetch as verified. The Quality page covers this candidate's local checks and remaining validation.

## Structure

- `docs.json` configures the Mint theme, monochrome colors, dark appearance, and four navigation groups, including the landing page.
- `getting-started/` introduces installation and the first window.
- `customization/` covers controls, data, appearance, icons, loading, key gates, lifecycle, animation, components, and notifications.
- `reference/` contains the API map, full customization defaults, all 96 icon IDs, and current quality status.
- `examples/` contains complete Luau examples for quickstart, loading, Discord key validation, server validation, and remote loading.
