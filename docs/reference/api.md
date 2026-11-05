# Méthodes de l’API

Cette page sert à retrouver un nom de méthode. Pour construire un menu, commence par [l’exemple complet](../exemple-complet.md). Les tableaux d’[options](options.md) donnent les valeurs par défaut ; le [catalogue](icones.md) liste les icônes.

## Bibliothèque `UI`

| Appel | Résultat ou usage |
|---|---|
| `UI:CreateWindow(title, options?)` ou `UI:CreateWindow(options)` | Crée une fenêtre pour ajouter les composants en plusieurs étapes |
| `UI:Create(spec)` | Crée une fenêtre depuis une table contenant `Tabs`, les contrôles et un éventuel `Loading` |
| `UI:Launch(spec)` | Retourne une session qui coordonne clé, chargement, étapes et fenêtre |
| `UI:CreateLoader(options)` | Crée un loader séparé |
| `UI:CreateKeySystem(options)` | Crée un dialogue de clé ; `Validate(key)` est obligatoire |
| `UI:KeyProvider(name, options)` | Adapte un SDK fourni en fonction `Validate` |
| `UI:Design(schemaOrName)` | Renvoie une copie validée d’un design |
| `UI:RegisterDesign(name, schema)` | Enregistre un design ; refuse un nom existant |
| `UI:GetDesignNames()` / `UI:UnregisterDesign(name)` | Liste ou retire les designs personnalisés |
| `UI:SetStyle(options)` / `UI:SetMotion(options)` | Défauts d’apparence et animation des futures fenêtres |
| `UI:SetLayout(options)` / `UI:SetNotifications(options)` | Défauts de disposition et notifications des futures fenêtres |
| `UI:DestroyAll()` | Détruit les fenêtres, loaders, gates et sessions de cette instance de bibliothèque |

## Fenêtre `window`

| Appel | Résultat ou usage |
|---|---|
| `window:Tab(title, iconOrOptions?)` ou `window:Tab(options)` | Crée un onglet |
| `window:Category(titleOrOptions)` | Crée ou retrouve une catégorie d’onglets |
| `window:SelectTab(tab)` | Sélectionne un onglet de cette fenêtre |
| `window:Get(id)` | Renvoie le contrôle, ou `nil` |
| `window:GetValues()` / `window:SetValues(values, fireCallbacks?)` | Lit ou applique les valeurs persistantes |
| `window:SearchFor(query)` | Filtre les contrôles par recherche |
| `window:Hide()` / `window:Show()` / `window:Toggle()` | Change la visibilité |
| `window:SetSize(width, height)` | Change les dimensions souhaitées, dans les limites de la bibliothèque |
| `window:SetPosition(position, anchor?)` | Positionne la fenêtre avec `UDim2` et un éventuel `Vector2` d’ancrage |
| `window:SetTheme(nameOrColors)` | Change le thème de la fenêtre existante |
| `window:SetStyle(options)` / `window:SetMotion(options)` | Change son style ou ses animations |
| `window:SetReducedMotion(enabled)` | Active ou désactive les animations réduites |
| `window:SetWatermark(enabled)` | Affiche ou masque le nom et la version dans le pied de fenêtre |
| `window:SetLayout(options)` / `window:SetNavigation(options)` / `window:SetBranding(options)` | Change la disposition, navigation ou le logo |
| `window:Appearance(options?)` | Ajoute l’onglet d’édition de l’apparence |
| `window:Notify(options)` | Renvoie une notification avec `Dismiss()` et `Destroy()` |
| `window:Confirm(options)` | Ouvre une confirmation ; renvoie `false` si une autre est ouverte |
| `window:SetNotifications(options)` | Change les défauts de ses notifications |
| `window:PromptDiscord(urlOrOptions)` | Ouvre le dialogue d’invitation ; renvoie succès et éventuelle raison |
| `window:Command(options)` / `window:RemoveCommand(id)` | Enregistre ou retire une commande |
| `window:OpenCommands()` / `window:CloseCommands()` | Ouvre ou ferme la palette de commandes |
| `window:Presets(options?)` | Ajoute l’éditeur de profils |
| `window:SavePreset(name)` / `window:LoadPreset(name, fireCallbacks?)` | Enregistre ou applique un profil ; renvoie succès et résultat/raison |
| `window:DeletePreset(name)` / `window:GetPresetNames()` | Supprime ou liste les profils |
| `window:ExportConfig()` / `window:ImportConfig(json, fireCallbacks?)` | Exporte ou restaure le JSON de configuration |
| `window:SaveConfig(name)` / `window:LoadConfig(name, fireCallbacks?)` | Utilise l’adaptateur `Storage.Read/Write` fourni à la fenêtre |
| `window:GetParts()` | Renvoie les instances GUI nommées |
| `window:SetPartLayout(name, options)` / `window:ResetPartLayout(name)` | Impose ou réinitialise la disposition d’une partie GUI |
| `window:Animate(instance, properties, options?)` | Anime une instance appartenant à la fenêtre |
| `window:BindColor(instance, property, token)` | Lie une couleur d’instance à un token du thème |
| `window:On(name, callback)` / `window:Connect(signal, callback)` | Abonnement à un événement de la lib ou à un signal Roblox |
| `window:Own(resource)` / `window:OnDestroy(callback)` | Nettoyage de ressources à la destruction |
| `window:Destroy()` | Détruit la fenêtre et ses ressources |

