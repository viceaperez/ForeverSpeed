// Regenerates docs/logo.svg + PNGs. Needs: npm i @resvg/resvg-js
const fs=require("fs");const {Resvg}=require("@resvg/resvg-js");
const cx=256,cy=290,R=172;
const P=(a,r)=>[cx+r*Math.cos(a*Math.PI/180),cy-r*Math.sin(a*Math.PI/180)];
const arc=(a0,a1,r)=>{const[x0,y0]=P(a0,r),[x1,y1]=P(a1,r);const large=Math.abs(a0-a1)>180?1:0;return `M${x0.toFixed(1)} ${y0.toFixed(1)} A${r} ${r} 0 ${large} 1 ${x1.toFixed(1)} ${y1.toFixed(1)}`};
// colored zones: slow(red) -> even(amber) -> fast(green), sweeping 210 -> -30
const zones=[[210,135,"#e5484d"],[133,47,"#f0b429"],[45,-30,"#30c25a"]];
let s=`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
<defs>
 <radialGradient id="bg" cx="50%" cy="38%" r="75%"><stop offset="0" stop-color="#22324f"/><stop offset="1" stop-color="#0b1220"/></radialGradient>
 <linearGradient id="gold" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffd27a"/><stop offset="1" stop-color="#c9822f"/></linearGradient>
</defs>
<rect x="8" y="8" width="496" height="496" rx="92" fill="url(#bg)" stroke="url(#gold)" stroke-width="10"/>
<path d="${arc(210,-30,R)}" fill="none" stroke="#000" stroke-opacity=".35" stroke-width="44" stroke-linecap="round"/>`;
for(const[a0,a1,c]of zones)s+=`<path d="${arc(a0,a1,R)}" fill="none" stroke="${c}" stroke-width="30" stroke-linecap="${a0===210||a1===-30?'round':'butt'}"/>`;
// ticks
for(let i=0;i<=12;i++){const a=210-i*20;const big=i%3===0;const[x0,y0]=P(a,R-34),[x1,y1]=P(a,R-(big?70:52));
 s+=`<line x1="${x0.toFixed(1)}" y1="${y0.toFixed(1)}" x2="${x1.toFixed(1)}" y2="${y1.toFixed(1)}" stroke="#e8eefc" stroke-opacity="${big?0.95:0.6}" stroke-width="${big?9:5}" stroke-linecap="round"/>`;}
// needle toward fast zone (~25deg)
const na=28;const[tx,ty]=P(na,R-28),[bx1,by1]=P(na+90,15),[bx2,by2]=P(na-90,15),[tl,tly]=P(na+180,30);
s+=`<polygon points="${tx.toFixed(1)},${ty.toFixed(1)} ${bx1.toFixed(1)},${by1.toFixed(1)} ${tl.toFixed(1)},${tly.toFixed(1)} ${bx2.toFixed(1)},${by2.toFixed(1)}" fill="url(#gold)" stroke="#5a3a10" stroke-width="3" stroke-linejoin="round"/>
<circle cx="${cx}" cy="${cy}" r="30" fill="url(#gold)" stroke="#5a3a10" stroke-width="4"/>
<circle cx="${cx}" cy="${cy}" r="11" fill="#0b1220"/>`;
// speed chevrons under the hub
const chev=(x)=>`<path d="M${x} 372 l34 34 l-34 34" fill="none" stroke="#30c25a" stroke-width="16" stroke-linecap="round" stroke-linejoin="round"/>`;
s+=`<g opacity=".95">${chev(196)}${chev(240)}${chev(284)}</g>`;
s+=`</svg>`;
fs.writeFileSync("logo.svg",s);
for(const w of [512,128,64]){fs.writeFileSync(`logo-${w}.png`,new Resvg(s,{fitTo:{mode:"width",value:w}}).render().asPng());}
console.log("done");
