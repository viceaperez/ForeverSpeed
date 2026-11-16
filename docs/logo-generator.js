// Regenerates docs/logo.svg + PNGs. Needs: npm i @resvg/resvg-js
// Original "sprinting figure" icon in a WoW-style frame: warm amber glow, motion streaks, speed arc.
const fs=require("fs");const {Resvg}=require("@resvg/resvg-js");
const cx=256,cy=300,R=196;
const P=(a,r)=>[cx+r*Math.cos(a*Math.PI/180),cy-r*Math.sin(a*Math.PI/180)];
const arc=(a0,a1,r)=>{const[x0,y0]=P(a0,r),[x1,y1]=P(a1,r);return `M${x0.toFixed(1)} ${y0.toFixed(1)} A${r} ${r} 0 0 1 ${x1.toFixed(1)} ${y1.toFixed(1)}`};
// figure: thick round-capped limbs (pictogram), leaning forward
const limbs=[
 "M296 192 L238 292",                 // torso
 "M290 196 L338 246 L392 222",        // front arm
 "M284 194 L222 218 L178 270",        // back arm
 "M238 292 L316 322 L300 410",        // front leg
 "M238 292 L204 360 L124 372",        // back leg
];
const figure=(stroke,w)=>limbs.map(d=>`<path d="${d}" fill="none" stroke="${stroke}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round"/>`).join("")
 +`<circle cx="330" cy="116" r="${w===44?34:34+(w-44)/2}" fill="${stroke}"/>`;
const streak=(y,x0,x1,o)=>`<line x1="${x0}" y1="${y}" x2="${x1}" y2="${y}" stroke="#fff4d6" stroke-opacity="${o}" stroke-width="12" stroke-linecap="round"/>`;
let s=`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
<defs>
 <radialGradient id="bg" cx="58%" cy="42%" r="70%"><stop offset="0" stop-color="#ffcf6b"/><stop offset=".45" stop-color="#e0782a"/><stop offset="1" stop-color="#5a1d0c"/></radialGradient>
 <linearGradient id="frame" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#9aa3ad"/><stop offset=".5" stop-color="#3a3f46"/><stop offset="1" stop-color="#15181c"/></linearGradient>
 <linearGradient id="fig" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3b1606"/><stop offset="1" stop-color="#1a0802"/></linearGradient>
 <clipPath id="inner"><rect x="30" y="30" width="452" height="452" rx="40"/></clipPath>
</defs>
<rect x="6" y="6" width="500" height="500" rx="58" fill="url(#frame)"/>
<rect x="30" y="30" width="452" height="452" rx="40" fill="url(#bg)"/>
<g clip-path="url(#inner)">
 <path d="${arc(200,135,R)}" fill="none" stroke="#e5484d" stroke-opacity=".85" stroke-width="18" stroke-linecap="round"/>
 <path d="${arc(130,50,R)}" fill="none" stroke="#ffe08a" stroke-opacity=".85" stroke-width="18"/>
 <path d="${arc(45,-20,R)}" fill="none" stroke="#30c25a" stroke-width="18" stroke-linecap="round"/>
 ${streak(170,60,200,.55)}${streak(215,40,150,.4)}${streak(262,70,170,.5)}${streak(318,46,150,.35)}${streak(400,60,180,.45)}
 ${figure("#fff1c9",64)}
 ${figure("url(#fig)",44)}
 <rect x="30" y="30" width="452" height="452" rx="40" fill="none" stroke="#000" stroke-opacity=".55" stroke-width="10"/>
</g>
<rect x="30" y="30" width="452" height="452" rx="40" fill="none" stroke="#d9a441" stroke-width="5"/>
</svg>`;
fs.writeFileSync("logo.svg",s);
for(const w of [512,64]) fs.writeFileSync(`logo-${w}.png`,new Resvg(s,{fitTo:{mode:"width",value:w}}).render().asPng());
console.log("done");
