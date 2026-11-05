// Canonical GitBook Markdown -> existing Mintlify deployment.
// No website code or hosting account is needed to read docs/ on GitHub.
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const docs = path.join(root, 'docs');
const mint = path.join(__dirname, 'mintlify');
const routes = {
  'README.md': 'index',
  'demarrer.md': 'getting-started/quickstart',
  'exemple-complet.md': 'examples/quickstart',
  'composants.md': 'customization/controls',
  'apparence-mobile.md': 'customization/appearance-and-layout',
  'valeurs-profils.md': 'customization/values-and-config',
  'notifications-commandes.md': 'guide/notifications-commandes',
  'chargement-acces.md': 'guide/chargement-acces',
  'depannage.md': 'guide/depannage',
  'reference/api.md': 'reference/api',
  'reference/options.md': 'reference/customization',
  'reference/icones.md': 'reference/icon-catalogue',
};
function read(file) { return fs.readFileSync(path.join(__dirname, file), 'utf8'); }
function write(file, text) {
  fs.mkdirSync(path.dirname(file), {recursive: true});
  fs.writeFileSync(file, text.replace(/\r\n/g, '\n'));
}
function defaults(source, name) {
  const body = source.match(new RegExp('Library\\.' + name + '\\s*=\\s*(?:Library\\.' + name + '\\s+or\\s*)?\\{([^}]+)\\}'))?.[1];
  if (!body) throw Error('Missing source defaults: ' + name);
  return [...body.matchAll(/(\w+)\s*=\s*([^,\n]+)/g)].map(([,key,value])=>[key,value.trim()]);
}
function table(rows) {
  return '| Option | Valeur par défaut |\n|---|---|\n' + rows.map(([k,v])=>'| `'+k+'` | `'+v+'` |').join('\n') + '\n';
}
function generateReferences() {
  const sources = [['Disposition : `Layout`','layout.luau','Layout'],['Style : `Style`','extensions.luau','Style'],['Animation : `Motion`','extensions.luau','Motion'],['Navigation : `Navigation`','navigation.luau','Navigation'],['Notifications : `Notifications`','notifications.luau','Notifications']];
  const rangeBody = read('layout.luau').match(/local layoutRanges=\{([^\n]+)\}/)?.[1];
  if (!rangeBody) throw Error('Missing layout ranges');
  const ranges = Object.fromEntries([...rangeBody.matchAll(/(\w+)=\{([^}]+)\}/g)].map(([,key,v])=>[key,v.split(',').join('–')]));
  let content = '# Options et valeurs par défaut\n\nCes tableaux sont générés depuis les fichiers Luau par `node gabibou_ui/sync_docs.cjs`. Ils décrivent les sources de ce dépôt.\n\n';
  content += '## Fenêtre\n\n`UI:CreateWindow(title, options)` accepte notamment `Id`, `Title`, `Subtitle`, `Design`, `Theme`, `Style`, `Motion`, `Branding`, `Layout`, `Navigation`, `Notifications`, `Responsive`, `Width`, `Height`, `Position`, `AnchorPoint`, `ToggleKey`, `ShowWatermark`, `ReducedMotion`, `Parent`, `DisplayOrder`, `DiscordPrompt` et `Storage`.\n\n';
  content += '| Option | Défaut et limites |\n|---|---|\n| `Width`, `Height` | 800 × 590 ; bornés à 320–1400 et 300–1000 px |\n| `Theme` | `Graphite` ; accepte aussi `Aurora`, `Ember` ou une table de couleurs |\n| `ToggleKey` | `Enum.KeyCode.RightControl` |\n| `DisplayOrder` | 90 |\n| `ShowWatermark` | `true` |\n| `Parent` | `PlayerGui` du joueur local |\n\n';
  const ui = read('ui.luau');
  const responsiveBody = ui.match(/responsive=\{([^\n]+)\}/)?.[1];
  if (!responsiveBody) throw Error('Missing responsive defaults');
  const responsiveRows = [...responsiveBody.matchAll(/(\w+)=responsive\.\w+ or ([\d.]+)/g)].map(([,k,v])=>[k,v]);
  content += '## Responsive\n\n' + table(responsiveRows);
  content += '\nPlages : `Breakpoint` 320–1000, `TouchTarget` 44–72, `Margin` 4–40, `LandscapeHeight` 0–700. Pour les gestes et orientations : [Apparence et mobile](../apparence-mobile.md).\n\n';
  for (const [title,file,name] of sources) {
    const rows = defaults(read(file),name);
    content += '## '+title+'\n\n';
    if (name === 'Layout') {
      content += '| Option | Défaut | Plage ou choix |\n|---|---|---|\n' + rows.map(([k,v])=> '| `'+k+'` | `'+v+'` | '+(ranges[k] || ({TabPosition:'Left, Right, Top, Bottom',MobileTabPosition:'Top, Bottom',ControlsPosition:'Left, Right, Below'}[k] || 'Booléen'))+' |').join('\n')+'\n\n';
    } else content += table(rows)+'\n';
  }
  content += '## Limites des options locales\n\nLes contrôles acceptent `Layout = {Order, Width, Height, Position}`. `Order` est un entier entre -100000 et 100000, `Width` vaut 58–600 px, `Height` 44–160 px et `Position` accepte `Left`, `Right` ou `Below`. Les onglets acceptent `Order`, `Width`, `Height` et `IconSize` (12–40 px).\n\n';
  content += 'Les tailles de texte du style acceptent 10–32 ; les rayons 0–32 ; `RowPadding` 8–32. Les options de disposition et de style hors plage sont rejetées. `Duration` et `Delay` acceptent 0–30 secondes ; `RepeatCount` est un entier entre -1 et 100.\n\n';
  content += '## Couleurs et icônes\n\nLes tokens du thème sont `Background`, `Surface`, `Raised`, `Hover`, `Border`, `Text`, `Muted`, `Accent`, `AccentText`, `Success`, `Danger`. Une table de thème partielle complète ses couleurs avec celles de Graphite.\n\n`Branding` accepte `Mode` (Initials, Avatar, Image), `Placement` (TopLeft, TopRight, BottomRight, BothRight), `Text`, `Image` et `UserId`. Les variantes d’icônes sont `Outline`, `Soft`, `Duotone`. Voir [Icônes](icones.md).\n\n';
  content += 'Pour les méthodes : [API](api.md). Pour une option spécialisée de fournisseur, consulte aussi les exemples de raccordement du dépôt.\n';
  write(path.join(docs,'reference/options.md'),content);
  const icons = read('icons.luau').match(/local builtinNames\s*=\s*\{([\s\S]*?)\n\}/)?.[1];
  if (!icons) throw Error('Missing icon catalogue');
  const names = [...icons.matchAll(/"([a-z][a-z0-9-]*)"/g)].map(m=>m[1]);
  let catalogue = '# Catalogue des icônes\n\n'+names.length+' dessins intégrés, utilisables par nom ou ID. Ce sont des IDs internes Gabibou UI, pas des IDs d’images Roblox. Les dessins intégrés ne nécessitent aucun téléchargement d’image.\n\n';
  catalogue += '```lua\nlocal tab = window:Tab("Accueil", "home")\ntab:Button("Actualiser", {Icon = "refresh", IconVariant = "Duotone"}, function()\n    print("Actualisation")\nend)\n```\n\nCe bloc utilise un `window` existant. Les variantes sont `Outline` (défaut), `Soft` et `Duotone`. Les noms sont sensibles à la casse.\n\n| ID | Nom |\n|---:|---|\n';
  catalogue += names.map((name,index)=>'| '+(index+1)+' | `'+name+'` |').join('\n')+'\n\n';
  catalogue += '`UI:GetIconId("home")` renvoie 1 ; `UI:GetIconName(1)` renvoie `home`. Les dessins personnalisés enregistrés avec `RegisterIcon` obtiennent des IDs à partir de 1000. Pour prévisualiser les fichiers PNG/SVG hors ligne, télécharge l’archive du projet puis ouvre `GabibouUI_Icons/index.html`.\n';
  write(path.join(docs,'reference/icones.md'),catalogue);
}
function sync() {
  generateReferences();
  const exampleFile = path.join(docs,'exemple-complet.md');
  const example = fs.readFileSync(path.join(docs,'examples/menu-complet.luau'),'utf8').trimEnd();
  const page = fs.readFileSync(exampleFile,'utf8');
  const marker = /<!-- example:menu-complet -->[\s\S]*?<!-- \/example:menu-complet -->/;
  if (!marker.test(page)) throw Error('Missing complete example markers');
  write(exampleFile,page.replace(marker,'<!-- example:menu-complet -->\n```lua\n'+example+'\n```\n<!-- /example:menu-complet -->'));
  for (const [file,route] of Object.entries(routes)) {
    const source = fs.readFileSync(path.join(docs,file),'utf8').replace(/\r\n/g,'\n');
    const title = source.match(/^# (.+)$/m)?.[1];
    if (!title) throw Error('Missing document title: '+file);
    const body = source.replace(/^# .+\n+/,'').replace(/<!--([\s\S]*?)-->/g,'{/*$1*/}').replace(/\]\(([^\s)]+)\)/g,(match,href)=>{
      if (/^(https?:|mailto:|#)/.test(href)) return match;
      const [target,anchor] = href.split('#');
      const resolved = path.posix.normalize(path.posix.join(path.posix.dirname(file),target));
      if (!routes[resolved]) throw Error('Unmapped canonical link: '+file+' -> '+href);
      return '](/'+routes[resolved]+(anchor?'#'+anchor:'')+')';
    });
    write(path.join(mint,route+'.mdx'),'---\ntitle: '+JSON.stringify(title)+'\ndescription: '+JSON.stringify('Guide pratique Gabibou UI : '+title.toLowerCase())+'\n---\n\n{/* Generated from docs/'+file+' by sync_docs.cjs. */}\n\n'+body);
  }
  const configPath = path.join(mint,'docs.json');
  const config = JSON.parse(fs.readFileSync(configPath,'utf8'));
  config.description = 'Documentation française de Gabibou UI : exemple complet, composants, mobile et référence API.';
  config.navigation = {tabs:[
    {tab:'Guide',groups:[{group:'Commencer',pages:['index','getting-started/quickstart','examples/quickstart']},{group:'Construire son interface',pages:['customization/controls','customization/appearance-and-layout','customization/values-and-config','guide/notifications-commandes','guide/chargement-acces','guide/depannage']}]},
    {tab:'Référence',pages:['reference/api','reference/customization','reference/icon-catalogue']},
    {tab:'Avancé',groups:[{group:'Installation et design',pages:['getting-started/installation','customization/design-your-interface','customization/icons-and-branding']},{group:'Flux spécialisés',pages:['customization/commands-and-presets','customization/loading-screens','customization/key-systems','customization/events-and-lifecycle','customization/animations-and-components','customization/notifications']},{group:'Exemples détaillés',pages:['examples/loading','examples/discord-prompt','examples/key-discord','examples/key-providers','examples/key-external-server','examples/server-validation','examples/remote-loading']},{group:'IA et vérification',pages:['getting-started/use-with-ai','ai/agent-guide','reference/quality']}]},
  ]};
  write(configPath,JSON.stringify(config,null,2)+'\n');
  return {canonicalPages:Object.keys(routes).length,mintlifyPages:Object.keys(routes).length};
}
module.exports = {sync,routes,root,docs,mint};
if(require.main===module) console.log(JSON.stringify(sync()));
