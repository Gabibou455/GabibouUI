# Options et valeurs par défaut

Ces tableaux sont générés depuis les fichiers Luau par `node gabibou_ui/sync_docs.cjs`. Ils décrivent les sources de ce dépôt.

## Fenêtre

`UI:CreateWindow(title, options)` accepte notamment `Id`, `Title`, `Subtitle`, `Design`, `Theme`, `Style`, `Motion`, `Branding`, `Layout`, `Navigation`, `Notifications`, `Responsive`, `Width`, `Height`, `Position`, `AnchorPoint`, `ToggleKey`, `ShowWatermark`, `ReducedMotion`, `Parent`, `DisplayOrder`, `DiscordPrompt` et `Storage`.

| Option | Défaut et limites |
|---|---|
| `Width`, `Height` | 800 × 590 ; bornés à 320–1400 et 300–1000 px |
| `Theme` | `Graphite` ; accepte aussi `Aurora`, `Ember` ou une table de couleurs |
| `ToggleKey` | `Enum.KeyCode.RightControl` |
| `DisplayOrder` | 90 |
| `ShowWatermark` | `true` |
| `Parent` | `PlayerGui` du joueur local |

## Responsive

| Option | Valeur par défaut |
|---|---|
| `Breakpoint` | `620` |
| `TouchTarget` | `44` |
| `Margin` | `12` |
| `LandscapeHeight` | `500` |

Plages : `Breakpoint` 320–1000, `TouchTarget` 44–72, `Margin` 4–40, `LandscapeHeight` 0–700. Pour les gestes et orientations : [Apparence et mobile](../apparence-mobile.md).

## Disposition : `Layout`

| Option | Défaut | Plage ou choix |
|---|---|---|
| `TabPosition` | `"Left"` | Left, Right, Top, Bottom |
| `MobileTabPosition` | `"Top"` | Top, Bottom |
| `SidebarWidth` | `168` | 96–360 |
| `TabWidth` | `128` | 64–400 |
| `TabHeight` | `44` | 44–96 |
| `TabGap` | `6` | 0–32 |
| `TabIconSize` | `16` | 12–40 |
| `ContentPadding` | `12` | 4–40 |
| `ContentGap` | `14` | 0–48 |
| `HeaderHeight` | `76` | 64–160 |
| `FooterHeight` | `42` | 32–96 |
| `SearchHeight` | `44` | 44–96 |
| `SearchGap` | `8` | 0–40 |
| `PageTitleHeight` | `40` | 28–80 |
| `ButtonWidth` | `112` | 58–400 |
| `ButtonHeight` | `44` | 44–120 |
| `RowGap` | `6` | 0–40 |
| `SectionGap` | `12` | 0–48 |
| `PanelTransparency` | `.06` | 0–1 |
| `ControlsPosition` | `"Right"` | Left, Right, Below |
| `Draggable` | `true` | Booléen |
| `Resizable` | `true` | Booléen |
| `ShowSearch` | `true` | Booléen |
| `ShowFooter` | `true` | Booléen |
| `ShowHeader` | `true` | Booléen |
| `ShowPageTitle` | `true` | Booléen |

## Style : `Style`

| Option | Valeur par défaut |
|---|---|
| `Font` | `Enum.Font.Gotham` |
| `FontBold` | `Enum.Font.GothamBold` |
| `TextSize` | `14` |
| `DescriptionSize` | `12` |
| `TitleSize` | `18` |
| `WindowRadius` | `16` |
| `SectionRadius` | `12` |
| `ControlRadius` | `8` |
| `RowPadding` | `12` |

## Animation : `Motion`

| Option | Valeur par défaut |
|---|---|
| `Duration` | `0.16` |
| `Style` | `Enum.EasingStyle.Quad` |
| `Direction` | `Enum.EasingDirection.Out` |
| `RepeatCount` | `0` |
| `Reverses` | `false` |
| `Delay` | `0` |

## Navigation : `Navigation`

| Option | Valeur par défaut |
|---|---|
| `Variant` | `"Soft"` |
| `IconVariant` | `"Outline"` |

## Notifications : `Notifications`

| Option | Valeur par défaut |
|---|---|
| `Position` | `"BottomRight"` |
| `Width` | `340` |
| `Margin` | `18` |
| `Gap` | `10` |
| `MaxVisible` | `4` |
| `Duration` | `4` |
| `ShowProgress` | `true` |
| `AnimationDuration` | `.18` |

## Limites des options locales

Les contrôles acceptent `Layout = {Order, Width, Height, Position}`. `Order` est un entier entre -100000 et 100000, `Width` vaut 58–600 px, `Height` 44–160 px et `Position` accepte `Left`, `Right` ou `Below`. Les onglets acceptent `Order`, `Width`, `Height` et `IconSize` (12–40 px).

Les tailles de texte du style acceptent 10–32 ; les rayons 0–32 ; `RowPadding` 8–32. Les options de disposition et de style hors plage sont rejetées. `Duration` et `Delay` acceptent 0–30 secondes ; `RepeatCount` est un entier entre -1 et 100.

## Couleurs et icônes

Les tokens du thème sont `Background`, `Surface`, `Raised`, `Hover`, `Border`, `Text`, `Muted`, `Accent`, `AccentText`, `Success`, `Danger`. Une table de thème partielle complète ses couleurs avec celles de Graphite.

`Branding` accepte `Mode` (Initials, Avatar, Image), `Placement` (TopLeft, TopRight, BottomRight, BothRight), `Text`, `Image` et `UserId`. Les variantes d’icônes sont `Outline`, `Soft`, `Duotone`. Voir [Icônes](icones.md).

Pour les méthodes : [API](api.md). Pour une option spécialisée de fournisseur, consulte aussi les exemples de raccordement du dépôt.
