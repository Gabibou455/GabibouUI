# Notifications et commandes

Ces blocs utilisent le `window` et le `tab` créés dans [Démarrer](demarrer.md).

## Afficher un message

```lua
window:Notify({
    Title = "Enregistré",
    Content = "Tes réglages ont été appliqués.",
    Kind = "success",
    Duration = 4,
})
```

`Kind` accepte `info`, `success`, `warning` et `error`. `Duration` est en secondes. La méthode renvoie une notification disposant de `Dismiss()` et `Destroy()`.

## Demander une confirmation

```lua
tab:Button("Réinitialiser", function()
    window:Confirm({
        Title = "Réinitialiser le volume ?",
        Content = "Le volume reviendra à 50.",
        ConfirmText = "Réinitialiser",
        Callback = function()
            local volume = window:Get("volume")
            if volume then volume:Set(50, true) end
        end,
    })
end)
```

La callback ne s’exécute qu’après confirmation. Annuler ne la lance pas. `Confirm` renvoie `false` si une autre confirmation est déjà ouverte.

## Ajouter une commande recherchable

```lua
window:Command({
    Id = "show_status",
    Title = "Afficher le statut",
    Keywords = {"status", "info"},
    Icon = "info",
    Callback = function()
        window:Notify({Title = "Interface prête", Kind = "success"})
    end,
})

tab:Button("Ouvrir les commandes", function()
    window:OpenCommands()
end)
```

Le bouton permet d’ouvrir la palette au toucher. Sur ordinateur, `Ctrl+K` tente de l’ouvrir ; l’environnement peut intercepter ce raccourci. Utilise les flèches et Entrée, ou active une commande à la souris/au toucher. `window:CloseCommands()` ferme la palette et `window:RemoveCommand("show_status")` retire la commande.

## Proposer un lien Discord

`window:PromptDiscord(urlOrOptions)` ouvre le dialogue d’invitation pour l’URL que tu fournis. Tu peux aussi passer `DiscordPrompt` à la création de la fenêtre. Cette option est désactivée par défaut ; elle ne rejoint jamais un serveur automatiquement. Utilise seulement une invitation réelle de ton projet.
