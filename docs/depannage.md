# Résoudre un problème

## L’interface ne s’affiche pas

| Symptôme | Vérification |
|---|---|
| Rien dans Studio en mode édition | Lance **Play**. Le menu est créé par un LocalScript. |
| `WaitForChild("GabibouUI")` attend indéfiniment | Vérifie le nom exact et la présence du ModuleScript dans `ReplicatedStorage`. |
| Erreur liée à `loadstring` ou `HttpGet` dans Studio | Utilise le chargement par ModuleScript décrit dans [Démarrer](demarrer.md). |
| Erreur au `require` ou à la compilation | Vérifie que tu as copié le module autonome complet, pas un fichier partiel de `gabibou_ui/`. |
| Téléchargement distant impossible | Ouvre l’URL du module et vérifie les fonctions et l’accès réseau de ton environnement. |
| La fenêtre était visible puis a disparu | Essaie `window:Show()` ou le bouton **Open** après minimisation. Une fenêtre détruite doit être recréée. |

Lis la **première erreur** dans Output : les erreurs suivantes peuvent en découler.

## Un composant ne réagit pas comme prévu

| Symptôme | Cause fréquente ou correction |
|---|---|
| La callback ne se lance pas à la création | C’est le comportement normal. Initialise ton système avec la valeur de départ dans ton code. |
| `Set(value)` ne lance pas la callback | Utilise `Set(value, true)` ; la valeur doit effectivement changer. |
| Un ID existe déjà | Donne un `Id` distinct à chaque composant dans la fenêtre. Ne colle pas deux variantes du même exemple. |
| La valeur du dropdown est refusée | `Value` doit correspondre exactement à une chaîne de `Options`. |
| Le slider refuse les paramètres | `Min < Max`, `Step > 0`, valeurs numériques finies. |
| Le raccourci ne fonctionne pas | Évite la saisie dans un TextBox et garde un bouton visible si Roblox ou ton environnement intercepte la touche. |
| Une action affiche une notification d’erreur | Lis `window.LastError` et Output pour retrouver l’erreur complète de la callback. |

## Les profils disparaissent après relancement

Les profils sont en mémoire par défaut. Ajoute un adaptateur `Storage.Read/Write` et configure `StorageKey` avant de créer des profils pour les conserver entre les sessions. Voir [Valeurs et profils](valeurs-profils.md).

## L’affichage mobile dépasse

Commence avec `Responsive = {TouchTarget = 48}` et la disposition automatique. Les contrôles `Custom` et les overrides `SetPartLayout` doivent tenir compte de la largeur disponible. Vérifie portrait, paysage, ouverture du clavier et minimisation. Les tests de géométrie de la lib ne remplacent pas les essais natifs dans ton projet.

## Une méthode de la documentation manque

Affiche `print(UI.Version)` et vérifie d’où vient le module installé. La documentation courante suit `main` ; un tag figé ou une ancienne copie Studio peut être plus ancien. Recopie le module si nécessaire, puis relance la session de test.

## Fournir un problème reproductible

Partage le chargement utilisé, `UI.Version`, le premier message d’erreur et le plus petit script qui reproduit le défaut. Pour une erreur d’affichage, ajoute la taille de l’écran et l’orientation. Les [méthodes](reference/api.md) et [valeurs par défaut](reference/options.md) servent de référence.
