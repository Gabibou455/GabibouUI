const fs=require('node:fs');
const path=require('node:path');
const root=path.resolve(__dirname,'..');
const logic=fs.readFileSync(path.join(__dirname,'logic.luau'),'utf8');
const ui=fs.readFileSync(path.join(__dirname,'ui.luau'),'utf8');
const version=ui.match(/Version="([0-9]+\.[0-9]+\.[0-9]+(?:-[a-z0-9.]+)?)"/)?.[1];
if(!version)throw Error('Library version missing or invalid');
const extensions=['extensions.luau','icons.luau','navigation.luau','branding.luau','layout.luau','loading.luau','key_system.luau','convenience.luau','launch.luau','notifications.luau','easy.luau','categories.luau'].map(file=>fs.readFileSync(path.join(__dirname,file),'utf8')).join('\n');
if(!/\nreturn Library\s*$/.test(ui))throw Error('UI export marker missing');
const combined=ui.replace(/\nreturn Library\s*$/, '\n'+extensions+'\nreturn Library\n');
const source='-- Gabibou UI v'+version+' | Original Roblox client GUI library\n-- No external UI or telemetry. Optional Roblox assets and avatar thumbnails.\nlocal Logic=(function()\n'+logic+'\nend)()\n'+combined;
fs.writeFileSync(path.join(root,'gabibou_ui.luau'),source);
const iconSource=fs.readFileSync(path.join(__dirname,'icons.luau'),'utf8');
const builtinBlock=iconSource.match(/local builtinNames\s*=\s*\{([\s\S]*?)\n\}/);
if(!builtinBlock)throw Error('Built-in icon catalogue missing');
const iconNames=[...builtinBlock[1].matchAll(/"([a-z][a-z0-9-]*)"/g)].map(match=>match[1]);
const rows=iconNames.map((name,index)=>'| `'+name+'` | '+(index+1)+' |').join('\n');
const catalogue=`# Gabibou UI icons — names and IDs

${iconNames.length} original drawings, usable by name or ID. These IDs belong to Gabibou UI; they are not Roblox image asset IDs. No image download is required. Built-in IDs are stable: future icons will be appended to the list.

## Add an icon

\`\`\`lua
local farm = window:Tab({Title = "Farm", Icon = 21})
farm:Button({Title = "Harvest", Text = "Collect", Icon = 24, IconVariant = "Duotone"})
window:Notify({Title = "Harvest ready", Icon = 24})
local icon = UI:Icon(parent, 21, {Size = 24, Variant = "Soft"})
\`\`\`

Names work too: \`Icon = "farm"\` and \`Icon = "harvest"\`.
The three variants are \`Outline\` (default), \`Soft\` and \`Duotone\`. Use \`IconVariant\` on a tab or button, and \`Variant\` with \`UI:Icon\`.

## Built-in catalogue

| Name | ID |
|---|---:|
${rows}

## Look up an ID in your script

\`\`\`lua
local id = UI:GetIconId("harvest") -- 24
local name = UI:GetIconName(21) -- "farm"
for _, entry in ipairs(UI:GetIconCatalogue()) do
    print(entry.Name, entry.Id)
end
\`\`\`

These lookup methods return \`nil\` for an unknown name or ID. The returned catalogue is a copy. Drawing an icon with an unknown or non-integer ID is rejected before allocating its GUI.

Icons added with \`RegisterIcon(name, builder)\` automatically receive IDs starting at 1000. Look them up with \`GetIconId(name)\`; custom IDs depend on registration order within that library instance. \`UnregisterIcon\` also removes the ID, which is not reused in that instance.

The Icons page in \`demo.luau\` shows the drawings, IDs and variants. The optional \`GabibouUI_Icons\` folder contains their PNG and SVG exports. This document is regenerated from the built-in catalogue by \`node gabibou_ui/build.cjs\`.
`;
fs.writeFileSync(path.join(__dirname,'ICONS.md'),catalogue);
console.log('Built gabibou_ui.luau');
