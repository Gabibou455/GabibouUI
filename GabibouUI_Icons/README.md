# Gabibou UI icon images

Open `index.html` to browse every icon by name, ID and variant. Each variant folder also contains a `preview.png` contact sheet.

- `Outline`, `Soft`, `Duotone`: 96 transparent PNGs and 96 editable SVGs per folder.
- File names use `ID_name`, for example `021_farm.png` and `024_harvest.svg`.
- PNGs are 256 x 256 RGBA. SVGs use a fixed 24 x 24 design canvas.
- `catalogue.csv` and `catalogue.json` map every name and ID to its files.

The images are exported from the library's own Luau geometry. Rasterization and anti-aliasing may differ from Roblox's native rendering. The IDs are internal Gabibou UI identifiers, not Roblox image asset IDs. The library can draw these icons directly with `Icon = 21`; uploading the PNGs to Roblox is optional and creates separate Roblox asset IDs.

This folder is included in the same ZIP as the library, alongside `gabibou_ui.luau` and the `gabibou_ui` source and documentation folder.
