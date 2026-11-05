# Maintain and publish documentation

The English user guide lives in `docs/` as GitBook-compatible Markdown. Default tables and the icon catalogue are generated from Luau source. `gabibou_ui/mintlify` receives the same guides for the existing hosted documentation.

## Edit the guide

1. Edit Markdown in `docs/`. For the complete menu, edit `docs/examples/menu-complet.luau`.
2. Run `node gabibou_ui/sync_docs.cjs` from the repository root.
3. Run `node gabibou_ui/check_docs.cjs`. Set `LUAU_COMPILE_BIN` to the official Luau compiler to include snippet compilation.
4. Commit and push to `main`, then verify the hosted deployment before reporting it as published.

Do not edit Mintlify pages marked `Generated from docs/` manually. Generation converts internal Markdown links to Mintlify routes. Existing document filenames and routes are retained to preserve shared links; all user-facing content is English.

## Connect GitBook

The repository includes [official Git Sync configuration](https://gitbook.com/docs/docs-as-code/git-sync/content-configuration).

1. Sign in to the GitBook organization and select the Gabibou UI site and space.
2. Configure GitHub Sync for `Gabibou455/GabibouUI`, branch `main`.
3. For repository-root configuration, keep Project directory at the root: `.gitbook.yaml` selects `docs/`. For a space directory mapping, select `docs`: its own `.gitbook.yaml` selects the local root.
4. Choose the initial direction **GitHub to GitBook**. `docs/SUMMARY.md` defines navigation and `docs/README.md` is the first page. Avoid an initial GitBook-to-GitHub sync that could overwrite prepared content.
5. Review pages and code in Preview, then publish with an available GitBook subdomain. The owner must decide on paid subscriptions or custom domains.
6. After verifying the public GitBook URL, add it to the repository README. Until then, links use the readable GitHub guide and existing Mintlify site.

Configuration files alone do not create an account, connect Git Sync or publish a GitBook site. A URL-based import was performed during migration, but its page order and external links require review before publication. Prefer Git Sync from the canonical Markdown for the final site.
