# Boutons et composants

Les exemples utilisent le `tab` créé dans [Démarrer](demarrer.md). Ajoute-les après sa création. Les mêmes méthodes fonctionnent sur une section.

| Besoin | Composant | Valeur reçue par la callback |
|---|---|---|
| Lancer une action | `Button` | Aucun argument |
| Activer ou désactiver | `Toggle` | Booléen |
| Régler un nombre | `Slider` | Nombre |
| Choisir dans une liste | `Dropdown` | Texte de l’option |
| Saisir du texte | `Input` | Texte confirmé ou modifié à la perte du focus |
| Assigner un raccourci clavier | `Keybind` | Nom de la touche lorsqu’elle est pressée |
| Choisir une couleur | `ColorPicker` | Texte `#RRGGBB` |
| Afficher une explication | `Paragraph` | Aucune callback |

## Button

```lua
tab:Button("Actualiser", {Text = "Lancer", Variant = "Primary"}, function()
    window:Notify({Title = "Actualisation demandée"})
end)
```

`Text` est le texte du bouton, distinct du titre de la ligne. `Variant` accepte `Primary` (défaut), `Secondary` et `Subtle`. Le bouton lance la callback lorsqu’il est activé.

## Toggle

```lua
local effects = tab:Toggle("Effets", {Id = "effects", Value = true}, function(enabled)
    print("Effets :", enabled)
end)
```

`Value` vaut `false` par défaut. La callback reçoit `true` ou `false` après un changement. `effects:Get()` lit la valeur actuelle.

## Slider

```lua
local volume = tab:Slider("Volume", {
    Id = "volume", Min = 0, Max = 100, Step = 5, Value = 50,
}, function(value)
    print("Volume :", value)
end)
```

Les défauts sont `Min = 0`, `Max = 100`, `Step = 1`, `Value = Min`. `Max` doit dépasser `Min` et `Step` doit être positif. La valeur est bornée puis arrondie aux pas calculés depuis `Min`.

Sur mobile, un glissement horizontal règle la valeur ; un glissement vertical laisse défiler la page. Un tap sélectionne une valeur au relâchement.

## Dropdown

```lua
local quality = tab:Dropdown("Qualité", {
    Id = "quality", Options = {"Basse", "Moyenne", "Haute"}, Value = "Moyenne",
}, function(choice)
    print("Qualité :", choice)
end)
```

`Options` contient au moins une chaîne non vide, sans doublon. `Value` doit appartenir à la liste ; sans valeur explicite, la première option est sélectionnée. `quality:SetOptions({"Basse", "Haute"})` remplace la liste et conserve la sélection si elle existe encore, sinon choisit la première option.

## Input

```lua
tab:Input("Pseudo", {
    Value = "", Placeholder = "Entre un nom", MaxLength = 24,
}, function(text)
    print("Pseudo :", text)
end)
```

La callback est appelée pour le texte modifié à la perte du focus. `MaxLength` vaut `120` par défaut et accepte de 1 à 4096 caractères UTF-8.

## Keybind

```lua
tab:Keybind("Action", {Value = Enum.KeyCode.F6}, function(keyName)
    print("Touche :", keyName)
end)
```

Le joueur active le champ puis presse une touche pour l’assigner. La callback s’exécute lorsque cette touche est ensuite pressée, hors saisie de texte. `Value` accepte un `Enum.KeyCode` ou son nom ; son défaut est `F6`. Prévois aussi un bouton visible pour les utilisateurs tactiles.

## ColorPicker

```lua
local color = tab:ColorPicker("Couleur", {
    Value = "#78B8FF", Palette = {"#78B8FF", "#A18FFF", "#F08B8B"},
}, function(hex)
    print("Couleur :", hex)
end)
```

La callback et `color:Get()` renvoient une chaîne `#RRGGBB`. `color:GetColor()` renvoie un `Color3`. `Value` accepte aussi un `Color3`. Une palette personnalisée accepte de 1 à 32 couleurs.

## Paragraph et Section

```lua
tab:Paragraph("Informations", {Description = "Les réglages sont propres à cette session."})

local audio = tab:Section("Audio")
audio:Toggle("Musique", {Value = true}, function(enabled)
    print("Musique :", enabled)
end)
```

Une section regroupe des composants dans l’onglet. Une catégorie regroupe des onglets : `window:Category("Réglages"):Tab("Audio", "volume")`.

## Options communes

| Option | Usage |
|---|---|
| `Id` | Retrouver le composant avec `window:Get(id)` et gérer ses valeurs |
| `Description` | Texte d’aide sous le titre |
| `Disabled = true` | Créer le composant désactivé |
| `Persistent = false` | Exclure sa valeur des configurations et profils |
| `Layout` | Régler sa largeur, sa hauteur, son ordre ou sa position |

Les options propres à chaque composant sont décrites ci-dessus. Toutes les options communes ne s’appliquent pas aux objets de navigation tels que les sections.

Pour lire et modifier les composants après création : [Valeurs et profils](valeurs-profils.md). Pour créer du contenu Roblox personnalisé : [API](reference/api.md).
