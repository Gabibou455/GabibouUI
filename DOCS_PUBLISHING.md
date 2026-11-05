# Maintenir et publier la documentation

La source du guide utilisateur français est `docs/`, en Markdown compatible GitBook. Les sections d’options et le catalogue sont générés depuis les sources Luau. `gabibou_ui/mintlify` reste la racine de la documentation déjà hébergée et reçoit les mêmes guides par génération.

## Modifier les guides

1. Modifie les Markdown dans `docs/`. Pour le menu complet, modifie `docs/examples/menu-complet.luau`.
2. Lance `node gabibou_ui/sync_docs.cjs` depuis la racine du dépôt.
3. Lance `node gabibou_ui/check_docs.cjs`. Définis `LUAU_COMPILE_BIN` vers l’exécutable officiel Luau pour compiler les exemples en plus des vérifications documentaires.
4. Commits et push sur `main` mettent à jour les fichiers suivis par la documentation hébergée. Vérifie son déploiement avant d’annoncer une publication réussie.

Ne modifie pas manuellement les pages Mintlify portant le commentaire `Generated from docs/`. Les liens internes du Markdown sont transformés vers leurs routes Mintlify, et les sources restent lisibles directement sur GitHub.

## Connecter GitBook

Le dépôt est préparé pour Git Sync selon la [configuration officielle GitBook](https://gitbook.com/docs/docs-as-code/git-sync/content-configuration).

1. Connecte-toi à ton organisation GitBook et crée ou choisis le site/espace de Gabibou UI.
2. Configure GitHub Sync sur `Gabibou455/GabibouUI`, branche `main`.
3. Pour une configuration au niveau du dépôt, conserve le project directory à la racine : `.gitbook.yaml` sélectionne `docs/`. Si l’interface propose une association de répertoire pour un espace, associe cet espace à `docs` : `docs/.gitbook.yaml` sélectionne alors sa racine locale.
4. Choisis le premier import **GitHub → GitBook**. `docs/SUMMARY.md` définit le sommaire ; `docs/README.md` définit l’accueil. Évite un premier import GitBook → GitHub qui pourrait remplacer la documentation préparée.
5. Vérifie les pages et l’exemple dans Preview, puis publie le site avec son sous-domaine disponible. Un domaine personnalisé ou un abonnement payant doit être décidé par le propriétaire.
6. Une fois l’URL publique vérifiée, ajoute-la au README du dépôt. Tant que ce n’est pas fait, les liens pointent vers le guide lisible sur GitHub et le site Mintlify existant.

La création des fichiers de configuration ne crée pas de compte ou de site GitBook et ne prouve pas qu’une synchronisation ou une publication ait eu lieu.
