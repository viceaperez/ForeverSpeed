const lp=require("luaparse"),fs=require("fs"),path=require("path");
const root=process.argv[2]||path.join(__dirname,"..");
const toc=fs.readFileSync(path.join(root,"ForeverSpeed.toc"),"utf8").split(/\r?\n/).filter(l=>l&&!l.startsWith("#"));
const g=new Set(),defined=new Set(),used=new Map();
for(const f of toc){const src=fs.readFileSync(path.join(root,f.split(String.fromCharCode(92)).join("/")),"utf8");
  const ast=lp.parse(src,{scope:true});ast.globals.forEach(x=>g.add(x.name));
  for(const m of src.matchAll(/\bns\.(\w+)\s*=(?!=)/g))defined.add(m[1]);
  for(const m of src.matchAll(/function ns\.(\w+)/g))defined.add(m[1]);
  for(const m of src.matchAll(/\bns\.(\w+)/g)){if(!used.has(m[1]))used.set(m[1],f)}
  console.log("OK",f);}
console.log("globals:",[...g].sort().join(" "));
console.log("ns used but never defined:",[...used.keys()].filter(k=>!defined.has(k)).join(" ")||"none");
