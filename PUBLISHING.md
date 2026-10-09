# Maintain and publish Gabibou UI releases

The repository is `Gabibou455/GabibouUI`. This guide covers the repeatable maintainer workflow. Verify the public repository page and raw module URL after publishing changes.

## Before each release

1. Review the current [quality report](QUALITY.md), known limits, and [changelog](CHANGELOG.md).
2. Run the documented local validation and review the demo in the environments you intend to support. Passing checks do not prove that the library has no defects.
3. Confirm the version in the source, standalone module, docs, and release archive agree. Rebuild the standalone module from the repository root when source modules change.
4. Review `LICENSE` and `THIRD_PARTY.md`; do not include credentials or access tokens in commits.

## Update the repository

From the repository checkout, review the changed files and commit the release candidate. Push the intended branch to `origin`; use your normal GitHub authentication and identity settings.

```powershell
git status --short
git add .
git commit -m "Prepare Gabibou UI <version>"
git push origin main
```

Keep unrelated development workspace files out of the repository. The published repository should contain the library, documentation, examples, license notices, and release assets only.

## Create a versioned release

On GitHub, open **Releases** and choose **Draft a new release**. Create a new immutable tag (for example, `v1.5.0-rc.5`) from the reviewed commit, add release notes, and attach the matching ZIP archive named `GabibouUI.zip`. Use this same asset filename for every future release so download instructions remain stable; identify each version through its Git tag, release title, source, and changelog. Mark a release candidate as a **pre-release**. Use a stable release label only after the supported environments and remaining items in `QUALITY.md` have been reviewed.

Link users to the [GitHub Releases page](https://github.com/Gabibou455/GabibouUI/releases) to choose and download a release. Keep this link version-neutral; do not use a `latest/download` URL, since pre-releases and GitHub's latest-release selection can change which asset it resolves to.

After the release is available, verify the repository page and the pinned raw module URL from an external client before describing remote loading as confirmed. The tagged raw module URL for this candidate is:

```text
https://raw.githubusercontent.com/Gabibou455/GabibouUI/v1.5.0-rc.5/gabibou_ui.luau
```

The one-line load is:

```lua
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Gabibou455/GabibouUI/v1.5.0-rc.5/gabibou_ui.luau"))()
```

This requires a client environment exposing those functions. For Studio, use the `ModuleScript` instructions in the API guide. Keep examples and release notes explicit about which checks have actually been run.

The beginner loader uses `main` to follow published updates without editing its URL. Projects that need reproducible behavior can replace `main` with a reviewed release tag. Publish a new tag for each version rather than moving a tag that people already use.

## Official GitHub guides

- [Create a repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-new-repository)
- [Manage releases](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository)
- [Licensing a repository](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository)
