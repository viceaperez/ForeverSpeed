const {lua,lauxlib,lualib,to_luastring}=require("fengari");const fs=require("fs"),path=require("path");
const root=process.argv[2]||path.join(__dirname,"..");
const files=fs.readFileSync(path.join(root,"ForeverSpeed.toc"),"utf8").split(/\r?\n/).filter(l=>l&&!l.startsWith("#"));
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
lua.lua_createtable(L,0,0);
files.forEach((f,i)=>{lua.lua_createtable(L,0,2);
  lua.lua_pushstring(L,to_luastring(f));lua.lua_setfield(L,-2,to_luastring("name"));
  lua.lua_pushstring(L,to_luastring(fs.readFileSync(path.join(root,f.split(String.fromCharCode(92)).join("/")),"utf8")));lua.lua_setfield(L,-2,to_luastring("src"));
  lua.lua_rawseti(L,-2,i+1);});
lua.lua_setglobal(L,to_luastring("FILES"));
if(lauxlib.luaL_dofile(L,to_luastring(path.join(__dirname,"harness.lua")))!==0){console.log("ERROR:",lua.lua_tojsstring(L,-1));process.exit(1)}
