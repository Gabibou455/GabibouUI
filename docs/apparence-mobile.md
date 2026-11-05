# Apparence et mobile

## Choisir un design

Passe les options lors de la création de ta fenêtre :

```lua
local window = UI:CreateWindow("Mon menu", {
    Design = "Atelier",
    Width = 800,
    Height = 590,
    Responsive = {TouchTarget = 48, LandscapeHeight = 500},
    Layout = {MobileTabPosition = "Bottom"},
})
```

Ce bloc remplace la création de `window` dans ton script ; ajoute ensuite tes onglets et composants.

| Design | Aspect | Navigation |
|---|---|---|
| `Studio` | Graphite, espacement confortable | Gauche, `Soft` |
| `Minimal` | Graphite, compact, angles nets | Gauche, `Classic` |
| `Command` | Presque noir, espacé | Haut, `Pill` |
| `Atelier` | Monochrome, confortable | Gauche, `Rail` |

`Theme`, `Style`, `Layout` et `Navigation` explicites prennent le dessus sur le preset. Un design plus précis s’écrit par exemple `Design = {Preset = "Atelier", Accent = Color3.fromRGB(120, 184, 255), Radius = 12}`.

## Modifier une fenêtre existante

```lua
window:SetTheme("Aurora")
window:SetStyle({TextSize = 14, WindowRadius = 16})
window:SetLayout({TabPosition = "Left", MobileTabPosition = "Bottom"})
window:SetNavigation({Variant = "Rail", IconVariant = "Outline"})
window:SetReducedMotion(true)
```

Thèmes disponibles : `Graphite`, `Aurora`, `Ember`. Variantes de navigation : `Classic`, `Soft`, `Pill`, `Rail`.

Pour laisser le joueur choisir son apparence :

```lua
window:Appearance({Title = "Apparence"})
```

Cela ajoute un onglet d’édition. Ses réglages sont exclus des profils de l’application.

## Comportement mobile

La fenêtre tient compte de la zone sûre et du clavier. Les champs larges passent sous leurs titres ; les toggles restent à côté du texte si la largeur le permet. Les onglets deviennent horizontaux sur une fenêtre étroite ou un téléphone tactile en paysage.

| Option `Responsive` | Défaut | Plage |
|---|---:|---|
| `Breakpoint` | 620 | 320–1000 px : largeur de fenêtre sous laquelle utiliser le mode mobile |
| `TouchTarget` | 44 | 44–72 px : taille minimale des contrôles concernés |
| `Margin` | 12 | 4–40 px : marge autour de la fenêtre |
| `LandscapeHeight` | 500 | 0–700 px : hauteur sûre maximale déclenchant le mode mobile en paysage tactile ; 0 désactive cette règle |

Le classement paysage utilise l’écran avant l’ouverture du clavier : le clavier d’une tablette ne la transforme pas en téléphone. Après rotation ou changement de clavier, une fenêtre déplacée hors écran revient dans la zone visible.

Sur un écran bas, l’en-tête est réduit et le sous-titre ainsi que le pied de fenêtre sont masqués. La recherche est masquée en mode compact sauf lorsqu’elle garde le focus, et reste masquée lorsque le panneau mesure moins de 260 px de haut. Les onglets restent affichés à partir de 140 px de hauteur de panneau. Le rendu et les gestes sur téléphone physique restent à tester dans ton projet.

## Icônes et logo

```lua
local home = window:Tab("Accueil", "home")
home:Button("Actualiser", {Icon = "refresh", IconVariant = "Duotone"}, function()
    print("Actualisation")
end)

window:SetBranding({Mode = "Initials", Text = "G", Placement = "TopLeft"})
```

Les noms et IDs sont dans le [catalogue](reference/icones.md). Un ID Gabibou UI n’est pas un ID d’image Roblox. `Mode = "Avatar"` utilise l’avatar ; `Mode = "Image"` nécessite une option `Image` contenant une URI `rbxassetid://` valide.

Les modifications avancées avec `SetPartLayout` imposent tes coordonnées après la disposition automatique : vérifie alors toi-même les petits écrans. Les [valeurs exactes](reference/options.md) permettent de retrouver toutes les options.
