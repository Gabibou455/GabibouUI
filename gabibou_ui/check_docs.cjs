// Portable checks for GitBook Markdown, shared Mintlify routes and Luau examples.
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const cp = require('node:child_process');
const crypto = require('node:crypto');
const {sync,routes,root,docs,mint} = require('./sync_docs.cjs');
function assert(value,message) { if(!value) throw Error(message); }
function walk(dir) { return fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(path.join(dir,e.name)):[path.join(dir,e.name)]); }
function hash(file) { return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex'); }
function stripCode(text) { return text.replace(/```[^\n]*\n[\s\S]*?```/g,''); }
function slug(value) { return value.toLowerCase().replace(/`/g,'').replace(/[^\p{L}\p{N}_\s-]/gu,'').replace(/\s/g,'-'); }
function anchors(file) {
  const text=stripCode(fs.readFileSync(file,'utf8'));
  return new Set([...text.matchAll(/^#{1,6}\s+(.+)$/gm)].map(m=>slug(m[1])).concat([...text.matchAll(/\bid="([^"]+)"/g)].map(m=>m[1])));
}
function links(file,base,isMdx,errors) {
  const text=stripCode(fs.readFileSync(file,'utf8'));
  for(const [,href] of text.matchAll(/\]\(([^\s)]+)\)/g)) {
    if(/^(https?:|mailto:)/.test(href)) continue;
    const [url,fragment]=href.split('#');
    let target=url?(url.startsWith('/')?path.join(base,url.slice(1)):path.resolve(path.dirname(file),url)):file;
    if(isMdx&&!fs.existsSync(target)&&fs.existsSync(target+'.mdx')) target+='.mdx';
    if(!fs.existsSync(target)){errors.push(path.relative(root,file)+' -> missing '+href);continue;}
    if(fragment&&/\.(md|mdx)$/.test(target)&&!anchors(target).has(decodeURIComponent(fragment)))errors.push(path.relative(root,file)+' -> missing anchor '+href);
  }
}
const before=new Map(Object.keys(routes).filter(f=>fs.existsSync(path.join(docs,f))).map(f=>[f,hash(path.join(docs,f))]));
sync();
for(const [f,value] of before)assert(hash(path.join(docs,f))===value,'Stale generated documentation: '+f+'; run sync_docs.cjs and review changes');
const errors=[];
const canonical=Object.keys(routes).map(f=>path.join(docs,f));
const summary=fs.readFileSync(path.join(docs,'SUMMARY.md'),'utf8');
const summaryPages=[...summary.matchAll(/\]\(([^)]+)\)/g)].map(m=>m[1]);
assert(new Set(summaryPages).size===summaryPages.length,'Duplicate GitBook navigation page');
assert(summaryPages.length===canonical.length&&summaryPages.every(f=>routes[f]),'GitBook navigation differs from canonical routes');
for(const file of [...canonical,path.join(docs,'SUMMARY.md')]) links(file,docs,false,errors);
const mdx=walk(mint).filter(f=>f.endsWith('.mdx'));
for(const file of mdx) links(file,mint,true,errors);
const config=JSON.parse(fs.readFileSync(path.join(mint,'docs.json'),'utf8'));
function pages(v){if(Array.isArray(v))return v.flatMap(pages);if(v&&typeof v==='object')return Object.entries(v).flatMap(([k,x])=>k==='pages'?x.flatMap(y=>typeof y==='string'?[y]:pages(y)):pages(x));return [];}
const nav=pages(config.navigation);
assert(new Set(nav).size===nav.length,'Duplicate Mintlify navigation page');
assert(nav.every(p=>fs.existsSync(path.join(mint,p+'.mdx'))),'Missing Mintlify navigation page');
assert(nav.length===mdx.length,'Some Mintlify pages are absent from navigation');
const source=walk(__dirname).filter(f=>f.endsWith('.luau')&&path.dirname(f)===__dirname).map(f=>fs.readFileSync(f,'utf8')).join('\n');
const knownIcons=new Set([...fs.readFileSync(path.join(__dirname,'icons.luau'),'utf8').match(/local builtinNames\s*=\s*\{([\s\S]*?)\n\}/)[1].matchAll(/"([a-z][a-z0-9-]*)"/g)].map(m=>m[1]));
const samples=[];
for(const file of canonical) {
  const text=fs.readFileSync(file,'utf8');
  assert((text.match(/^# /gm)||[]).length===1,'Expected one page title: '+file);
  for(const [,code] of text.matchAll(/```lua\r?\n([\s\S]*?)```/g)) {
    samples.push({file,code});
    for(const [,icon] of code.matchAll(/\bIcon\s*=\s*"([^"]+)"/g))assert(knownIcons.has(icon),'Unknown example icon: '+icon);
    for(const [,icon] of code.matchAll(/:Tab\("[^"]+",\s*"([^"]+)"\)/g))assert(knownIcons.has(icon),'Unknown tab icon: '+icon);
    for(const [,method] of code.matchAll(/\b(?:UI|window|tab|settings|graphics|audio|loader|volume|effects|quality|color|control):([A-Z]\w*)\(/g)) {
      assert(new RegExp('(?:function\\s+[\\w.]+:'+method+'\\s*\\(|easy_constructor\\([^\\n]+"'+method+'")').test(source),'Undocumented implementation method in snippet: '+method);
    }
  }
}
assert(errors.length===0,errors.join('\n'));
const complete=fs.readFileSync(path.join(docs,'examples/menu-complet.luau'),'utf8').trimEnd();
assert(fs.readFileSync(path.join(docs,'exemple-complet.md'),'utf8').includes('```lua\n'+complete+'\n```'),'Complete example differs from downloadable source');
const localCompiler=path.resolve(root,'../ride_pet_diagnostics/luau_runtime/luau-compile.exe');
const compiler=process.env.LUAU_COMPILE_BIN||(fs.existsSync(localCompiler)?localCompiler:null);
if(compiler) {
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),'gabibou-docs-'));
  const files=samples.map((s,i)=>{const f=path.join(dir,'example-'+i+'.luau');fs.writeFileSync(f,s.code);return f;});
  try {
    const result=cp.spawnSync(compiler,['--null',...files],{encoding:'utf8',timeout:15000});
    if(result.error)throw result.error;
    assert(result.status===0,result.stderr||result.stdout||'Luau compile failed');
  } finally {for(const f of files)fs.rmSync(f,{force:true});fs.rmdirSync(dir);}
}
const result={gitbookPages:canonical.length,mintlifyPages:mdx.length,navigationPages:nav.length,brokenLinks:0,examples:samples.length,exampleCompilation:compiler?'passed':'not run; set LUAU_COMPILE_BIN',nativeRobloxExecution:false};
console.log(JSON.stringify(result));
