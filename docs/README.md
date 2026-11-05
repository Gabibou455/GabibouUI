# Gabibou UI in one minute

Gabibou UI builds Roblox menus in Luau: windows, tabs, buttons, settings and notifications. It adapts to desktop and mobile screens.

**Start with the [complete example](exemple-complet.md).** Copy one script to get working settings, a theme selector and a reset button.

| Object | What it represents | Example |
|---|---|---|
| `UI` | The loaded library | `UI:CreateWindow("My menu")` |
| `window` | A window containing tabs | `window:Tab("Settings", "settings")` |
| `tab` or `section` | Where you add controls | `tab:Button("Hello", function() print("Hello") end)` |

A **callback** runs when a player uses a control. A toggle passes `true` or `false`; a slider passes a number.

## Find what you need

| I want to... | Page |
|---|---|
| Install the library | [Getting started](demarrer.md) |
| Copy a working menu | [Complete example](exemple-complet.md) |
| Add buttons, toggles, sliders or inputs | [Controls](composants.md) |
| Change the theme or mobile layout | [Appearance and mobile](apparence-mobile.md) |
| Read values and save profiles | [Values and profiles](valeurs-profils.md) |
| Show messages or confirmations | [Notifications and commands](notifications-commandes.md) |
| Add a loader or key screen | [Loading and access](chargement-acces.md) |
| Fix a problem | [Troubleshooting](depannage.md) |
| Find a method or exact default | [API](reference/api.md) / [Options](reference/options.md) / [Icons](reference/icones.md) |

These guides describe `main` in the [GabibouUI repository](https://github.com/Gabibou455/GabibouUI). An older installed tag may support fewer features.
