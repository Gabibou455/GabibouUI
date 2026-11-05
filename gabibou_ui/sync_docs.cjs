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
  return '| Option | Default |\n|---|---|\n' + rows.map(([k,v])=>'| `'+k+'` | `'+v+'` |').join('\n') + '\n';
}
function generateReferences() {
  const sources = [['Layout','layout.luau','Layout'],['Style','extensions.luau','Style'],['Motion','extensions.luau','Motion'],['Navigation','navigation.luau','Navigation'],['Notifications','notifications.luau','Notifications']];
  const rangeBody = read('layout.luau').match(/local layoutRanges=\{([^\n]+)\}/)?.[1];
  if (!rangeBody) throw Error('Missing layout ranges');
  const ranges = Object.fromEntries([...rangeBody.matchAll(/(\w+)=\{([^}]+)\}/g)].map(([,key,v])=>[key,v.split(',').join('–')]));
  let content = '# Options and defaults\n\nThese tables are generated from production Luau sources by `node gabibou_ui/sync_docs.cjs`. They describe the source in this repository.\n\n';
  content += '## Window\n\n`UI:CreateWindow(title, options)` accepts `Id`, `Title`, `Subtitle`, `Design`, `Theme`, `Style`, `Motion`, `Branding`, `Layout`, `Navigation`, `Notifications`, `Responsive`, `Width`, `Height`, `Position`, `AnchorPoint`, `ToggleKey`, `ShowWatermark`, `ReducedMotion`, `Parent`, `DisplayOrder`, `DiscordPrompt` and `Storage`.\n\n';
  content += '| Option | Default and limits |\n|---|---|\n| `Width`, `Height` | 800 x 590; clamped to 320-1400 and 300-1000 px |\n| `Theme` | `Graphite`; also accepts `Aurora`, `Ember` or a color-token table |\n| `ToggleKey` | `Enum.KeyCode.RightControl` |\n| `DisplayOrder` | 90 |\n| `ShowWatermark` | `true` |\n| `Parent` | Local player\'s `PlayerGui` |\n\n';
  const ui = read('ui.luau');
  const responsiveBody = ui.match(/responsive=\{([^\n]+)\}/)?.[1];
  if (!responsiveBody) throw Error('Missing responsive defaults');
  const responsiveRows = [...responsiveBody.matchAll(/(\w+)=responsive\.\w+ or ([\d.]+)/g)].map(([,k,v])=>[k,v]);
  content += '## Responsive\n\n' + table(responsiveRows);
  content += '\nRanges: `Breakpoint` 320-1000, `TouchTarget` 44-72, `Margin` 4-40, `LandscapeHeight` 0-700. For gestures and orientation changes, see [Appearance and mobile](../apparence-mobile.md).\n\n';
  for (const [title,file,name] of sources) {
    const rows = defaults(read(file),name);
    content += '## '+title+'\n\n';
    if (name === 'Layout') {
      content += '| Option | Default | Range or choices |\n|---|---|---|\n' + rows.map(([k,v])=> '| `'+k+'` | `'+v+'` | '+(ranges[k] || ({TabPosition:'Left, Right, Top, Bottom',MobileTabPosition:'Top, Bottom',ControlsPosition:'Left, Right, Below'}[k] || 'Boolean'))+' |').join('\n')+'\n\n';
    } else content += table(rows)+'\n';
  }
  content += '## Local layout limits\n\nControls accept `Layout = {Order, Width, Height, Position}`. `Order` is an integer from -100000 to 100000, `Width` is 58-600 px, `Height` is 44-160 px and `Position` accepts `Left`, `Right` or `Below`. Tabs accept `Order`, `Width`, `Height` and `IconSize` (12-40 px).\n\n';
  content += 'Style text sizes accept 10-32, corner radii 0-32, and `RowPadding` 8-32. Out-of-range layout and style options are rejected. `Duration` and `Delay` accept 0-30 seconds; `RepeatCount` is an integer from -1 to 100.\n\n';
  content += '## Colors and icons\n\nTheme tokens are `Background`, `Surface`, `Raised`, `Hover`, `Border`, `Text`, `Muted`, `Accent`, `AccentText`, `Success`, `Danger`. Partial theme tables inherit omitted colors from Graphite.\n\n`Branding` accepts `Mode` (Initials, Avatar, Image), `Placement` (TopLeft, TopRight, BottomRight, BothRight), `Text`, `Image` and `UserId`. Icon variants are `Outline`, `Soft`, `Duotone`. See [Icons](icones.md).\n\n';
  content += 'See [API methods](api.md) for available calls and repository examples for provider-specific integration options.\n';
  write(path.join(docs,'reference/options.md'),content);
  const icons = read('icons.luau').match(/local builtinNames\s*=\s*\{([\s\S]*?)\n\}/)?.[1];
  if (!icons) throw Error('Missing icon catalogue');
  const names = [...icons.matchAll(/"([a-z][a-z0-9-]*)"/g)].map(m=>m[1]);
  let catalogue = '# Icon catalogue\n\n'+names.length+' built-in drawings, usable by name or ID. These are internal Gabibou UI IDs, not Roblox image asset IDs. Built-in drawings require no image downloads.\n\n';
  catalogue += '```lua\nlocal tab = window:Tab("Home", "home")\ntab:Button("Refresh", {Icon = "refresh", IconVariant = "Duotone"}, function()\n    print("Refresh")\nend)\n```\n\nThis block uses an existing `window`. Variants are `Outline` (default), `Soft` and `Duotone`. Names are case-sensitive.\n\n| ID | Name |\n|---:|---|\n';
  catalogue += names.map((name,index)=>'| '+(index+1)+' | `'+name+'` |').join('\n')+'\n\n';
  catalogue += '`UI:GetIconId("home")` returns 1; `UI:GetIconName(1)` returns `home`. Custom drawings registered with `RegisterIcon` receive IDs starting at 1000. For offline PNG/SVG previews, download the project archive and open `GabibouUI_Icons/index.html`.\n';
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
    write(path.join(mint,route+'.mdx'),'---\ntitle: '+JSON.stringify(title)+'\ndescription: '+JSON.stringify('Practical Gabibou UI guide: '+title.toLowerCase())+'\n---\n\n{/* Generated from docs/'+file+' by sync_docs.cjs. */}\n\n'+body);
  }
  const configPath = path.join(mint,'docs.json');
  const config = JSON.parse(fs.readFileSync(configPath,'utf8'));
  config.description = 'Gabibou UI documentation: a complete example, controls, mobile layouts and API reference.';
  config.navigation = {tabs:[
    {tab:'Guide',groups:[{group:'Get started',pages:['index','getting-started/quickstart','examples/quickstart']},{group:'Build your interface',pages:['customization/controls','customization/appearance-and-layout','customization/values-and-config','guide/notifications-commandes','guide/chargement-acces','guide/depannage']}]},
    {tab:'Reference',pages:['reference/api','reference/customization','reference/icon-catalogue']},
    {tab:'Advanced',groups:[{group:'Installation and design',pages:['getting-started/installation','customization/design-your-interface','customization/icons-and-branding']},{group:'Specialized workflows',pages:['customization/commands-and-presets','customization/loading-screens','customization/key-systems','customization/events-and-lifecycle','customization/animations-and-components','customization/notifications']},{group:'Detailed examples',pages:['examples/loading','examples/discord-prompt','examples/key-discord','examples/key-providers','examples/key-external-server','examples/server-validation','examples/remote-loading']},{group:'AI and verification',pages:['getting-started/use-with-ai','ai/agent-guide','reference/quality']}]},
  ]};
  write(configPath,JSON.stringify(config,null,2)+'\n');
  return {canonicalPages:Object.keys(routes).length,mintlifyPages:Object.keys(routes).length};
}
module.exports = {sync,routes,root,docs,mint};
if(require.main===module) console.log(JSON.stringify(sync()));
