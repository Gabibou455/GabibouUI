# Gabibou UI en une minute

Gabibou UI construit des menus Roblox en Luau : fenêtres, onglets, boutons, réglages et notifications. L’affichage s’adapte au bureau et au mobile.

**Pour commencer, copie [l’exemple complet](exemple-complet.md).** Il contient le chargement de la bibliothèque, une fenêtre, des réglages fonctionnels et un bouton de réinitialisation.

Les trois objets à connaître :

| Objet | Ce qu’il représente | Exemple |
|---|---|---|
| `UI` | La bibliothèque chargée | `UI:CreateWindow("Mon menu")` |
| `window` | Une fenêtre avec ses onglets | `window:Tab("Réglages", "settings")` |
| `tab` ou `section` | L’endroit où ajouter des composants | `tab:Button("Bonjour", function() print("Bonjour") end)` |

Une **callback** est la fonction appelée lorsque le joueur utilise un composant. Un toggle lui transmet `true` ou `false`, un slider lui transmet un nombre.

## Trouver directement la bonne page

| Je veux… | Page |
|---|---|
| Installer la lib dans Studio ou la charger à distance | [Démarrer](demarrer.md) |
| Copier un menu entier | [Exemple complet](exemple-complet.md) |
| Ajouter un toggle, slider, dropdown ou champ de texte | [Composants](composants.md) |
| Changer le thème, les onglets ou le comportement mobile | [Apparence et mobile](apparence-mobile.md) |
| Lire une valeur, la changer ou enregistrer un profil | [Valeurs et profils](valeurs-profils.md) |
| Afficher un message ou une confirmation | [Notifications et commandes](notifications-commandes.md) |
| Ajouter un loader ou une saisie de clé | [Chargement et accès](chargement-acces.md) |
| Comprendre une erreur | [Dépannage](depannage.md) |
| Retrouver une méthode ou une valeur exacte | [API](reference/api.md) · [Options](reference/options.md) · [Icônes](reference/icones.md) |

Les guides décrivent la branche `main` du [dépôt GabibouUI](https://github.com/Gabibou455/GabibouUI). Une version installée depuis un ancien tag peut avoir moins de fonctionnalités.