## Onglets, sections et catégories

`tab:Section(titleOrOptions)` renvoie une section. Un onglet et une section acceptent `Button`, `Toggle`, `Slider`, `Dropdown`, `Input`, `Keybind`, `ColorPicker`, `Paragraph`, `Custom` et `Add`. Voir [Composants](../composants.md) pour les paramètres.

Une catégorie expose `category:Tab(title, iconOrOptions?)`, `category:SetTitle(title)` et `category:Destroy()` ; sa destruction détruit aussi ses onglets.

`tab:SetOrder(order)` et `section:SetOrder(order)` changent l’ordre visuel. `tab:SetLayout(options)` change les options locales de navigation. `SetVisible(enabled)` et `Destroy()` sont aussi disponibles sur ces conteneurs.

## Composant `control`

| Appel | Usage |
|---|---|
| `control:Get()` | Valeur courante d’un contrôle à valeur |
| `control:Set(value, fireCallback?)` | Modifie la valeur ; callback seulement si `true` et valeur changée |
| `control:SetTitle(text)` / `control:SetDescription(text)` | Change le texte |
| `control:SetEnabled(enabled)` / `control:SetVisible(visible)` | Activation ou visibilité |
| `control:SetLayout(options)` / `control:SetOrder(order)` | Disposition ou ordre |
| `control:GetParts()` | Instances GUI exposées par le composant |
| `control:Animate(properties, options?)` | Anime la racine du composant |
| `control:On(name, callback)` / `control:Connect(signal, callback)` / `control:Own(resource)` | Événements, signaux et nettoyage |
| `control:Destroy()` | Retire le composant et libère ses ressources |

Le dropdown ajoute `SetOptions(options, value?)`. Le ColorPicker ajoute `GetColor()`. Le Custom ajoute `SetHeight(height)`. Les boutons et paragraphes n’ont pas de valeur persistante à lire avec `Get()` ou modifier avec `Set()`.

## Composants personnalisés

```lua
local custom = tab:Custom({
    Title = "Mon contenu", Height = 60,
    Build = function(content)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Text = "Contenu Roblox personnalisé"
        label.Parent = content
    end,
})
```

Ce bloc utilise un `tab` existant. `Build(content, control, window)` reçoit le frame où créer tes instances. Pour réutiliser un composant, enregistre son builder avec `UI:RegisterComponent(name, builder)`, puis crée-le avec `tab:Add(name, options)`. `UI:GetComponentNames()` les liste ; `UI:UnregisterComponent(name, expectedBuilder)` retire un enregistrement.

## Icônes

`UI:Icon(parent, idOrName, options)` dessine une icône. `GetIconNames`, `GetIconId`, `GetIconName`, `GetIconCatalogue` et `GetIconVariants` lisent le catalogue. `RegisterIcon(name, builder)` et `UnregisterIcon(name, expectedBuilder)` gèrent les dessins personnalisés. Voir [Icônes](icones.md).

## Loader, dialogue de clé et session

| Objet | Méthodes publiques |
|---|---|
| `loader` | `SetProgress(ratio, status?)`, `SetStatus(text)`, `Update(options)`, `Run(steps)`, `GetParts()`, `SetPartLayout(name, options)`, `ResetPartLayout(name)`, `Own(resource)`, `Complete(status?)`, `Destroy()` |
| `gate` | `Submit(key)`, `Cancel()`, `Destroy()`, `Update(options)`, `GetParts()`, `SetPartLayout(name, options)`, `ResetPartLayout(name)`, `CopyDiscordLink()`, `GetKey()` |
| `session` | `Cancel()`, `Destroy()` ; propriétés `Status`, `Window`, `Loader`, `Gate`, `LastError` |

`gate:Cancel()` annule une tentative et conserve le dialogue ; `gate:Destroy()` le ferme. Une session `Launch` expose les statuts `WaitingForKey`, `Loading`, `Ready`, `Failed` ou `Destroyed`.

Les exemples de raccordement sont dans [Chargement et accès](../chargement-acces.md). Pour les SDK de fournisseurs, le stockage et les autres flux spécialisés, les [guides avancés existants](https://github.com/Gabibou455/GabibouUI/tree/main/gabibou_ui/mintlify) restent disponibles dans le dépôt.
