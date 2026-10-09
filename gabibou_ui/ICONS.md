# Gabibou UI icons — names and IDs

96 original drawings, usable by name or ID. These IDs belong to Gabibou UI; they are not Roblox image asset IDs. No image download is required. Built-in IDs are stable: future icons will be appended to the list.

## Add an icon

```lua
local farm = window:Tab({Title = "Farm", Icon = 21})
farm:Button({Title = "Harvest", Text = "Collect", Icon = 24, IconVariant = "Duotone"})
window:Notify({Title = "Harvest ready", Icon = 24})
local icon = UI:Icon(parent, 21, {Size = 24, Variant = "Soft"})
```

Names work too: `Icon = "farm"` and `Icon = "harvest"`.
The three variants are `Outline` (default), `Soft` and `Duotone`. Use `IconVariant` on a tab or button, and `Variant` with `UI:Icon`.

## Built-in catalogue

| Name | ID |
|---|---:|
| `home` | 1 |
| `sliders` | 2 |
| `palette` | 3 |
| `save` | 4 |
| `code` | 5 |
| `search` | 6 |
| `close` | 7 |
| `check` | 8 |
| `chevron-down` | 9 |
| `chevron-right` | 10 |
| `settings` | 11 |
| `user` | 12 |
| `folder` | 13 |
| `download` | 14 |
| `upload` | 15 |
| `refresh` | 16 |
| `bell` | 17 |
| `info` | 18 |
| `plus` | 19 |
| `minus` | 20 |
| `farm` | 21 |
| `panel` | 22 |
| `inventory` | 23 |
| `harvest` | 24 |
| `seed` | 25 |
| `sprout` | 26 |
| `watering-can` | 27 |
| `shovel` | 28 |
| `tools` | 29 |
| `tractor` | 30 |
| `map` | 31 |
| `menu` | 32 |
| `arrow-left` | 33 |
| `arrow-right` | 34 |
| `minimize` | 35 |
| `maximize` | 36 |
| `restore` | 37 |
| `resize` | 38 |
| `window` | 39 |
| `automation` | 40 |
| `play` | 41 |
| `pause` | 42 |
| `stop` | 43 |
| `bolt` | 44 |
| `shield` | 45 |
| `key` | 46 |
| `lock` | 47 |
| `unlock` | 48 |
| `coins` | 49 |
| `gift` | 50 |
| `teleport` | 51 |
| `target` | 52 |
| `chart` | 53 |
| `chart-bar` | 54 |
| `clock` | 55 |
| `timer` | 56 |
| `compass` | 57 |
| `heart` | 58 |
| `star` | 59 |
| `eye` | 60 |
| `eye-off` | 61 |
| `filter` | 62 |
| `sort` | 63 |
| `check-circle` | 64 |
| `alert` | 65 |
| `help` | 66 |
| `copy` | 67 |
| `clipboard` | 68 |
| `trash` | 69 |
| `edit` | 70 |
| `wand` | 71 |
| `wifi` | 72 |
| `globe` | 73 |
| `link` | 74 |
| `mail` | 75 |
| `message` | 76 |
| `terminal` | 77 |
| `bug` | 78 |
| `cpu` | 79 |
| `server` | 80 |
| `database` | 81 |
| `cloud` | 82 |
| `cloud-download` | 83 |
| `camera` | 84 |
| `image` | 85 |
| `music` | 86 |
| `volume` | 87 |
| `volume-off` | 88 |
| `sun` | 89 |
| `moon` | 90 |
| `gamepad` | 91 |
| `trophy` | 92 |
| `rocket` | 93 |
| `backpack` | 94 |
| `sword` | 95 |
| `flag` | 96 |

## Look up an ID in your script

```lua
local id = UI:GetIconId("harvest") -- 24
local name = UI:GetIconName(21) -- "farm"
for _, entry in ipairs(UI:GetIconCatalogue()) do
    print(entry.Name, entry.Id)
end
```

These lookup methods return `nil` for an unknown name or ID. The returned catalogue is a copy. Drawing an icon with an unknown or non-integer ID is rejected before allocating its GUI.

Icons added with `RegisterIcon(name, builder)` automatically receive IDs starting at 1000. Look them up with `GetIconId(name)`; custom IDs depend on registration order within that library instance. `UnregisterIcon` also removes the ID, which is not reused in that instance.

The Icons page in `demo.luau` shows the drawings, IDs and variants. The optional `GabibouUI_Icons` folder contains their PNG and SVG exports. This document is regenerated from the built-in catalogue by `node gabibou_ui/build.cjs`.
