'use strict';
/* =====================================================================
   1+ Ballon Pop: new BALLOONS window + INDEX (Balloons / Mutations / Enemies)
   Mock-up of Gustav's design at real size. Balloon models are the game's
   own BalloonModels; enemies are ports of src/shared/Hazards/Visuals.
   ===================================================================== */
const T = THREE;
const $ = (s, r) => (r || document).querySelector(s);
function el(parent, html){ const d = document.createElement('div'); d.innerHTML = html.trim(); const n = d.firstElementChild; if(parent) parent.appendChild(n); return n; }
const fmt = n => n >= 1e9 ? (n/1e9).toFixed(n%1e9?1:0)+'B' : n >= 1e6 ? (n/1e6).toFixed(n%1e6?1:0)+'M' : n >= 1e4 ? Math.round(n/1e3)+'K' : n.toLocaleString('en-US');

/* ---------------------------------------------------------------- data */
const TIERS = ['Common','Uncommon','Rare','Epic','Legendary','Mythic','Secret'];
const ZONES = [
  {id:'Meadow Sky',  sky:['#8fd6ff','#d9f3ff'], open:true,  chest:500,        echest:300},
  {id:'Cloud Shelf', sky:['#6fb8ff','#e8f6ff'], open:true,  chest:3500,       echest:2000},
  {id:'Kite Fields', sky:['#ffc98a','#ffeccc'], open:false, chest:30000,      echest:20000},
  {id:'Windways',    sky:['#7fe6d8','#e2fff8'], open:false, chest:75000,      echest:50000},
  {id:'Thunderhead', sky:['#53507e','#9d93c4'], open:false, chest:1500000,    echest:1000000},
  {id:'Hail Belt',   sky:['#9fc7ef','#eaf6ff'], open:false, chest:14000000,   echest:8000000},
  {id:'Stratosphere',sky:['#18236a','#4a5fb8'], open:false, chest:50000000,   echest:40000000},
  {id:'Orbit',       sky:['#0b0f2e','#2b2a6a'], open:false, chest:600000000,  echest:300000000},
  {id:'Sky Boss',    sky:['#b2213c','#ff8a5a'], open:false, chest:500000000,  echest:500000000},
  {id:'Secret',      sky:['#ffb84a','#fff1b8'], open:false, chest:1000000000},
];
const B = {
 Gumball:{tier:'Common',   zone:'Meadow Sky', price:100,       max:100, earn:1,   tough:3,  flav:'Your first adventure starts here.'},
 Bubble: {tier:'Common',   zone:'Meadow Sky', price:250,       max:90,  earn:1,   tough:6,  flav:'Soft, round and hard to pop.'},
 Ember:  {tier:'Common',   zone:'Meadow Sky', price:500,       max:120, earn:1.1, tough:3,  flav:'A little campfire in the sky.'},
 Spike:  {tier:'Uncommon', zone:'Cloud Shelf',price:2000,      max:180, earn:1.3, tough:4,  flav:'Touch it and you will regret it.'},
 Popcorn:{tier:'Uncommon', zone:'Cloud Shelf',price:5000,      max:200, earn:1.3, tough:3,  flav:'Pop, pop, pop... coins!'},
 Jelly:  {tier:'Uncommon', zone:'Kite Fields',price:10000,     max:220, earn:1.4, tough:4,  flav:'Wobbly, glowing and a bit stingy.'},
 Buzz:   {tier:'Rare',     zone:'Kite Fields',price:50000,     max:350, earn:1.8, tough:5,  flav:'It never flies alone.'},
 Frost:  {tier:'Rare',     zone:'Windways',   price:150000,    max:400, earn:2,   tough:6,  flav:'Cold as the top of the sky.'},
 Volt:   {tier:'Epic',     zone:'Thunderhead',price:1000000,   max:700, earn:3,   tough:7,  flav:'Crackling with storm power.'},
 Thorn:  {tier:'Epic',     zone:'Thunderhead',price:2000000,   max:750, earn:3,   tough:12, flav:'Tough as an old rose bush.'},
 Clock:  {tier:'Epic',     zone:'Hail Belt',  price:3000000,   max:800, earn:3.2, tough:8,  flav:'Tick, tock. The sky slows down.'},
 Flame:  {tier:'Legendary',zone:'Hail Belt',  price:25000000,  max:1200,earn:5,   tough:9,  flav:'Hot air at its very hottest.'},
 Whale:  {tier:'Legendary',zone:'Stratosphere',price:60000000, max:1600,earn:5.5, tough:12, flav:'The gentle giant of the clouds.'},
 Iron:   {tier:'Legendary',zone:'Stratosphere',price:40000000, max:1300,earn:6,   tough:14, flav:'A balloon that should not float.'},
 Void:   {tier:'Mythic',   zone:'Orbit',      price:500000000, max:2500,earn:10,  tough:12, flav:'It eats whatever comes close.'},
 Sun:    {tier:'Mythic',   zone:'Orbit',      price:750000000, max:2200,earn:10,  tough:11, flav:'Too bright to look at.'},
 Crown:  {tier:'Mythic',   zone:'Sky Boss',   price:1000000000,max:2000,earn:10,  tough:13, flav:'Only for sky royalty.'},
 Cluck:  {tier:'Secret',   zone:'Secret',     price:0,         max:3000,earn:12,  tough:10, flav:'Nobody knows how it flies.'},
};
const BORDER = Object.keys(B);
const AB = {
 Gumball:{ab:'No power', key:'', desc:'Just a good, honest balloon. Every pro started here.'},
 Bubble:{ab:'Bubble Guard', key:'AUTO', desc:'3 bubbles circle you. Each one blocks a hit.'},
 Ember:{ab:'Warm Glow', key:'AUTO', desc:'Glows like a campfire: +10% coins while you fly.'},
 Spike:{ab:'Spike Burst', key:'AUTO', desc:'After a hit, spikes shoot out for 3 s and pop birds.'},
 Popcorn:{ab:'Kernel Pop', key:'AUTO', desc:'Every 25 size a kernel rains coins on players below.'},
 Jelly:{ab:'Sting Field', key:'AUTO', desc:'Tentacles slow anything coming from below.'},
 Buzz:{ab:'Bee Guard', key:'AUTO', desc:'3 bees orbit you and chase off a bird every 15 s.'},
 Frost:{ab:'Deep Freeze', key:'Q', desc:'An ice blast freezes hazards near you for 4 s.'},
 Volt:{ab:'Static Charge', key:'AUTO', desc:'Charges while you fly. Land full for +25% coins.'},
 Thorn:{ab:'Thorn Hide', key:'AUTO', desc:'Every hit does half damage. No riders.'},
 Clock:{ab:'Slow Time', key:'Q', desc:'Hazards near you move at half speed for 5 s.'},
 Flame:{ab:'Lava Rise', key:'AUTO', desc:'Lava blobs float up and burn hazards above you.'},
 Whale:{ab:'Whale Song', key:'Q', desc:'A deep song calms every bird near you for 10 s.'},
 Iron:{ab:'Iron Slam', key:'SPACE', desc:'Let out air to drop like a rock and crush hazards.'},
 Void:{ab:'Devour', key:'AUTO', desc:'Eats hazards that get too close: +5 size each.'},
 Sun:{ab:'Sun Heat', key:'AUTO', desc:'Birds that fly too close get scorched and flee.'},
 Crown:{ab:'Royal Guard', key:'AUTO', desc:'A golden shield bounces a hit straight back.'},
 Cluck:{ab:'Squawk!', key:'AUTO', desc:'Every 30 s it squawks and does a random power.'},
};
const AB_BG = {Gumball:'linear-gradient(#ffb0b0,#ff3b3b)',Bubble:'linear-gradient(#e6fbff,#7fdcff)',Ember:'linear-gradient(#ffe08a,#ff7a1f)',Spike:'linear-gradient(#ff9aa8,#e0204a)',Popcorn:'linear-gradient(#fffbe0,#ffd23a)',Jelly:'linear-gradient(#ffc8f0,#ff6fc8)',Buzz:'linear-gradient(#fff36a,#ffb300)',Frost:'linear-gradient(#e8fbff,#5ccfff)',Volt:'linear-gradient(#fff9a0,#3dc8ff)',Thorn:'linear-gradient(#b9ff8a,#3a9a2a)',Clock:'linear-gradient(#f0e6ff,#8f7bff)',Flame:'linear-gradient(#ffd36a,#ff3b1f)',Whale:'linear-gradient(#cfe8ff,#3d7bff)',Iron:'linear-gradient(#e6ebf2,#7c8696)',Void:'linear-gradient(#c58cff,#2a0f4a)',Sun:'linear-gradient(#fff7b0,#ffb020)',Crown:'linear-gradient(#fff3a0,#ffb300)',Cluck:'linear-gradient(#ffffff,#ffc94a)'};
const MUT = {
 universal:[['Chrome','Common'],['Shadow','Common'],['Stripes','Common'],['Neon','Uncommon'],['Sparkle','Uncommon'],['Steel','Uncommon'],['Gold','Rare'],['Rainbow','Rare']],
 Gumball:[['Sour','Uncommon'],['Tough','Rare']], Bubble:[['Thick','Uncommon'],['Shield','Rare']], Ember:[['Wisp','Uncommon'],['Ghost','Epic']],
 Spike:[['Sharp','Uncommon'],['Venom','Epic']], Popcorn:[['Butter','Rare'],['Chain','Epic']], Jelly:[['Glow','Uncommon'],['Sting','Legendary']],
 Buzz:[['Honey','Rare'],['Queen','Legendary']], Frost:[['Ice','Rare'],['Freeze','Epic']], Volt:[['Charged','Rare'],['Thunder','Legendary']],
 Thorn:[['Bloom','Rare'],['Mirage','Epic']], Clock:[['Slowmo','Epic'],['Rewind','Mythic']], Flame:[['Lava','Epic'],['Blast','Legendary']],
 Whale:[['Shell','Uncommon'],['Song','Legendary']], Iron:[['Anchor','Rare'],['Quake','Legendary']], Void:[['Gravity','Legendary'],['Infinity','Mythic']],
 Sun:[['Flare','Legendary'],['Nova','Mythic']], Crown:[['Royal','Mythic']], Cluck:[['Crazy','Mythic']],
};
const DANGER = {
  EASY:   {pc:'#1d6b14', pt:'#d9ffc0'},
  MEDIUM: {pc:'#8a5a00', pt:'#fff0b8'},
  HARD:   {pc:'#8a1f0b', pt:'#ffd9cc'},
  EXTREME:{pc:'#4a1596', pt:'#f1e0ff'},
  BOSS:   {pc:'#16182a', pt:'#ffd84a'},
};
const EN = [
 {id:'Sparrow', zone:'Meadow Sky', danger:'EASY',   col:['#fff2a0','#ffd21f','#d99a00'], built:true, atk:'Corkscrew Dive', tip:'It locks on, then dives. Steer sideways or dash the moment it tucks its wings.'},
 {id:'Plane',   zone:'Meadow Sky', danger:'EASY',   col:['#e8ffd0','#7cff3a','#3fb81d'], built:true, atk:'Crease Cutter', tip:'It cuts in a straight line. Rise or drop out of the line before it folds into a dart.'},
 {id:'Pinwheel',zone:'Cloud Shelf',danger:'MEDIUM', col:['#ffd0f5','#ff3fd0','#b8148f'], built:true, atk:'Saw Bloom', tip:'Its 4 blades fly out around you and snap shut in a cross. Get out of the square fast.'},
 {id:'Nimbo',   zone:'Cloud Shelf',danger:'MEDIUM', col:['#ddf6ff','#38c8ff','#0b80c8'], built:true, atk:'Pin Drizzle', tip:'It rains pins straight down. Never float right under it.'},
 {id:'Kite',    zone:'Kite Fields',danger:'MEDIUM', col:['#ffd0b0','#ff7a3a','#d84a10']},
 {id:'Gulls',   zone:'Kite Fields',danger:'HARD',   col:['#f4f7ff','#b9c6e0','#7f8eb0']},
 {id:'Gust',    zone:'Windways',   danger:'MEDIUM', col:['#e2fff8','#5ce8cf','#13a88f']},
 {id:'Zap',     zone:'Thunderhead',danger:'HARD',   col:['#fff9a0','#ffd21f','#8a6ad8']},
 {id:'Eagle',   zone:'Thunderhead',danger:'HARD',   col:['#e8d0b0','#a8743a','#5a3a18']},
 {id:'Hail',    zone:'Hail Belt',  danger:'MEDIUM', col:['#f2fbff','#9fdcff','#4aa0e0']},
 {id:'Satellite',zone:'Stratosphere',danger:'HARD', col:['#e6ebf2','#9aa6bc','#55607a']},
 {id:'Meteor',  zone:'Stratosphere',danger:'EXTREME',col:['#ffc08a','#ff6a2a','#a8280a']},
 {id:'Vacuum',  zone:'Orbit',      danger:'EXTREME',col:['#d8c8ff','#8a5cff','#3a1a9a']},
 {id:'Pin King',zone:'Sky Boss',   danger:'BOSS',   col:['#ffb0b0','#e8203c','#7a0b1e']},
];

/* demo player state (what a player 20 minutes in might have) */
const S = {
  owned:{Gumball:{lv:12}, Bubble:{lv:3}, Ember:{lv:5}, Spike:{lv:2}},
  equipped:'Spike', fav:new Set(['Spike','Gumball']),
  sel:'Spike', btab:'All', search:'',
  itab:'Balloons',
  met:{Sparrow:34, Plane:12, Pinwheel:3},
  claimed:new Set(), coins:1840,
  sound:true,
};
const isOwned = n => !!S.owned[n];

/* ---------------------------------------------------------------- icons */
const studSVG = `<svg xmlns='http://www.w3.org/2000/svg' width='28' height='28'><ellipse cx='15' cy='16.2' rx='8.6' ry='8.6' fill='black' fill-opacity='.13'/><circle cx='14' cy='14' r='8.4' fill='white' fill-opacity='.07'/><path d='M7.9 17.2A6.9 6.9 0 0 1 17.2 7.9' stroke='white' stroke-opacity='.34' stroke-width='2.3' fill='none' stroke-linecap='round'/><path d='M20 10.6A6.9 6.9 0 0 1 10.6 20' stroke='black' stroke-opacity='.17' stroke-width='2.3' fill='none' stroke-linecap='round'/></svg>`;
document.documentElement.style.setProperty('--stud', `url("data:image/svg+xml;utf8,${encodeURIComponent(studSVG)}")`);
const svgw = (vb, inner, cls) => `<svg viewBox="${vb}" class="${cls||''}" aria-hidden="true">${inner}</svg>`;
const ICO = {
  search: svgw('0 0 40 40','<circle cx="17" cy="17" r="10" fill="none" stroke="#0b1430" stroke-width="9"/><path d="M25 25l9 9" stroke="#0b1430" stroke-width="10" stroke-linecap="round"/><circle cx="17" cy="17" r="10" fill="none" stroke="#a9b8e6" stroke-width="4.5"/><path d="M25 25l9 9" stroke="#a9b8e6" stroke-width="5" stroke-linecap="round"/>'),
  x: svgw('0 0 60 60','<path d="M15 15L45 45M45 15L15 45" stroke="#0b1430" stroke-width="19" stroke-linecap="round"/><path d="M15 15L45 45M45 15L15 45" stroke="#fff" stroke-width="10" stroke-linecap="round"/>'),
  starOn: svgw('0 0 48 48','<path d="M24 4l6 13 14 1.6-10.5 9.6 3 14L24 35l-12.5 7.2 3-14L4 18.6 18 17z" fill="#ffd21f" stroke="#0b1430" stroke-width="4" stroke-linejoin="round"/><path d="M16 20.5l5-.6 3-6.8" fill="none" stroke="#fff6b0" stroke-width="3" stroke-linecap="round"/>'),
  starOff: svgw('0 0 48 48','<path d="M24 4l6 13 14 1.6-10.5 9.6 3 14L24 35l-12.5 7.2 3-14L4 18.6 18 17z" fill="rgba(10,18,48,.35)" stroke="#0b1430" stroke-width="4" stroke-linejoin="round"/><path d="M24 11l4 9 9.6 1.1-7.2 6.6 2 9.6L24 32.4l-8.4 4.9 2-9.6-7.2-6.6L20 20z" fill="none" stroke="rgba(255,255,255,.55)" stroke-width="2.5" stroke-linejoin="round"/>'),
  lock: svgw('0 0 40 40','<path d="M12 18v-5a8 8 0 0 1 16 0v5" fill="none" stroke="#0b1430" stroke-width="10"/><path d="M12 18v-5a8 8 0 0 1 16 0v5" fill="none" stroke="#fff" stroke-width="4.5"/><rect x="7" y="16" width="26" height="20" rx="4" fill="#fff" stroke="#0b1430" stroke-width="4"/><path d="M20 23v6" stroke="#0b1430" stroke-width="4" stroke-linecap="round"/>'),
  check: svgw('0 0 48 48','<circle cx="24" cy="24" r="19" fill="#5ad62a" stroke="#0b1430" stroke-width="4.5"/><path d="M14 24.5l7 7 13-14" fill="none" stroke="#0b1430" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/><path d="M14 24.5l7 7 13-14" fill="none" stroke="#fff" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>'),
  book: svgw('0 0 48 40','<path d="M24 8C18 3 9 3 3 6v28c6-3 15-3 21 2 6-5 15-5 21-2V6c-6-3-15-3-21 2z" fill="#fff" stroke="#0b1430" stroke-width="4" stroke-linejoin="round"/><path d="M24 8v28" stroke="#0b1430" stroke-width="4"/><path d="M8 12c4-1 8-1 11 1M8 18c4-1 8-1 11 1M29 13c3-2 7-2 11-1M29 19c3-2 7-2 11-1" stroke="#9fb0d8" stroke-width="2.5" fill="none" stroke-linecap="round"/>'),
  gift: svgw('0 0 48 48','<rect x="6" y="18" width="36" height="26" rx="3" fill="#ff4f6a" stroke="#0b1430" stroke-width="4"/><rect x="3" y="12" width="42" height="10" rx="3" fill="#ff7a8a" stroke="#0b1430" stroke-width="4"/><path d="M24 12v32" stroke="#0b1430" stroke-width="10"/><path d="M24 12v32" stroke="#ffd21f" stroke-width="5"/><path d="M24 12c-4-9-14-9-12-2 1 3 7 3 12 2zM24 12c4-9 14-9 12-2-1 3-7 3-12 2z" fill="#ffd21f" stroke="#0b1430" stroke-width="3.5" stroke-linejoin="round"/>'),
  balloonTab: svgw('0 0 48 48','<path d="M24 34c-9 0-15-8-15-16a15 15 0 0 1 30 0c0 8-6 16-15 16z" fill="#ff4a4a" stroke="#0b1430" stroke-width="4"/><path d="M21 34h6l-3 4z" fill="#ff4a4a" stroke="#0b1430" stroke-width="3" stroke-linejoin="round"/><path d="M24 38c-3 3 3 4 0 8" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round"/><path d="M16 14a9 9 0 0 1 6-6" stroke="#fff" stroke-width="3.5" stroke-linecap="round" fill="none"/>'),
  mutTab: svgw('0 0 48 48','<path d="M24 3l5 14 14 5-14 5-5 14-5-14-14-5 14-5z" fill="#c78cff" stroke="#0b1430" stroke-width="4" stroke-linejoin="round"/><path d="M38 31l2 5 5 2-5 2-2 5-2-5-5-2 5-2z" fill="#ffd84a" stroke="#0b1430" stroke-width="3" stroke-linejoin="round"/><path d="M19 17l5-5" stroke="#fff" stroke-width="3" stroke-linecap="round"/>'),
  enTab: svgw('0 0 48 48','<path d="M8 22c0-9 7-15 15-15 9 0 16 6 16 14l7 3-7 3c-1 8-8 13-16 13S8 32 8 22z" fill="#ffd21f" stroke="#0b1430" stroke-width="4" stroke-linejoin="round"/><path d="M14 26c4 6 13 6 18 0" fill="#d99a00" stroke="#0b1430" stroke-width="3.5" stroke-linejoin="round"/><circle cx="29" cy="17" r="3.5" fill="#0b1430"/><path d="M27 9l6 4" stroke="#0b1430" stroke-width="4" stroke-linecap="round"/>'),
  coin: svgw('0 0 40 40','<circle cx="20" cy="21" r="16" fill="#c9780a" stroke="#0b1430" stroke-width="3.5"/><circle cx="20" cy="18.5" r="15" fill="#ffd21f" stroke="#0b1430" stroke-width="3.5"/><circle cx="20" cy="18.5" r="9.5" fill="none" stroke="#e09a0a" stroke-width="3"/><path d="M12 12a10 10 0 0 1 6-4" stroke="#fff6b0" stroke-width="3" stroke-linecap="round"/>'),
  skull: svgw('0 0 40 40','<path d="M20 4C11 4 5 10 5 18c0 5 3 8 6 10v6h18v-6c3-2 6-5 6-10 0-8-6-14-15-14z" fill="#fff" stroke="#0b1430" stroke-width="3.5" stroke-linejoin="round"/><circle cx="14" cy="18" r="4" fill="#0b1430"/><circle cx="26" cy="18" r="4" fill="#0b1430"/><path d="M17 34v-4M23 34v-4" stroke="#0b1430" stroke-width="3"/>'),
};
const ICO_DODGE = '<span style="display:inline-block;width:14px;height:14px;vertical-align:-2px"><svg viewBox="0 0 20 20"><path d="M3 13c4 0 7-3 9-8l5 3c-2 6-7 9-14 9z" fill="#fff" stroke="#0b1430" stroke-width="2.5" stroke-linejoin="round"/></svg></span>';
const ABI = {
 Gumball:'<circle cx="24" cy="21" r="14"/><path d="M21 35h6l-3 5z"/>',
 Bubble:'<circle cx="20" cy="26" r="13"/><circle cx="35" cy="13" r="7"/><circle cx="37" cy="33" r="5"/><path d="M13 21a8 8 0 0 1 7-6" fill="none" stroke-width="3.5"/>',
 Ember:'<path d="M24 5c3 9 13 13 13 25a13 13 0 0 1-26 0c0-7 5-10 6-17 3 4 4 6 4 9 3-4 4-9 3-17z"/>',
 Spike:'<path d="M24 3l5 12 12-5-5 12 12 5-12 4 5 12-12-5-5 12-4-12-12 5 5-12-12-4 12-5-5-12 12 5z"/>',
 Popcorn:'<path d="M12 22c-6-1-6-10 1-10 0-7 9-8 11-3 3-6 12-4 11 3 7 0 7 9 1 10z"/><path d="M12 22h24l-4 22H16z"/>',
 Jelly:'<path d="M8 22a16 14 0 0 1 32 0z"/><path d="M12 22c0 8-4 10-1 18M20 22c0 8 3 10 0 19M28 22c0 8-3 10 0 19M36 22c0 8 4 10 1 18" fill="none" stroke-width="4"/>',
 Buzz:'<ellipse cx="24" cy="28" rx="11" ry="13"/><path d="M14 23h20M13 31h22" fill="none" stroke-width="4"/><ellipse cx="13" cy="12" rx="7" ry="5"/><ellipse cx="35" cy="12" rx="7" ry="5"/>',
 Frost:'<path d="M24 4v40M6.7 14l34.6 20M6.7 34l34.6-20M18 8l6 6 6-6M18 40l6-6 6 6" fill="none" stroke-width="5"/>',
 Volt:'<path d="M28 3L9 27h12l-4 18 22-26H27z"/>',
 Thorn:'<path d="M24 4l8 10-4 1 7 9-4 1 7 11H10l7-11-4-1 7-9-4-1z"/><rect x="21" y="36" width="6" height="8"/>',
 Clock:'<circle cx="24" cy="25" r="18"/><path d="M24 14v12l8 5" fill="none" stroke-width="4"/><rect x="19" y="2" width="10" height="5" rx="2"/>',
 Flame:'<circle cx="16" cy="32" r="9"/><circle cx="31" cy="20" r="7"/><circle cx="24" cy="8" r="5"/>',
 Whale:'<path d="M6 28c0-9 9-14 19-14s15 6 15 13c3-3 5-5 6-9 1 6-1 11-6 13-3 5-9 8-17 8C12 39 6 35 6 28z"/><path d="M14 8c2-3 6-3 7 0" fill="none" stroke-width="3.5"/>',
 Iron:'<path d="M10 6h28l-4 12H14z"/><path d="M24 18v12M14 30l10 12 10-12z"/>',
 Void:'<circle cx="24" cy="24" r="19"/><path d="M24 10a14 14 0 0 1 13 15M38 24a14 14 0 0 1-15 13M24 38a14 14 0 0 1-13-15M10 24a14 14 0 0 1 15-13" fill="none" stroke-width="3.5"/>',
 Sun:'<circle cx="24" cy="24" r="10"/><path d="M24 3v7M24 38v7M3 24h7M38 24h7M9 9l5 5M34 34l5 5M39 9l-5 5M14 34l-5 5" fill="none" stroke-width="4.5"/>',
 Crown:'<path d="M5 15l9 8 10-14 10 14 9-8-4 24H9z"/><rect x="9" y="40" width="30" height="5" rx="2"/>',
 Cluck:'<path d="M14 40c-7-5-7-17 1-23 2-9 13-11 17-4l9 2-7 4c4 4 5 13 0 19z"/><path d="M23 7c1-4 6-4 6-1 2-2 6 0 3 4" />',
};
const abIcon = id => '<svg viewBox="0 0 48 48"><g fill="#fff" stroke="#0b1430" stroke-width="3" stroke-linejoin="round" stroke-linecap="round">'+ABI[id]+'</g></svg>';

/* ---------------------------------------------------------------- UI bits */
function btn(parent, {cls='b-green', label='', icon='', w=null, h=null, fs=null, r=null, onClick=null, style=''}){
  const n = el(parent, `<div class="btn ${cls}" style="${w?`width:${w}px;`:''}${h?`height:${h}px;`:''}${fs?`--fs:${fs}px;`:''}${r?`--r:${r}px;`:''}${style}">
     <div class="lip"></div><div class="face">${icon}<span class="lbl t">${label}</span></div></div>`);
  if(onClick) n.addEventListener('click', e => { e.stopPropagation(); onClick(e); });
  n.setLabel = (lab, ic) => { n.querySelector('.face').innerHTML = (ic||'') + `<span class="lbl t">${lab}</span>`; };
  return n;
}
function setBtnCls(b, cls){ b.className = 'btn ' + cls + (b.classList.contains('cbtn')?' cbtn':'') + (b.classList.contains('dbtn')?' dbtn':''); }
const iconLock = '<span style="width:30px;height:30px;display:inline-block">'+ICO.lock+'</span>';
function toast(msg, err, at){
  const n = el($('#ui'), `<div class="toast ${err?'err':''}"><div class="t">${msg}</div></div>`);
  const w = [WB, WI].find(o => o && !o.classList.contains('hide'));
  n.style.left = (at ? at.x : UI.W/2)+'px';
  n.style.top = (at ? at.y : w ? (parseFloat(w.style.top) + w.H - 190) : UI.H*.7)+'px';
  setTimeout(() => n.remove(), 2300);
}

/* ---------------------------------------------------------------- sound (synth stand-ins for SoundConfig) */
let AC = null;
function ac(){ if(!AC){ try{ AC = new (window.AudioContext||window.webkitAudioContext)(); }catch(e){} } return AC; }
function tone(f, t0, dur, {type='sine', vol=.2, f2=null, at=.005}={}){
  const a = ac(); if(!a || !S.sound) return;
  const o = a.createOscillator(), g = a.createGain(); o.type = type;
  const t = a.currentTime + t0; o.frequency.setValueAtTime(f, t); if(f2) o.frequency.exponentialRampToValueAtTime(f2, t+dur);
  g.gain.setValueAtTime(0, t); g.gain.linearRampToValueAtTime(vol, t+at); g.gain.exponentialRampToValueAtTime(.0008, t+dur);
  o.connect(g).connect(a.destination); o.start(t); o.stop(t+dur+.05);
}
function noise(t0, dur, {vol=.15, hp=800, lp=6000}={}){
  const a = ac(); if(!a || !S.sound) return;
  const len = Math.max(1, Math.floor(a.sampleRate*dur)), buf = a.createBuffer(1, len, a.sampleRate), d = buf.getChannelData(0);
  for(let i=0;i<len;i++) d[i] = (Math.random()*2-1)*(1-i/len);
  const s = a.createBufferSource(); s.buffer = buf; const h = a.createBiquadFilter(); h.type='highpass'; h.frequency.value = hp; const l = a.createBiquadFilter(); l.type='lowpass'; l.frequency.value = lp;
  const g = a.createGain(); g.gain.value = vol; s.connect(h).connect(l).connect(g).connect(a.destination); s.start(a.currentTime+t0);
}
const SFX = {
  click(){ tone(900,0,.06,{type:'triangle',vol:.18,f2:1300}); },
  tab(){ tone(620,0,.07,{type:'triangle',vol:.16,f2:880}); noise(0,.05,{vol:.05,hp:3000}); },
  open(){ noise(0,.22,{vol:.12,hp:600,lp:3000}); tone(330,0,.22,{type:'triangle',vol:.14,f2:880}); tone(1320,.18,.12,{vol:.12}); },
  close(){ noise(0,.16,{vol:.1,hp:500,lp:2500}); tone(700,0,.18,{type:'triangle',vol:.12,f2:300}); },
  equip(){ [784,1047,1319].forEach((f,i)=>tone(f,i*.06,.25,{type:'triangle',vol:.16})); tone(2093,.2,.3,{vol:.06}); },
  fav(){ tone(500,0,.1,{type:'sine',vol:.2,f2:1400}); tone(1800,.07,.12,{vol:.07}); },
  unfav(){ tone(900,0,.12,{type:'sine',vol:.15,f2:400}); },
  err(){ tone(180,0,.12,{type:'square',vol:.07}); tone(150,.13,.16,{type:'square',vol:.07}); },
  coin(i){ tone(1568+((i||0)%4)*120,0,.12,{type:'triangle',vol:.07}); },
  chest(){ noise(0,.25,{vol:.12,hp:200,lp:1500}); tone(140,0,.25,{type:'sawtooth',vol:.05,f2:90}); [523,659,784,1047,1319].forEach((f,i)=>tone(f,.25+i*.07,.4,{type:'triangle',vol:.15})); },
  hover(){ tone(1400,0,.03,{type:'sine',vol:.03}); },
};

/* ================================================================== 3D */
const R = new T.WebGLRenderer({antialias:true, alpha:true, preserveDrawingBuffer:false});
const DPR = Math.min(2, window.devicePixelRatio || 1);
R.setPixelRatio(1);
R.setSize(1024, 1024, false);
R.setClearColor(0x000000, 0);
const RH = 1024;

const matCache = new Map();
function mat(color, o){
  o = o || {};
  const k = color + '|' + JSON.stringify(o);
  if(matCache.has(k)) return matCache.get(k);
  const p = {color, roughness:o.r != null ? o.r : .55, metalness:o.m || 0};
  if(o.op != null){ p.transparent = true; p.opacity = o.op; p.depthWrite = o.op > .7; }
  if(o.em){ p.emissive = new T.Color(o.emc != null ? o.emc : color); p.emissiveIntensity = o.em; }
  const m = new T.MeshStandardMaterial(p); matCache.set(k, m); return m;
}
const geo = {box:new T.BoxGeometry(1,1,1), nub:new T.CylinderGeometry(.5,.5,1,12), cyl:new T.CylinderGeometry(1,1,1,14), sph:new T.SphereGeometry(1,16,12), coin:new T.CylinderGeometry(1,1,.32,16)};
const wedgeGeo = (function(){
  const v = [[-.5,-.5,-.5],[.5,-.5,-.5],[-.5,-.5,.5],[.5,-.5,.5],[-.5,.5,.5],[.5,.5,.5]];
  const faces = [[0,2,3,1],[2,4,5,3],[0,1,5,4],[0,4,2],[1,3,5]];
  const pos = [], ctr = new T.Vector3(0,-1/6,1/6);
  faces.forEach(f => { const tris = f.length === 4 ? [[f[0],f[1],f[2]],[f[0],f[2],f[3]]] : [f];
    tris.forEach(t => { const a = new T.Vector3().fromArray(v[t[0]]), b = new T.Vector3().fromArray(v[t[1]]), c = new T.Vector3().fromArray(v[t[2]]);
      const n = new T.Vector3().subVectors(b,a).cross(new T.Vector3().subVectors(c,a)); const mid = a.clone().add(b).add(c).multiplyScalar(1/3).sub(ctr);
      if(n.dot(mid) < 0) pos.push(a.x,a.y,a.z,c.x,c.y,c.z,b.x,b.y,b.z); else pos.push(a.x,a.y,a.z,b.x,b.y,b.z,c.x,c.y,c.z); }); });
  const g = new T.BufferGeometry(); g.setAttribute('position', new T.Float32BufferAttribute(pos,3)); g.computeVertexNormals(); return g;
})();
const SIL = new T.MeshBasicMaterial({color:0x0a0f26});

/* ----- voxel builder with studs (stud surface on exposed tops) ----- */
function Vox(){
  const g = new T.Group(); const boxes = [];
  g.box = (x,y,z,w,h,d,c,o) => { o = o || {};
    const m = new T.Mesh(o.wedge ? wedgeGeo : o.ball ? geo.sph : o.cyl ? geo.cyl : geo.box, o.m || mat(c, o));
    if(o.ball || o.cyl) m.scale.set(w/2,h/(o.cyl?1:2),d/2); else m.scale.set(w,h,d);
    m.position.set(x,y,z); if(o.rot) m.rotation.set(o.rot[0],o.rot[1],o.rot[2]); g.add(m);
    if(o.studs !== false && !o.wedge && !o.ball && !o.cyl && !o.rot && !o.em && o.op == null) boxes.push([x-w/2,x+w/2,y-h/2,y+h/2,z-d/2,z+d/2,c]);
    return m; };
  g.studs = (sz) => { sz = sz || 1;
    const by = new Map();
    boxes.forEach(b => { for(let x=b[0]+sz/2; x<b[1]-1e-3; x+=sz) for(let z=b[4]+sz/2; z<b[5]-1e-3; z+=sz){
      const yt = b[3]; if(boxes.some(o => o !== b && x>o[0] && x<o[1] && z>o[4] && z<o[5] && yt+.2>o[2] && yt+.2<o[3])) continue;
      if(!by.has(b[6])) by.set(b[6], []); by.get(b[6]).push([x,yt,z]); } });
    by.forEach((pts, c) => { const im = new T.InstancedMesh(geo.nub, mat(c), pts.length), d = new T.Object3D();
      pts.forEach((p,i) => { d.position.set(p[0], p[1]+.1*sz, p[2]); d.scale.set(.62*sz,.2*sz,.62*sz); d.updateMatrix(); im.setMatrixAt(i, d.matrix); }); g.add(im); });
    return g; };
  return g;
}

/* ----- the game's balloon models ----- */
function balloonMat(pal){
  const hex = parseInt(pal[0],16), m = pal[1], tr = pal[2] || 0, o = {};
  if(m === 'N'){ o.em = .9; o.r = .4; } else if(m === 'G'){ o.r = .08; o.op = Math.max(.25, 1-tr-.12); } else if(m === 'S'){ o.r = .32; }
  if(m !== 'G' && tr > 0) o.op = 1-tr;
  return mat(hex, o);
}
function buildBalloon(name, palSwap, o_str){
  const BM = DATA.balloons[name]; const g = new T.Group(); const kn = BM.knot; const boxes = [];
  const palOf = k => palSwap && palSwap[k] ? palSwap[k] : BM.pal[k];
  BM.parts.forEach(p => {
    const shape = p[0], key = p[1], sx=p[2], sy=p[3], sz=p[4], x=p[5]-kn[0], y=p[6]-kn[1], z=p[7]-kn[2];
    const m = new T.Mesh(shape === 'W' ? wedgeGeo : geo.box, balloonMat(palOf(key)));
    const M = new T.Matrix4();
    if(p.length > 8){ const r = p.slice(8); M.set(r[0],r[1],r[2],x, r[3],r[4],r[5],y, r[6],r[7],r[8],z, 0,0,0,1); }
    else { M.makeTranslation(x,y,z); boxes.push([x-sx/2,x+sx/2,y-sy/2,y+sy/2,z-sz/2,z+sz/2, palOf(key)]); }
    M.multiply(new T.Matrix4().makeScale(sx,sy,sz)); m.matrixAutoUpdate = false; m.matrix.copy(M); g.add(m);
  });
  const by = new Map();
  boxes.forEach(b => { if(b[6][1] !== 'P' || (b[6][2]||0) > 0) return;
    for(let x=b[0]+.5; x<b[1]; x+=1) for(let z=b[4]+.5; z<b[5]; z+=1){ const yt = b[3];
      if(!boxes.some(o => o !== b && x>o[0] && x<o[1] && z>o[4] && z<o[5] && yt+.25>o[2] && yt+.25<o[3])){ const k = b[6][0]; if(!by.has(k)) by.set(k, []); by.get(k).push([x,yt,z]); } } });
  by.forEach((pts, hex) => { const im = new T.InstancedMesh(geo.nub, mat(parseInt(hex,16)), pts.length), d = new T.Object3D();
    pts.forEach((p,i) => { d.position.set(p[0],p[1]+.1,p[2]); d.scale.set(.6,.2,.6); d.updateMatrix(); im.setMatrixAt(i, d.matrix); }); g.add(im); });
  if(BM.light){ const L = new T.PointLight(parseInt(BM.light[0],16), BM.light[1]*.7, BM.light[2]*2); L.position.set(0,4,4); g.add(L); }
  // curly string under the knot (like the cards in Gustav's picture)
  const sm = mat(0xffffff, {r:.6}); const pts = [];
  for(let i=0;i<=14;i++){ const u = i/14; pts.push(new T.Vector3(Math.sin(u*Math.PI*2.4)*.5*(.4+u), -u*(o_str||3.4) - .2, Math.cos(u*Math.PI*2.4)*.3)); }
  const curve = new T.CatmullRomCurve3(pts); const tube = new T.Mesh(new T.TubeGeometry(curve, 40, .13, 6, false), sm); g.add(tube);
  return g;
}
function fitInfo(obj){ const bb = new T.Box3().setFromObject(obj); return {c:bb.getCenter(new T.Vector3()), s:bb.getSize(new T.Vector3())}; }

/* ----- enemies: ports of src/shared/Hazards/Visuals/*.lua (rest pose + idle animation) ----- */
const M4 = (x,y,z) => new T.Matrix4().makeTranslation(x||0,y||0,z||0);
const AN = (x,y,z) => new T.Matrix4().makeRotationFromEuler(new T.Euler(x||0,y||0,z||0,'XYZ'));
const mul = (...a) => a.reduce((p,c) => p.multiply(c), new T.Matrix4());
const rad = d => d*Math.PI/180;
const hx = h => parseInt(h.replace('#',''),16);
function rigPart(spec){
  // spec: {size:[x,y,z], color, wedge, m:'P'|'S'|'N', studs}
  const g = new T.Group(); g.matrixAutoUpdate = false;
  const o = spec.m === 'N' ? {em:1, r:.4} : spec.m === 'S' ? {r:.35} : {};
  const mesh = new T.Mesh(spec.wedge ? wedgeGeo : geo.box, mat(spec.color, o)); mesh.scale.set(spec.size[0],spec.size[1],spec.size[2]); g.add(mesh);
  const studs = spec.studs != null ? spec.studs : (spec.m || 'P') === 'P' && !spec.wedge;
  if(studs && spec.size[0] >= .9 && spec.size[2] >= .9){
    const nx = Math.max(1, Math.round(spec.size[0])), nz = Math.max(1, Math.round(spec.size[2]));
    const im = new T.InstancedMesh(geo.nub, mat(spec.color), nx*nz), d = new T.Object3D(); let i = 0;
    for(let a=0;a<nx;a++) for(let b=0;b<nz;b++){ d.position.set((a+.5)*spec.size[0]/nx - spec.size[0]/2, spec.size[1]/2+.08, (b+.5)*spec.size[2]/nz - spec.size[2]/2); d.scale.set(.55,.16,.55); d.updateMatrix(); im.setMatrixAt(i++, d.matrix); }
    g.add(im);
  }
  return g;
}
function makeRig(def){
  const g = new T.Group(); const parts = {};
  def.parts.forEach(p => { const n = rigPart(p); n.userData.off = p.off || new T.Matrix4(); parts[p.key] = n; g.add(n); });
  g.userData.anim = (t, dt) => def.anim(t, dt, parts);
  g.userData.anim(0, 0);
  return g;
}
const ENEMY = {
  Sparrow(){ const BR=0xc8742a, DK=0x8a4a18, CR=0xf2d7a6, INK=0x141414, C=0xffd21f, DEEP=0xb36b00;
    const parts = [
      {key:'Body', size:[2.6,2.4,3.4], color:BR, off:M4(0,0,0)}, {key:'Belly', size:[2.2,1,2.6], color:CR, off:M4(0,-.8,-.2)},
      {key:'Head', size:[2.2,2.2,2.2], color:BR, off:M4(0,.9,-2.3)}, {key:'Cap', size:[2.3,.5,2.3], color:DK, off:M4(0,2.05,-2.3)},
      {key:'Beak', size:[.9,.8,1.3], color:C, wedge:true, studs:false, off:M4(0,.75,-4.05)},
      {key:'EyeL', size:[.12,.45,.45], color:INK, studs:false, off:M4(-1.12,1.15,-2.9)}, {key:'EyeR', size:[.12,.45,.45], color:INK, studs:false, off:M4(1.12,1.15,-2.9)},
      {key:'Tail', size:[1.8,.3,1.8], color:DK, off:mul(M4(0,.5,2.4), AN(rad(20),0,0))},
      {key:'FootL', size:[.3,.7,.3], color:DEEP, studs:false, off:M4(-.6,-1.5,.2)}, {key:'FootR', size:[.3,.7,.3], color:DEEP, studs:false, off:M4(.6,-1.5,.2)},
      {key:'WingL', size:[2.6,.3,1.9], color:DK}, {key:'WingR', size:[2.6,.3,1.9], color:DK}];
    return makeRig({parts, anim(t, dt, P){ const bob = Math.sin(t*4.2); const base = mul(M4(0,bob*.35,0), AN(bob*.05,0,0));
      for(const k in P){ if(k.startsWith('Wing')) continue; P[k].matrix.copy(mul(base.clone(), P[k].userData.off)); }
      const flap = Math.sin(t*20)*.75;
      P.WingL.matrix.copy(mul(base.clone(), M4(-1.2,.6,-.3), AN(0,0,-flap), M4(-1.3,0,0)));
      P.WingR.matrix.copy(mul(base.clone(), M4(1.2,.6,-.3), AN(0,0,flap), M4(1.3,0,0))); }}); },
  Plane(){ const W=0xffffff, F=0xb8c2d4, C=0x7cff3a;
    const parts = [
      {key:'WingL', size:[.08,2.4,6.4], color:W, wedge:true, m:'S', off:mul(M4(-1.2,0,0), AN(0,0,rad(90)))},
      {key:'WingR', size:[.08,2.4,6.4], color:W, wedge:true, m:'S', off:mul(M4(1.2,0,0), AN(0,0,rad(-90)))},
      {key:'KeelL', size:[.08,1,6.4], color:F, wedge:true, m:'S', off:mul(M4(-.06,-.5,0), AN(0,0,Math.PI))},
      {key:'KeelR', size:[.08,1,6.4], color:F, wedge:true, m:'S', off:mul(M4(.06,-.5,0), AN(0,0,Math.PI))},
      {key:'Crease', size:[.14,.14,6.4], color:C, m:'N', off:M4(0,.05,0)}];
    return makeRig({parts, anim(t, dt, P){ const base = mul(M4(0,Math.sin(t*1.8)*.4,0), AN(Math.sin(t*1.3)*.06,0,Math.sin(t*1.1)*.2));
      for(const k in P) P[k].matrix.copy(mul(base.clone(), P[k].userData.off)); }}); },
  Pinwheel(){ const Rr=3.2, H=2.6, C=0xff3fd0, VC=[0xff3fd0,0xffd0f5,0xc21e9e,0xff8ae6];
    const EL = Math.sqrt(Rr*Rr+H*H);
    const parts = [
      {key:'Stick', size:[.5,6,.5], color:0x8a5a2e, off:M4(0,-3.7,.3)}, {key:'Hub', size:[1.8,1.8,.9], color:0xffffff, off:M4(0,0,-.2)},
      {key:'HubTop', size:[1.1,.35,.6], color:0xf1e6f0, off:M4(0,1.07,-.2)},
      {key:'EyeL', size:[.45,.28,.1], color:0x2a0a24, studs:false, off:mul(M4(-.4,.22,-.7), AN(0,0,rad(-15)))},
      {key:'EyeR', size:[.45,.28,.1], color:0x2a0a24, studs:false, off:mul(M4(.4,.22,-.7), AN(0,0,rad(15)))},
      {key:'Mouth', size:[.9,.2,.1], color:C, m:'N', off:M4(0,-.35,-.7)}];
    for(let i=0;i<4;i++){ parts.push({key:'Vane'+i, size:[.18,H,Rr], color:VC[i], wedge:true, m:'S'}); parts.push({key:'Edge'+i, size:[EL,.12,.12], color:C, m:'N'}); }
    const VO = mul(M4(Rr/2,H/2,-.55), AN(0,Math.PI/2,0)), EO = mul(M4(Rr/2,H/2,-.66), AN(0,0,Math.atan2(H,Rr)));
    let spin = 0;
    return makeRig({parts, anim(t, dt, P){ spin += 4*(dt||0); const base = mul(M4(0,Math.sin(t*2)*.35,0), AN(0,0,Math.sin(t*1.7)*.08));
      ['Stick','Hub','HubTop','EyeL','EyeR','Mouth'].forEach(k => P[k].matrix.copy(mul(base.clone(), P[k].userData.off)));
      for(let i=0;i<4;i++){ const sp = mul(base.clone(), AN(0,0,spin+i*Math.PI/2)); P['Vane'+i].matrix.copy(mul(sp.clone(), VO)); P['Edge'+i].matrix.copy(mul(sp.clone(), EO)); } }}); },
  Nimbo(){ const W=0xf7faff, SI=0xeef3ff, SH=0xc3cfe8, INK=0x1a2440, C=0x38c8ff, HOT=0xddf6ff;
    const parts = [
      {key:'Core', size:[8,3.2,5], color:W, off:M4(0,0,0)}, {key:'PuffL', size:[3.6,2.6,4], color:W, off:M4(-1.7,2.3,.2)},
      {key:'PuffR', size:[4.2,3,4.2], color:W, off:M4(1.6,2.6,0)}, {key:'SideL', size:[2.4,2.6,3.6], color:SI, off:M4(-4.9,-.2,.1)},
      {key:'SideR', size:[2.6,2.8,3.8], color:SI, off:M4(5,-.1,0)}, {key:'Base', size:[8,.6,5], color:SH, studs:false, off:M4(0,-1.9,0)},
      {key:'EyeL', size:[.9,.65,.12], color:C, m:'N', off:M4(-1.2,-.2,-2.56)}, {key:'EyeR', size:[.9,.65,.12], color:C, m:'N', off:M4(1.2,-.2,-2.56)},
      {key:'BrowL', size:[1.3,.3,.12], color:INK, studs:false, off:mul(M4(-1.2,.5,-2.56), AN(0,0,rad(-18)))},
      {key:'BrowR', size:[1.3,.3,.12], color:INK, studs:false, off:mul(M4(1.2,.5,-2.56), AN(0,0,rad(18)))},
      {key:'Mouth', size:[1.3,.35,.12], color:INK, studs:false, off:M4(0,-1.05,-2.56)}];
    [mul(M4(-2,3.4,0), AN(0,0,rad(20))), mul(M4(.8,4.2,0), AN(0,0,rad(-8))), mul(M4(3.2,3.6,0), AN(0,0,rad(-25)))].forEach((pin,i) => {
      parts.push({key:'Pin'+i, size:[.16,2,.16], color:HOT, m:'S', studs:false, off:mul(pin.clone(), M4(0,.5,0))});
      parts.push({key:'PinHead'+i, size:[.5,.5,.5], color:C, m:'N', off:mul(pin.clone(), M4(0,1.6,0))}); });
    return makeRig({parts, anim(t, dt, P){ const s = 1 + Math.sin(t*2.1)*.025; const base = mul(M4(0,Math.sin(t*1.6)*.5,0), AN(0,0,Math.sin(t*1.2)*.04), new T.Matrix4().makeScale(s,s,s));
      for(const k in P) P[k].matrix.copy(mul(base.clone(), P[k].userData.off)); }}); },
};
// silhouettes for enemies that are not in the game yet (shape only, drawn black)
const FUTURE = {
  Kite(){ const v = Vox(); v.box(0,0,0,6,6,.4,0,{rot:[0,0,Math.PI/4]}); for(let i=0;i<4;i++){ const a=i*Math.PI/2; v.box(Math.cos(a)*4.6,Math.sin(a)*4.6,0,1.4,1.4,.4,0,{rot:[0,0,Math.PI/4]}); }
    for(let i=0;i<4;i++) v.box(.6*Math.sin(i), -5-i*1.6, 0, 1.2, .5, .3, 0, {rot:[0,0,(i%2?1:-1)*.5]}); return v; },
  Gulls(){ const v = Vox(); [[0,1.6,0,1],[-4.2,-.8,0,.8],[4.2,-.6,0,.85]].forEach(b => { const s=b[3]; v.box(b[0],b[1],b[2],2*s,1.3*s,1.3*s,0); v.box(b[0]-1.7*s,b[1]+.6*s,b[2],2.4*s,.3*s,1*s,0,{rot:[0,0,-.45]}); v.box(b[0]+1.7*s,b[1]+.6*s,b[2],2.4*s,.3*s,1*s,0,{rot:[0,0,.45]}); v.box(b[0]+1.3*s,b[1]+.2*s,b[2],.9*s,.5*s,.5*s,0); }); return v; },
  Gust(){ const v = Vox(); v.box(-2.4,0,0,5,4,3.4,0); v.box(-3.4,2.4,0,3,2,2.6,0); v.box(-1,2.6,0,3,2.4,2.6,0); v.box(-5,-.4,0,2,2.8,2.6,0); v.box(.6,-.2,0,1.6,1.6,1.6,0);
    [[2.2,1.2,4.4],[2.6,-.4,6],[2.2,-2,4.4]].forEach(b => { v.box(b[0]+b[2]/2,b[1],0,b[2],.6,.6,0); v.box(b[0]+b[2]+.3,b[1]+.5,0,.6,1.6,.6,0); }); return v; },
  Zap(){ const v = Vox(); v.box(0,2,0,8,3,4,0); v.box(-2,3.8,0,3.6,2.4,3,0); v.box(1.8,4.2,0,4,2.8,3,0); v.box(-.6,-1,0,1.2,3,.8,0,{rot:[0,0,.35]}); v.box(.4,-3,0,1.2,2.6,.8,0,{rot:[0,0,-.4]}); v.box(-.4,-5,0,1,2.6,.8,0,{rot:[0,0,.35]}); return v; },
  Eagle(){ const v = Vox(); v.box(0,0,0,2.6,2.4,4,0); v.box(0,1.2,-2.6,2,2,2,0); v.box(0,.9,-4,1,.9,1.2,0); v.box(-3.6,.6,0,5,.4,2.4,0,{rot:[0,0,.25]}); v.box(3.6,.6,0,5,.4,2.4,0,{rot:[0,0,-.25]}); v.box(-6.6,1.6,.2,2,.3,1.6,0,{rot:[0,0,.5]}); v.box(6.6,1.6,.2,2,.3,1.6,0,{rot:[0,0,-.5]}); v.box(0,.2,2.8,2.2,.3,2,0); return v; },
  Hail(){ const v = Vox(); [[0,0,0,3],[2.6,1.8,.4,1.8],[-2.4,1.4,-.2,2],[1.4,-2.4,0,1.6],[-1.8,-2.2,.3,1.2],[3.2,-1,0,1],[-3.4,-.4,0,1]].forEach(b => v.box(b[0],b[1],b[2],b[3],b[3],b[3],0,{rot:[.6,.7,.3]})); return v; },
  Satellite(){ const v = Vox(); v.box(0,0,0,2.4,2.4,2.4,0); v.box(-4.4,0,0,5,.3,2.4,0); v.box(4.4,0,0,5,.3,2.4,0); v.box(0,2,0,.3,1.6,.3,0); v.box(0,2.9,0,1.8,.4,1.8,0,{cyl:true}); return v; },
  Meteor(){ const v = Vox(); v.box(0,0,0,3.6,3.2,3.2,0,{rot:[.3,.4,.2]}); v.box(1.4,1.2,.4,2,2,2,0,{rot:[.6,.2,.4]}); v.box(-1.2,-1,0,2,2,2,0,{rot:[.2,.8,.1]}); [[3,2.6,1.2],[4.6,3.8,.8],[6,4.8,.5]].forEach(b => v.box(b[0],b[1],0,b[2],b[2],b[2],0,{rot:[.4,.4,.4]})); return v; },
  Vacuum(){ const v = Vox(); v.box(0,0,0,3,3,3,0,{ball:true}); for(let i=0;i<14;i++){ const a=i/14*Math.PI*2; v.box(Math.cos(a)*4.4,Math.sin(a)*1.3,Math.sin(a)*4.4*.2,1.4,.5,.9,0,{rot:[0,-a,0]}); } return v; },
  'Pin King'(){ const v = Vox(); [[0,2,7,5],[0,4.6,8,3],[0,6.8,7,2],[0,8.4,5,1.4],[0,-.4,5,1.6],[0,-1.8,3,1.2]].forEach(b => v.box(b[0],b[1],0,b[2],b[3],b[2]*.8,0));
    for(let i=0;i<8;i++){ const a=i/8*Math.PI*2; v.box(Math.cos(a)*4.4,4,Math.sin(a)*3.4,1.6,.5,.5,0,{rot:[0,-a,0]}); }
    [-1.6,0,1.6].forEach((x,i) => v.box(x,10+(i===1?.6:0),0,.8,1.6+(i===1?.6:0),.8,0)); v.box(0,9.3,0,4.2,.7,1.2,0);
    v.box(0,-5.6,0,3,2,3,0); [-1.2,1.2].forEach(x => v.box(x,-3.6,0,.2,2.6,.2,0)); return v; },
};

/* ----- chest (zone reward) ----- */
function buildChest(){
  const g = new T.Group();
  const v = Vox(); g.add(v);
  const WD = 0x9a5626, WDK = 0x6e3814, GD = 0xffc52a, GDK = 0xd88a0a, GL = 0xfff07a;
  v.box(0,1.8,0,8,3.6,5.4,WD);            // body
  v.box(0,.25,0,8.4,.5,5.8,GDK,{studs:false});
  [-3.4,3.4].forEach(x => v.box(x,1.9,0,.8,3.8,5.6,GD,{studs:false}));
  v.box(0,3.5,0,8.3,.5,5.7,GD,{studs:false});
  [-1.1,1.1].forEach(x => v.box(x,1.8,-2.72,.15,3.2,.1,WDK,{studs:false}));
  v.studs(1);
  const lid = new T.Group(); lid.position.set(0,3.75,2.7); g.add(lid);    // hinge at the back
  const L = Vox(); L.position.set(0,0,-2.7); lid.add(L);
  [[.45,5.8,.9],[1.2,5.2,.8],[1.9,4.2,.7],[2.45,2.6,.5]].forEach(b => L.box(0,b[0],0,8.2,b[2],b[1],GD));
  [-3.4,3.4].forEach(x => [[.45,6,.95],[1.2,5.4,.85],[1.9,4.4,.75],[2.45,2.8,.55]].forEach(b => L.box(x,b[0],0,.85,b[2]+.04,b[1]+.04,GDK,{studs:false})));
  L.box(0,2.85,0,7,.3,1.2,GL,{studs:false});
  L.studs(1);
  // padlock on the front
  const lock = new T.Group(); lock.position.set(0,2.6,-3.05); g.add(lock);
  const LM = mat(0xc9ced6,{r:.3,m:.4}), LD = mat(0x8e96a3,{r:.4,m:.3});
  const lb = new T.Mesh(geo.box, LM); lb.scale.set(2.4,2,.7); lock.add(lb);
  const kh = new T.Mesh(geo.box, mat(0x1a1f2e)); kh.scale.set(.45,.9,.1); kh.position.set(0,-.15,-.36); lock.add(kh);
  const sh = new T.Group(); sh.position.set(0,1,0); lock.add(sh);
  [[-.8,.8,0,.38,1.6],[.8,.8,0,.38,1.6],[0,1.55,0,1.98,.38]].forEach(b => { const m = new T.Mesh(geo.box, LD); m.scale.set(b[3],b[4],.38); m.position.set(b[0],b[1],b[2]); sh.add(m); });
  // coins inside (seen when open)
  const coins = new T.Group(); g.add(coins);
  for(let i=0;i<16;i++){ const c = new T.Mesh(geo.coin, mat(0xffd21f,{r:.25,m:.3,em:.25,emc:0xffb000})); c.scale.set(.75,.9,.75); c.position.set((i%5-2)*1.3+(Math.random()-.5)*.4, 3.4+Math.floor(i/5)*.25, ((i*7)%3-1)*1.1); c.rotation.set(Math.random()*.6,0,Math.random()*.6); coins.add(c); }
  coins.visible = false;
  const glow = new T.PointLight(0xffd25a, 0, 16); glow.position.set(0,5,-1); g.add(glow);
  g.userData = {lid, lock, sh, coins, glow, state:'locked', open:0, t0:0};
  g.userData.set = st => { g.userData.state = st; lock.visible = st === 'locked' || st === 'ready'; coins.visible = st === 'claimed' || st === 'opening'; };
  return g;
}

/* ----- header icons ----- */
function buildCluster(){
  const g = new T.Group();
  const reds = null;
  const mk = (pal, x, y, z, rz, s) => { const sw = {}; Object.keys(DATA.balloons.Gumball.pal).forEach(k => sw[k] = DATA.balloons.Gumball.pal[k]);
    if(pal){ sw.red = [pal[0],'P',0]; sw.redDark = [pal[1],'P',0]; sw.pink = [pal[2],'P',0]; }
    const b = buildBalloon('Gumball', sw); b.scale.setScalar(s); b.position.set(x,y,z); b.rotation.z = rz; g.add(b); return b; };
  g.userData.bs = [mk(['3D9EFF','1F6FE0','A8D8FF'],-1.3,-1.2,-1.2,.5,.9), mk(['FFD21F','E09A00','FFF3A0'],1.3,-1.4,-1.2,-.48,.88), mk(null,0,.4,1,0,1.05)];
  const bow = Vox(); bow.box(0,-5.3,1.6,1.2,.9,.9,0xff4fc8,{studs:false}); bow.box(-1,-5.2,1.6,1,1.3,.7,0xff4fc8,{studs:false,rot:[0,0,.35]}); bow.box(1,-5.2,1.6,1,1.3,.7,0xff4fc8,{studs:false,rot:[0,0,-.35]}); g.add(bow);
  return g;
}
function buildBook(){
  const v = Vox();
  v.box(0,0,0,9,11,2.2,0x2a7cf0);          // cover
  v.box(.55,0,0,7.8,10.2,2.4,0xf4f7ff,{studs:false});
  v.box(-4.3,0,0,.9,11.2,2.6,0x1a5fd6,{studs:false}); // spine
  v.box(0,0,-1.25,9.1,11.1,.3,0x2a7cf0,{studs:false});
  v.box(.3,1.4,-1.45,4,4.6,.25,0xffffff,{studs:false,em:.15});
  v.box(.3,1.6,-1.6,3,3.6,.2,0xff3b3b,{studs:false});
  v.box(.3,-.9,-1.6,.8,.8,.2,0xff3b3b,{studs:false});
  v.box(.3,-2.3,-1.55,.25,2,.2,0xffffff,{studs:false});
  v.box(-.6,2.4,-1.72,.8,.8,.1,0xffffff,{studs:false,em:.4});
  [[-2.8,4.6],[3.4,-4.4],[3.4,4.6],[-2.8,-4.4]].forEach(p => v.box(p[0],p[1],-1.5,1.2,1.2,.3,0xffc52a,{studs:false}));
  return v;
}

/* ----- zone pictures (small voxel dioramas) ----- */
function islandBase(v, cx, cy, cz, w, d, top, dirt){
  v.box(cx,cy,cz,w,1,d,top); v.box(cx,cy-1.2,cz,w-.4,1.4,d-.4,dirt);
  v.box(cx,cy-2.6,cz,w-2.2,1.4,d-2.2,dirt); v.box(cx,cy-3.9,cz,w-4.6,1.2,d-4.4,0x7a4a26); if(w>8) v.box(cx,cy-4.9,cz,w-7.4,.9,d-6.8,0x6a3e1e);
}
function tree(v,x,y,z,s){ s=s||1; v.box(x,y+1.4*s,z,.9*s,2.8*s,.9*s,0x8a5a2e); v.box(x,y+3.6*s,z,3.4*s,2*s,3.4*s,0x3fae2a); v.box(x,y+5*s,z,2.2*s,1.2*s,2.2*s,0x5fd13a); }
function cloud(v,x,y,z,s,c){ c=c||0xffffff; v.box(x,y,z,6*s,2*s,3*s,c); v.box(x-1.4*s,y+1.4*s,z,3*s,1.6*s,2.4*s,c); v.box(x+1.4*s,y+1.6*s,z,3.4*s,2*s,2.6*s,c); }
const DIO = {
  'Meadow Sky'(v){ islandBase(v,0,0,0,12,9,0x5fd13a,0x9a5a2e); tree(v,1,.5,1,1); [[-3.5,-2],[-2,2.8],[4,-2.6],[3.2,2.6]].forEach(p => { v.box(p[0],.9,p[1],.4,.8,.4,0x3fae2a,{studs:false}); v.box(p[0],1.45,p[1],.8,.5,.8,0xffd21f,{studs:false}); });
    v.box(-3.6,1,.6,1.6,1,1.6,0x3fae2a); cloud(v,-9,5,-6,.8); cloud(v,9,7,-8,.7); },
  'Cloud Shelf'(v){ [[0,0,0,12,2,8],[-4,1.4,1,4,1.6,4],[4.6,1.2,-.5,3.6,1.8,4.4],[0,-1.6,0,9,1.6,6]].forEach(b => v.box(b[0],b[1],b[2],b[3],b[4],b[5],0xffffff));
    const RB = [0xff4a4a,0xff9a2a,0xffd21f,0x5fd13a,0x3d9eff,0x9a5cff];
    RB.forEach((c,i) => { const r = 6.2 - i*.62; for(let k=0;k<=10;k++){ const a = Math.PI*k/10; v.box(Math.cos(a)*r, 1+Math.sin(a)*r, -1.5, .9, .9, .9, c, {studs:false}); } });
    v.box(-4.6,2.6,1.4,1.2,.4,1.2,0x7fdcff); cloud(v,8.6,6,-7,.6); },
  'Kite Fields'(v){ islandBase(v,0,0,0,12,8,0xc8874a,0x7a4a26); for(let x=-5;x<=5;x+=1.25) v.box(x,.55,0,1.1,.2,7.6,x%2.5?0xb0703a:0xc8874a,{studs:false});
    [[-5.2,-3.2],[5.2,-3.2]].forEach(p => { v.box(p[0],1.8,p[1],.5,3,.5,0x6a3e1e); v.box(p[0],3.5,p[1],.9,.9,.9,0xffd25a,{em:.8}); });
    v.box(3.4,8.5,-2,4,4,.3,0xff4a4a,{rot:[0,.3,Math.PI/4],studs:false}); v.box(3.4,8.5,-1.8,2.8,2.8,.3,0x3d9eff,{rot:[0,.3,Math.PI/4],studs:false});
    for(let i=0;i<6;i++) v.box(2.6-i*.55,6-i*.95,-1.6,.15,.95,.15,0xffffff,{studs:false}); [0,1,2].forEach(i => v.box(3.6+i*.3,5.8-i*1.1,-1.9,.7,.35,.2,[0xffd21f,0x5fd13a,0xff4fc8][i],{studs:false})); },
  'Windways'(v){ islandBase(v,0,0,0,10,8,0x5ce8cf,0x5a6a8a); v.box(0,3,0,1.6,5,1.6,0xeef3ff); v.box(0,5.8,-1,.6,.6,.6,0x5a6a8a,{studs:false});
    for(let i=0;i<4;i++) v.box(0,5.8,-1.2,.5,6,.2,0xffffff,{rot:[0,0,i*Math.PI/2+.4],studs:false});
    [[-7,4,1],[6,6,.8],[-5,8,.7]].forEach(w => { for(let k=0;k<6;k++) v.box(w[0]+k*.9*w[2],w[1]+Math.sin(k*.9)*.6,2,1*w[2],.35,.35,0xffffff,{studs:false,op:.9}); }); },
  'Thunderhead'(v){ cloud(v,0,3,0,1.6,0x6a6f96); cloud(v,-3,5,-1,1,0x7f84ac); v.box(0,2,0,10,1,5,0x585c80);
    [[0,0,.4],[.8,-2,-.4],[-.2,-4,.4],[.6,-6,-.3]].forEach(b => v.box(b[0],b[1],2.4,.8,2.4,.4,0xffe24a,{em:1.2,rot:[0,0,b[2]],studs:false})); },
  'Hail Belt'(v){ islandBase(v,0,0,0,11,8,0xe8f6ff,0x8fb6d8); v.box(-2,1.6,0,2.4,2.4,2.4,0xbfe8ff,{rot:[.2,.5,.1],studs:false}); v.box(2.6,1.2,1,1.6,1.6,1.6,0xbfe8ff,{rot:[.4,.2,.3],studs:false});
    for(let i=0;i<12;i++) v.box(-8+i*1.5,4+((i*37)%7),-3+((i*13)%5),.6,.6,.6,0xffffff,{rot:[i,i*2,0],studs:false}); },
  'Stratosphere'(v){ for(let i=-7;i<=7;i++) v.box(i*1.6,-6+Math.pow(Math.abs(i)/7,2)*-3+3,-2,1.6,4,1,i%3?0x3d9eff:0x5fd13a,{studs:false});
    v.box(0,3,0,2,2,2,0xc9ced6); v.box(-3,3,0,3.4,.25,1.6,0x3d6aff,{em:.3,studs:false}); v.box(3,3,0,3.4,.25,1.6,0x3d6aff,{em:.3,studs:false});
    for(let i=0;i<14;i++) v.box(-10+((i*53)%20),2+((i*31)%9),-6,.3,.3,.3,0xffffff,{em:1,studs:false}); },
  'Orbit'(v){ v.box(0,-1,0,12,4,9,0xa8adbc); v.box(0,1.2,0,9,1,7,0xc9ced6); [[-3,1.8,-1,2],[2.6,1.8,1.4,1.4],[2,1.8,-2.4,1]].forEach(c => v.box(c[0],c[1],c[2],c[3],.25,c[3],0x8a8f9e,{studs:false}));
    v.box(-1,2.8,1,3,2,3,0x7fdcff,{ball:true,op:.75}); for(let i=0;i<16;i++) v.box(-10+((i*53)%20),3+((i*31)%8),-6,.3,.3,.3,0xffffff,{em:1,studs:false}); },
  'Sky Boss'(v){ const k = FUTURE['Pin King'](); k.traverse(o => { if(o.isMesh) o.material = mat(0xe8203c); }); k.scale.setScalar(.7); k.position.y = 1; v.add(k); v.box(0,8.6,0,3,.6,1,0xffc52a,{studs:false}); [-1,0,1].forEach(x => v.box(x*1.1,9.4,0,.6,1,.6,0xffc52a,{studs:false})); },
  'Secret'(v){ const cs = [0xff4a4a,0x3d9eff,0xffd21f,0x5fd13a,0xff4fc8,0x9a5cff]; for(let i=0;i<14;i++){ const x=-8+((i*41)%16), y=-3+((i*29)%11), c=cs[i%6]; v.box(x,y,-((i*7)%4),1.6,1.9,1.6,c); v.box(x,y-1.2,0,.4,.4,.4,c,{studs:false}); } },
};
function buildZone(id){ const v = Vox(); DIO[id](v); v.studs(1); return v; }

/* ================================================================== views (one shared WebGL renderer, each card draws into its own 2D canvas) */
const VIEWS = [];
function lights(scene, o){
  o = o || {};
  scene.add(new T.HemisphereLight(0xffffff, 0x8aa0c8, o.hemi != null ? o.hemi : .75));
  const k = new T.DirectionalLight(0xfff2dc, o.key != null ? o.key : .95); k.position.set(-10, 18, 22); scene.add(k);
  const f = new T.DirectionalLight(0xbfe0ff, .3); f.position.set(16, 2, 8); scene.add(f);
  const rim = new T.DirectionalLight(0xffffff, .35); rim.position.set(6, 10, -20); scene.add(rim);
}
function addView(canvas, obj, o){
  o = o || {};
  const scene = new T.Scene(); lights(scene, o.light); const pivot = new T.Group(); scene.add(pivot); pivot.add(obj);
  const cam = new T.PerspectiveCamera(o.fov || 30, 1, .5, 400);
  const fi = fitInfo(obj);
  const v = {canvas, ctx:canvas.getContext('2d'), scene, cam, pivot, obj, o, fi, t:Math.random()*10, spin:o.spin != null ? o.spin : .55, hover:0, w:0, h:0, alive:true, sil:!!o.sil, extra:o.extra};
  if(v.sil){ scene.overrideMaterial = SIL; }
  canvas.addEventListener && canvas.parentElement && canvas.parentElement.addEventListener('mouseenter', () => v.hover = 1);
  canvas.parentElement && canvas.parentElement.addEventListener('mouseleave', () => v.hover = 0);
  VIEWS.push(v); return v;
}
function frameView(v){
  const asp = v.w / v.h; v.cam.aspect = asp; v.cam.fov = v.o.fov || 30;
  const s = v.fi.s, c = v.fi.c, pad = v.o.pad || 1.12;
  const r = Math.max(s.y*.5, Math.max(s.x, s.z)*.5/asp*1.02);
  const dist = r*pad / Math.tan(T.MathUtils.degToRad(v.cam.fov/2));
  const el = v.o.elev != null ? v.o.elev : .12;
  v.cam.position.set(0, c.y + dist*Math.sin(el), dist*Math.cos(el)); v.cam.lookAt(0, c.y + (v.o.lookY || 0), 0);
  v.pivot.position.set(-c.x*0, 0, 0); v.cam.updateProjectionMatrix();
}
function visibleRect(c){
  if(!c.isConnected || c.offsetParent === null) return null;
  const r = c.getBoundingClientRect(); if(r.width < 2 || r.height < 2) return null;
  let p = c.parentElement, clip = {l:0, t:0, r:innerWidth, b:innerHeight};
  while(p){ if(p.classList && p.classList.contains('scroll')){ const q = p.getBoundingClientRect(); clip = {l:Math.max(clip.l,q.left), t:Math.max(clip.t,q.top), r:Math.min(clip.r,q.right), b:Math.min(clip.b,q.bottom)}; } p = p.parentElement; }
  if(r.right < clip.l || r.left > clip.r || r.bottom < clip.t || r.top > clip.b) return null;
  return r;
}
let lastT = performance.now(), clock = 0, FROZEN = false;
function renderViews(dt){
  for(let i=VIEWS.length-1;i>=0;i--){
    const v = VIEWS[i]; if(!v.canvas.isConnected){ VIEWS.splice(i,1); continue; }
    const r = visibleRect(v.canvas); if(!r) continue;
    const scale = r.width / v.canvas.offsetWidth || 1;
    const w = Math.min(RH, Math.round(v.canvas.offsetWidth*scale*DPR)), h = Math.min(RH, Math.round(v.canvas.offsetHeight*scale*DPR));
    if(w !== v.w || h !== v.h){ v.w = w; v.h = h; v.canvas.width = w; v.canvas.height = h; frameView(v); }
    v.t += dt;
    const sp = v.spin * (1 + v.hover*3.2);
    if(v.o.yaw0 != null) v.pivot.rotation.y = v.o.yaw0 + Math.sin(v.t*.6)*(v.o.sway||.35) + (v.o.spinAdd? v.t*sp : 0);
    else v.pivot.rotation.y += sp*dt;
    v.pivot.position.y = Math.sin(v.t*1.6)*(v.o.bob != null ? v.o.bob : .25) + (v.hover ? Math.abs(Math.sin(v.t*7))*.25 : 0);
    if(v.obj.userData.anim) v.obj.userData.anim(v.t, dt);
    if(v.extra) v.extra(v, dt);
    R.setViewport(0, 0, w, h); R.setScissor(0, 0, w, h); R.setScissorTest(true);
    R.clear(); R.render(v.scene, v.cam);
    v.ctx.clearRect(0, 0, w, h); v.ctx.drawImage(R.domElement, 0, RH - h, w, h, 0, 0, w, h);
  }
}
function loop(now){
  const dt = Math.min(.05, (now - lastT)/1000); lastT = now;
  if(!FROZEN){ clock += dt; renderViews(dt); stepFx(dt); scrollbars(); }
  requestAnimationFrame(loop);
}

/* ================================================================== background (blurred game world) */
function drawBackground(){
  const c = $('#bg'); const w = Math.round(c.clientWidth*.5), h = Math.round(c.clientHeight*.5); if(!w || !h) return;
  const r = new T.WebGLRenderer({canvas:c, antialias:false}); r.setPixelRatio(1); r.setSize(w, h, false);
  const s = new T.Scene(); s.background = new T.Color(0x86c8ff); s.fog = new T.Fog(0xa8d8ff, 80, 260); lights(s, {hemi:.8});
  const g = Vox(); for(let x=-12;x<12;x++) for(let z=-4;z<12;z++) g.box(x*8, -2, -z*8, 8, 2, 8, (x+z)%2 ? 0x5fd13a : 0x57c934); g.studs(2); s.add(g);
  [[-60,40,-120,1.6],[50,58,-150,1.9],[0,80,-210,2.2],[-110,70,-200,1.8],[110,30,-110,1.4]].forEach(p => { const z = buildZone('Meadow Sky'); z.scale.setScalar(p[3]); z.position.set(p[0],p[1],p[2]); s.add(z); });
  const cl = Vox(); [[-80,60,-170,3],[70,85,-190,3.5],[20,45,-100,2],[-30,95,-220,4]].forEach(p => cloud(cl,p[0],p[1],p[2],p[3])); s.add(cl);
  const cam = new T.PerspectiveCamera(55, w/h, 1, 600); cam.position.set(0, 18, 40); cam.lookAt(0, 28, -60);
  r.render(s, cam); r.dispose && r.forceContextLoss && 0;
}

/* ================================================================== layout */
const UI = {W:1280, H:720, s:1};
const ui = $('#ui');
function layout(){
  const vw = innerWidth, vh = innerHeight;
  let s = Math.min(vw*.965/1200, vh*.95/600, 1.25); s = Math.max(s, .28);
  UI.s = s; UI.W = vw/s; UI.H = vh/s; UI.compact = UI.H < 760;
  ui.classList.toggle('compact', UI.compact); document.body.classList.toggle('short', vh < 520);
  ui.style.width = UI.W+'px'; ui.style.height = UI.H+'px'; ui.style.transform = `scale(${s})`;
  [WB, WI].forEach(w => w && w.place());
}

/* ================================================================== BALLOONS window */
function makeWindow(o){
  const w = el(ui, `<div class="win"><div class="frame"><div class="studs"></div></div></div>`);
  const f = w.firstElementChild;
  const hdr = el(f, `<div class="hdr ${o.color}"><div class="fill"></div><div class="studs"></div><div class="shine"></div><div class="base"></div></div>`);
  w.ttl = el(f, `<div class="title t" style="left:${o.titleX}px">${o.title}</div>`);
  const ic = el(f, `<div class="hicon" style="left:${o.icon.x}px;top:${o.icon.y}px;width:${o.icon.w}px;height:${o.icon.h}px"><canvas class="v" style="width:100%;height:100%"></canvas></div>`);
  addView(ic.firstElementChild, o.icon.obj(), o.icon.view);
  const x = el(f, `<div class="xbtn"></div>`);
  btn(x, {cls:'b-red', label:'', icon:'<span style="width:46px;height:46px;display:inline-block">'+ICO.x+'</span>', w:78, h:78, r:16, onClick:() => closeWin(w)});
  w.f = f; w.hdr = hdr;
  return w;
}
let WB, WI;
function buildBalloonsWin(){
  const w = makeWindow({color:'blue', title:'BALLOONS', titleX:205,
    icon:{x:-14, y:-42, w:204, h:142, obj:buildCluster, view:{spin:0, yaw0:0, sway:.25, bob:.3, pad:1.0, fov:28}}});
  const f = w.f;
  const search = el(f, `<div class="search" style="left:18px;top:118px;width:340px">${'<span style="width:30px;height:30px;display:inline-block">'+ICO.search+'</span>'}<input placeholder="Search balloons..." spellcheck="false"></div>`);
  const inp = search.querySelector('input'); inp.addEventListener('input', () => { S.search = inp.value.trim().toLowerCase(); fillGrid(); });
  const tabs = el(f, `<div class="tabs" style="left:372px;top:118px"></div>`);
  ['All','Owned','Favorites'].forEach(name => {
    const tb = el(tabs, `<div class="tab ${S.btab===name?'on':''}" style="width:${name==='Favorites'?150:126}px"><div class="face">${name==='Favorites'?'<span style="width:24px;height:24px;display:inline-block;position:relative">'+ICO.starOn+'</span>':''}<span class="lbl t">${name}</span></div></div>`);
    tb.addEventListener('click', () => { S.btab = name; [...tabs.children].forEach(c => c.classList.toggle('on', c === tb)); SFX.tab(); fillGrid(); });
  });
  w.scrollEl = el(f, `<div class="scroll" style="left:14px;top:188px;width:784px"><div class="grid"></div></div>`);
  w.sbar = el(f, `<div class="sbar" style="left:802px;top:192px"><div class="thumb"></div></div>`);
  w.detail = el(f, `<div class="detail" style="left:826px;top:118px;width:346px"></div>`);
  w.foot = el(f, `<div class="foot" style="left:18px;right:18px"><div class="studs"></div><div class="ftxt t" id="ownedTxt"></div><div style="flex:1"></div></div>`);
  btn(w.foot, {cls:'b-green', label:'OPEN INDEX', icon:'<span style="width:46px;height:40px;display:inline-block">'+ICO.book+'</span>', w:300, h:66, fs:30, onClick:() => swapTo(WI)});
  w.place = () => {
    const c = UI.compact, H = Math.min(840, UI.H - (c ? 34 : Math.max(40, UI.H*.06) + 16)); w.H = H;
    w.style.height = H+'px'; w.style.left = ((UI.W-1200)/2)+'px'; w.style.top = (c ? (UI.H-H)/2 + 8 : Math.max(44, (UI.H-H)/2 + 18))+'px';
    const tb = c ? 90 : 118, tbH = c ? 50 : 56, fh = c ? 64 : 78;
    search.style.top = tb+'px'; tabs.style.top = tb+'px'; w.detail.style.top = tb+'px';
    const top = tb + tbH + 14;
    const footTop = H - 10 - (c ? 12 : 18) - fh; w.foot.style.top = footTop+'px';
    const bot = footTop - (c ? 10 : 14); w.scrollEl.style.top = top+'px'; w.sbar.style.top = (top+4)+'px';
    w.scrollEl.style.height = (bot-top)+'px'; w.sbar.style.height = (bot-top-8)+'px'; w.detail.style.height = (bot-tb)+'px';
  };
  return w;
}
function sortedBalloons(){
  let list = BORDER.slice();
  list.sort((a,b) => (isOwned(b) - isOwned(a)) || (BORDER.indexOf(a) - BORDER.indexOf(b)));
  if(S.btab === 'Owned') list = list.filter(isOwned);
  if(S.btab === 'Favorites') list = list.filter(n => S.fav.has(n));
  if(S.search) list = list.filter(n => n.toLowerCase().includes(S.search) || B[n].tier.toLowerCase().includes(S.search));
  return list;
}
function cardBtn(card, n){
  const b = card.btn;
  if(isOwned(n)){ if(S.equipped === n){ setBtnCls(b,'b-blue cbtn'); b.setLabel('EQUIPPED'); } else { setBtnCls(b,'b-green cbtn'); b.setLabel('EQUIP'); } }
  else { setBtnCls(b,'b-grey cbtn'); b.setLabel('LOCKED', iconLock); }
}
function fillGrid(){
  const grid = WB.scrollEl.firstElementChild; grid.innerHTML = '';
  const list = sortedBalloons();
  if(!list.length){ el(grid, `<div style="grid-column:1/-1;text-align:center;padding:60px 0;font-size:26px;color:#8fa3dc">${S.btab==='Favorites'?'Tap the star on a balloon to add it here.':'No balloons found.'}</div>`); }
  list.forEach((n, i) => {
    const sec = n === 'Cluck' && !isOwned(n);
    const c = el(grid, `<div class="card r-${B[n].tier} ${S.sel===n?'sel':''}" data-n="${n}"><div class="bgc"><div class="rays"></div><div class="glow"></div><div class="studs"></div></div><div class="rim"></div>
      <div class="name t">${sec?'???':n}</div><div class="pill">${B[n].tier.toUpperCase()}</div>
      <div class="star">${S.fav.has(n)?ICO.starOn:ICO.starOff}</div>
      <div class="view"><canvas class="v" style="width:100%;height:100%"></canvas></div>${sec?'<div class="qm t">?</div>':''}</div>`);
    c.btn = btn(c, {cls:'b-green', label:'EQUIP', fs:30, onClick:() => onCardBtn(n, c)}); c.btn.classList.add('cbtn');
    cardBtn(c, n);
    addView(c.querySelector('canvas'), buildBalloon(n), {spin:.6, pad:.94, elev:.1, sil:sec});
    c.querySelector('.star').addEventListener('click', e => { e.stopPropagation(); toggleFav(n, c); });
    c.addEventListener('click', () => select(n));
    c.addEventListener('mouseenter', () => SFX.hover());
  });
  $('#ownedTxt').textContent = `${Object.keys(S.owned).length} / ${BORDER.length} owned`;
  WB.scrollEl.scrollTop = 0;
}
function toggleFav(n, c){
  if(S.fav.has(n)){ S.fav.delete(n); SFX.unfav(); } else { S.fav.add(n); SFX.fav(); }
  const st = c.querySelector('.star'); st.innerHTML = S.fav.has(n) ? ICO.starOn : ICO.starOff; st.classList.remove('bump'); void st.offsetWidth; st.classList.add('bump');
  if(S.btab === 'Favorites') setTimeout(fillGrid, 250);
}
function onCardBtn(n, c){
  if(!isOwned(n)){ SFX.err(); c.classList.remove('shake'); void c.offsetWidth; c.classList.add('shake'); toast(n==='Cluck'?'A secret! Look for it in Balloon Rain.':`Buy ${n} in the ${B[n].zone} shop!`, true); select(n); return; }
  if(S.equipped === n){ SFX.click(); select(n); return; }
  S.equipped = n; SFX.equip();
  document.querySelectorAll('#ui .card').forEach(k => cardBtn(k, k.dataset.n));
  select(n); toast(`${n} equipped!`);
  burstAt(c.querySelector('.view'), 'star');
}
function select(n){
  S.sel = n; document.querySelectorAll('#ui .card').forEach(k => k.classList.toggle('sel', k.dataset.n === n));
  fillDetail();
}
function fillDetail(){
  const d = WB.detail, n = S.sel, b = B[n], a = AB[n], sec = n === 'Cluck' && !isOwned(n);
  d.className = 'detail dpop';
  d.innerHTML = `<div class="studs"></div><div class="rays"></div>
    <div class="dname t">${sec?'???':n}</div>
    <div class="prow"><div class="pill r-${b.tier}" style="font-size:19px;padding:6px 18px 5px">${b.tier.toUpperCase()}</div>${isOwned(n)?`<div class="lvl t" style="--sw:5px">LV ${S.owned[n].lv}</div>`:''}</div>
    <div class="dview"><canvas class="v"></canvas></div>
    <div class="flav t">${sec?'A secret balloon. Nobody knows where it comes from.':b.flav}</div>
    <div class="abox"><div class="ai" style="background:${AB_BG[n]}">${abIcon(sec?'Gumball':n)}</div>
      <div style="flex:1;min-width:0"><div class="an t">${sec?'???':a.ab}${a.key&&!sec?`<span class="kt">${a.key}</span>`:''}</div><div class="ad">${sec?'Find it to learn its power.':a.desc}</div></div></div>
    <div class="stats"><div class="stat"><b class="t" style="--sw:5px">${sec?'?':b.max}</b><i>MAX SIZE</i></div><div class="stat"><b class="t" style="--sw:5px">${sec?'?':'x'+b.earn}</b><i>COINS</i></div><div class="stat"><b class="t" style="--sw:5px">${sec?'?':b.tough}</b><i>TOUGH</i></div></div>`;
  if(!isOwned(n)) el(d.querySelector('.dview'), `<div class="where"><span style="width:18px;height:18px;display:inline-block;vertical-align:-3px">${ICO.lock}</span> ${sec?'Only in a Balloon Rain':'Buy it in the '+b.zone+' shop'}</div>`);
  const db = btn(d, {cls:'b-green', label:'EQUIP', fs:40, r:16, onClick:() => { const c = document.querySelector(`#ui .card[data-n="${n}"]`) || d; onCardBtn(n, c); }});
  db.classList.add('dbtn');
  if(isOwned(n)){ if(S.equipped === n){ setBtnCls(db,'b-blue dbtn'); db.setLabel('EQUIPPED'); } }
  else { setBtnCls(db,'b-grey dbtn'); db.setLabel(sec?'SECRET':'LOCKED', '<span style="width:38px;height:38px;display:inline-block">'+ICO.lock+'</span>'); }
  addView(d.querySelector('canvas'), buildBalloon(n), {spin:.5, pad:.92, elev:.08, bob:.35, sil:sec});
  void d.offsetWidth;
}

/* ================================================================== INDEX window */
const ITAB = {
  Balloons:{title:'BALLOON INDEX', icon:ICO.balloonTab, tc:'linear-gradient(#6cc0ff,#2e8cff 55%,#1d6ee6)', hint:'Collect balloons to complete each zone.'},
  Mutations:{title:'MUTATION INDEX', icon:ICO.mutTab, tc:'linear-gradient(#e2b2ff,#b25cff 55%,#7a2be0)', hint:'Roll mutations while you fly. Land to keep them!'},
  Enemies:{title:'ENEMY INDEX', icon:ICO.enTab, tc:'linear-gradient(#ffb37a,#ff6a2a 55%,#e0420f)', hint:'Meet every enemy to complete each zone.'},
};
function buildIndexWin(){
  const w = makeWindow({color:'green', title:'BALLOON INDEX', titleX:0,
    icon:{x:4, y:-34, w:160, h:150, obj:buildBook, view:{spin:0, yaw0:Math.PI+.62, sway:.18, bob:.3, pad:1.12, fov:28, elev:.22}}});
  w.ttl.style.left = '50%'; w.ttl.style.transform = 'translate(-50%,-50%)';
  const f = w.f;
  const tabs = el(f, `<div class="itabs" style="left:18px;right:18px;top:116px"></div>`);
  w.tabEls = {};
  Object.keys(ITAB).forEach(k => {
    const tb = el(tabs, `<div class="itab ${S.itab===k?'on':''}" style="--tc:${ITAB[k].tc}"><div class="face">${ITAB[k].icon}<span class="lbl t">${k.toUpperCase()}</span><span class="cnt"></span></div></div>`);
    tb.addEventListener('click', () => { if(S.itab === k) return; S.itab = k; SFX.tab(); fillIndex(); });
    w.tabEls[k] = tb;
  });
  w.prog = el(f, `<div class="prog" style="left:22px;right:22px;top:196px;height:60px"><div class="ptxt t"></div><div class="bar" style="flex:1"><div class="fillp" style="width:0"></div></div><div class="ppct t" style="font-size:32px;--sw:8px;width:76px;text-align:right"></div></div>`);
  btn(w.prog, {cls:'b-gold', label:'REWARDS', icon:'<span style="width:38px;height:38px;display:inline-block">'+ICO.gift+'</span>', w:236, h:62, fs:27, onClick:openRewards});
  w.scrollEl = el(f, `<div class="scroll" style="left:16px;top:270px;width:1132px"></div>`);
  w.sbar = el(f, `<div class="sbar" style="left:1156px;top:274px"><div class="thumb"></div></div>`);
  w.foot = el(f, `<div class="foot" style="left:18px;right:18px"><div class="studs"></div><div class="fhint" id="idxHint"></div><div style="flex:1"></div></div>`);
  btn(w.foot, {cls:'b-blue', label:'BACK TO BALLOONS', w:400, h:66, fs:30, onClick:() => swapTo(WB)});
  w.place = () => {
    const c = UI.compact, H = Math.min(860, UI.H - (c ? 34 : Math.max(40, UI.H*.06) + 16)); w.H = H;
    w.style.height = H+'px'; w.style.left = ((UI.W-1200)/2)+'px'; w.style.top = (c ? (UI.H-H)/2 + 8 : Math.max(44, (UI.H-H)/2 + 18))+'px';
    const tb = c ? 88 : 116, pr = c ? 152 : 196, top = c ? 212 : 270, fh = c ? 64 : 78;
    tabs.style.top = tb+'px'; w.prog.style.top = pr+'px';
    const footTop = H - 10 - (c ? 12 : 18) - fh; w.foot.style.top = footTop+'px';
    const bot = footTop - (c ? 10 : 14); w.scrollEl.style.top = top+'px'; w.sbar.style.top = (top+4)+'px';
    w.scrollEl.style.height = (bot-top)+'px'; w.sbar.style.height = (bot-top-8)+'px';
  };
  return w;
}
function counts(){
  const bal = BORDER.filter(isOwned).length;
  const mutTotal = MUT.universal.length + BORDER.reduce((a,n) => a + MUT[n].length, 0);
  const en = EN.filter(e => S.met[e.id]).length;
  return {Balloons:[bal, BORDER.length], Mutations:[0, mutTotal], Enemies:[en, EN.length]};
}
function fillIndex(){
  const w = WI, k = S.itab, C = counts();
  Object.keys(w.tabEls).forEach(t => { w.tabEls[t].classList.toggle('on', t === k); w.tabEls[t].querySelector('.cnt').textContent = C[t][0]+'/'+C[t][1]; });
  w.ttl.textContent = ITAB[k].title;
  const [a, b] = C[k]; const pct = Math.round(a/b*100);
  w.prog.querySelector('.ptxt').textContent = `Discovered ${a} / ${b}`;
  w.prog.querySelector('.ppct').textContent = pct+'%';
  const fp = w.prog.querySelector('.fillp'); fp.style.width = '0'; requestAnimationFrame(() => requestAnimationFrame(() => fp.style.width = Math.max(pct, a?4:0)+'%'));
  $('#idxHint').textContent = ITAB[k].hint;
  const sc = w.scrollEl; sc.innerHTML = ''; sc.scrollTop = 0;
  if(k === 'Balloons') ZONES.forEach(z => { const list = BORDER.filter(n => B[n].zone === z.id); if(list.length) indexRow(sc, z, list.map(n => ({kind:'balloon', n})), z.chest, 'B:'+z.id); });
  if(k === 'Enemies') ZONES.forEach(z => { const list = EN.filter(e => e.zone === z.id); if(list.length) indexRow(sc, z, list.map(e => ({kind:'enemy', e})), z.echest, 'E:'+z.id); });
  if(k === 'Mutations'){
    el(sc, `<div class="soon"><span style="width:52px;height:52px;flex:0 0 52px">${ICO.mutTab}</span><div><div class="t">MUTATIONS ARE COMING</div><div class="s">They roll on your balloon while you fly. Land to keep them, pop and they are gone!</div></div></div>`);
    [[0,4,'Any balloon'],[4,8,'Any balloon']].forEach((r,i) => indexRow(sc, {id:'Any balloon', mut:'Gumball', part:i+1}, MUT.universal.slice(r[0],r[1]).map(m => ({kind:'mut', m, b:'Gumball'})), i ? 250000 : 25000, 'M:any'+i));
    BORDER.forEach(n => indexRow(sc, {id:n, mut:n}, MUT[n].map(m => ({kind:'mut', m, b:n})), Math.max(2000, (B[n].price||200000000)*2), 'M:'+n));
  }
}
function zoneThumb(row, z, found, total){
  if(z.mut){
    const n = z.mut, own = isOwned(n) || z.id === 'Any balloon';
    const t = el(row, `<div class="zone r-${B[n].tier}" style="background:var(--cg)"><div class="studs" style="--ss:24px;--so:.6"></div><canvas class="v"></canvas>
      <div class="zn t" style="font-size:${z.id.length>9?26:30}px">${z.id==='Any balloon'?'Any balloon':(own?n:'???')}</div><div class="zc t">${found} / ${total}</div></div>`);
    let obj; if(z.id === 'Any balloon'){ obj = new T.Group(); [['Gumball',-4.2,.2],['Ember',0,0],['Spike',4.2,.3]].forEach(p => { const q = buildBalloon(p[0]); q.scale.setScalar(.62); q.position.set(p[1],p[2],0); obj.add(q); }); }
    else obj = buildBalloon(n);
    addView(t.querySelector('canvas'), obj, {spin:.4, pad:1.25, lookY:-1.6, elev:.1, sil:!own});
    return t;
  }
  const t = el(row, `<div class="zone" style="background:linear-gradient(${z.sky[0]},${z.sky[1]})"><canvas class="v"></canvas>${z.open?'':'<div class="zlock t" style="--sw:0">SOON</div>'}
     <div class="zn t">${z.id}</div><div class="zc t">${found} / ${total}</div></div>`);
  addView(t.querySelector('canvas'), buildZone(z.id), {spin:0, yaw0:-.5, sway:.3, bob:.15, pad:1.18, elev:.32, lookY:-2.4, fov:32});
  return t;
}
function indexRow(sc, z, items, reward, key){
  const row = el(sc, `<div class="row"><div class="studs"></div></div>`);
  const found = items.filter(it => it.kind === 'balloon' ? isOwned(it.n) : it.kind === 'enemy' ? !!S.met[it.e.id] : false).length;
  zoneThumb(row, z, found, items.length);
  items.forEach(it => indexCard(row, it));
  const done = found === items.length;
  const st = S.claimed.has(key) ? 'claimed' : done ? 'ready' : 'locked';
  const ch = el(row, `<div class="chest ${st==='ready'?'ready':''}"><div class="ct t">${z.mut?'ROW REWARD':'ZONE REWARD'}</div><div class="view"><canvas class="v"></canvas></div><div class="amt"><span style="width:18px;height:18px;display:inline-block;vertical-align:-3px">${ICO.coin}</span> <span class="t" style="--sw:4px">${fmt(reward)}</span></div></div>`);
  const chest = buildChest(); chest.userData.set(st); if(st === 'claimed'){ chest.userData.open = 1; }
  const v = addView(ch.querySelector('canvas'), chest, {spin:0, yaw0:Math.PI-.5, sway:.12, bob:st==='ready'?.0:.05, pad:1.62, elev:.36, lookY:1.1, fov:30, extra:chestAnim});
  const cb = btn(ch, {cls: st==='ready' ? 'b-green' : 'b-grey', label: st==='ready' ? 'CLAIM!' : st==='claimed' ? 'CLAIMED' : 'LOCKED', icon: st==='locked' ? '<span style="width:22px;height:22px;display:inline-block">'+ICO.lock+'</span>' : '', onClick:() => claim(key, reward, ch, cb, chest)});
  cb.classList.add('cbtn'); if(st === 'claimed') cb.style.opacity = .75;
}
function chestAnim(v, dt){
  const u = v.obj.userData, st = u.state;
  if(st === 'ready'){ const p = (Math.sin(v.t*5)+1)/2; v.pivot.position.y = Math.abs(Math.sin(v.t*3.2))*.7; v.pivot.rotation.z = Math.sin(v.t*6.4)*.05; u.sh.position.y = 1 + p*.35; u.glow.intensity = .6 + p*.8; }
  if(st === 'opening'){ u.open = Math.min(1, u.open + dt*2.2); u.glow.intensity = 2.2*(1-u.open*.4); if(u.open >= 1) u.set('claimed'); }
  if(st === 'claimed') u.glow.intensity = .7;
  const e = st === 'locked' || st === 'ready' ? 0 : (1 - Math.pow(1-u.open, 3));
  u.lid.rotation.x = e*1.35 - (st==='opening' ? Math.sin(u.open*Math.PI)*.12 : 0);
}
function claim(key, reward, ch, cb, chest){
  if(S.claimed.has(key)){ SFX.click(); return; }
  if(chest.userData.state !== 'ready'){ SFX.err(); ch.classList.remove('shake'); void ch.offsetWidth; ch.classList.add('shake'); toast('Fill the whole row first!', true); return; }
  S.claimed.add(key); chest.userData.set('opening'); chest.userData.open = 0; ch.classList.remove('ready');
  setBtnCls(cb, 'b-grey cbtn'); cb.setLabel('CLAIMED'); cb.style.opacity = .75;
  SFX.chest(); burstAt(ch.querySelector('.view'), 'coin', 18); S.coins += reward;
  const r = ch.getBoundingClientRect(); setTimeout(() => toast(`+${fmt(reward)} coins!`, false, {x:Math.min(UI.W-150,(r.left+r.width/2)/UI.s), y:r.top/UI.s - 64}), 300);
}
function indexCard(row, it){
  let tier, name, found, pill, view, extra = '';
  if(it.kind === 'balloon'){ const n = it.n; found = isOwned(n); tier = B[n].tier; name = found ? n : 'UNDISCOVERED'; pill = tier.toUpperCase();
    const c = el(row, `<div class="icard r-${tier}"><div class="bgc"><div class="studs"></div></div><div class="rim"></div><div class="view"><canvas class="v"></canvas></div>${found?'':'<div class="qm t">?</div>'}
       <div class="iname t ${found?'':'unk'}">${name}</div><div class="ipill">${pill}</div>${found?`<div class="chk">${ICO.check}</div>`:''}</div>`);
    addView(c.querySelector('canvas'), buildBalloon(n), {spin:.6, pad:1.0, elev:.1, sil:!found});
    c.addEventListener('click', e => popover(c, it, found));
    return c; }
  if(it.kind === 'enemy'){ const e = it.e; found = !!S.met[e.id]; const D = DANGER[e.danger];
    const c = el(row, `<div class="icard" style="--cg:radial-gradient(circle at 50% 45%,${e.col[0]} 0,${e.col[1]} 40%,${e.col[2]} 100%);--pc:${D.pc};--pt:${D.pt}"><div class="bgc"><div class="studs"></div></div><div class="rim"></div><div class="view"><canvas class="v"></canvas></div>${found?'':'<div class="qm t">?</div>'}
       <div class="iname t ${found?'':'unk'}" ${found?'style="top:112px"':''}>${found?e.id:'UNDISCOVERED'}</div>${found?`<div class="dodge t">${ICO_DODGE} DODGED ${S.met[e.id]}</div>`:''}<div class="ipill">${e.danger==='BOSS'?'<span style="width:18px;height:18px;display:inline-block;margin-right:5px">'+ICO.skull+'</span>':''}${e.danger}</div>${found?`<div class="chk">${ICO.check}</div>`:''}</div>`);
    const obj = e.built ? ENEMY[e.id]() : FUTURE[e.id]();
    const VO = {Plane:{yaw0:2.5, elev:.75, pad:1.0}, Nimbo:{yaw0:Math.PI+.35, pad:1.0}, Pinwheel:{yaw0:Math.PI+.3, pad:1.02}};
    addView(c.querySelector('canvas'), obj, Object.assign({spin:0, yaw0:Math.PI+.55, sway:.45, bob:.2, pad:e.built?1.04:1.1, elev:.18, sil:!found}, VO[e.id]||{}));
    if(found) c.querySelector('.view').style.height = '106px';
    c.addEventListener('click', () => popover(c, it, found));
    return c; }
  // mutation: none discovered yet; silhouette of its balloon with a "?"
  tier = it.m[1];
  const c = el(row, `<div class="icard r-${tier}"><div class="bgc"><div class="studs"></div></div><div class="rim"></div><div class="view"><canvas class="v"></canvas></div><div class="qm t">?</div>
     <div class="iname t unk">UNDISCOVERED</div><div class="ipill">${tier.toUpperCase()}</div></div>`);
  addView(c.querySelector('canvas'), buildBalloon(it.b), {spin:.5, pad:1.0, elev:.1, sil:true});
  c.addEventListener('click', () => popover(c, it, false));
  return c;
}

/* ----- info bubble on index cards ----- */
let POP = null;
function closePop(){ if(POP){ POP.remove(); POP = null; } }
function popover(card, it, found){
  closePop(); SFX.click();
  let h = '';
  if(it.kind === 'balloon'){ const n = it.n, b = B[n];
    h = found ? `<div class="ph"><div class="pn t">${n}</div><div class="pill r-${b.tier}" style="font-size:14px">${b.tier.toUpperCase()}</div></div>
      <div class="pl"><b>${AB[n].ab}:</b> ${AB[n].desc}</div><div class="pl">Found! Level ${S.owned[n].lv}.</div>`
      : `<div class="ph"><div class="pn t">???</div><div class="pill r-${b.tier}" style="font-size:14px">${b.tier.toUpperCase()}</div></div>
      <div class="pl">${n==='Cluck'?'A secret balloon. It only shows up in a <b>Balloon Rain</b>.':`Sold in the <b>${b.zone}</b> shop. Buy it once to add it to your Index.`}</div>`; }
  else if(it.kind === 'enemy'){ const e = it.e;
    h = found ? `<div class="ph"><div class="pn t">${e.id}</div><div class="pill" style="--pc:${DANGER[e.danger].pc};--pt:${DANGER[e.danger].pt};font-size:14px">${e.danger}</div></div>
      <div class="pl">Lives in <b>${e.zone}</b>. Attack: <b>${e.atk}</b>.</div><div class="tip">TIP: ${e.tip}</div><div class="pl">You dodged it <b>${S.met[e.id]}</b> times.</div>`
      : `<div class="ph"><div class="pn t">???</div><div class="pill" style="--pc:${DANGER[e.danger].pc};--pt:${DANGER[e.danger].pt};font-size:14px">${e.danger}</div></div>
      <div class="pl">Something lives in <b>${e.zone}</b>. Fly there to meet it.</div>`; }
  else h = `<div class="ph"><div class="pn t">???</div><div class="pill r-${it.m[1]}" style="font-size:14px">${it.m[1].toUpperCase()}</div></div>
      <div class="pl">${it.b==='Gumball'&&!MUT.Gumball.some(m=>m[0]===it.m[0])?'Any balloon can roll this one.':`Only <b>${it.b}</b> can roll this one.`} Roll it while you fly, then land to keep it.</div>`;
  const p = el(ui, `<div class="pop">${h}</div>`);
  const r = card.getBoundingClientRect(), s = UI.s;
  const cx = (r.left + r.width/2)/s, top = r.top/s, bot = r.bottom/s;
  const pw = 330, ph = p.offsetHeight;
  let x = Math.max(12, Math.min(UI.W - pw - 12, cx - pw/2));
  let y = top - ph - 22, below = false; if(y < 10){ y = bot + 22; below = true; }
  p.style.left = x+'px'; p.style.top = y+'px'; p.style.setProperty('--ax', (cx - x)+'px'); if(below) p.classList.add('below');
  POP = p;
}
document.addEventListener('click', e => { if(POP && !POP.contains(e.target) && !e.target.closest('.icard')) closePop(); });

/* ----- rewards modal ----- */
function openRewards(){
  SFX.open(); closePop();
  const k = S.itab, [a, b] = counts()[k];
  const m = el(ui, `<div class="modal"><div class="mwin"><div class="hdr gold-h" style="height:86px"><div class="fill" style="background:linear-gradient(#fff07a,#ffc52a 55%,#ff9d14)"></div><div class="studs"></div><div class="shine"></div><div class="base"></div></div>
     <div class="title t" style="left:50%;transform:translate(-50%,-50%);--ts:#5a2400">REWARDS</div><div class="xbtn" style="right:10px;top:4px"></div></div></div>`);
  const mw = m.firstElementChild;
  btn(mw.querySelector('.xbtn'), {cls:'b-red', icon:'<span style="width:40px;height:40px;display:inline-block">'+ICO.x+'</span>', w:70, h:70, r:15, onClick:() => { SFX.close(); m.remove(); }});
  el(mw, `<div style="font-size:21px;color:#cfdcff;text-align:center;margin-top:-4px">${ITAB[k].title}: ${a} / ${b} found</div>`);
  [[25,1000,'+1K coins'],[50,25000,'+25K coins'],[75,250000,'+250K coins'],[100,2500000,'+2.5M coins + title']].forEach(r => {
    const need = Math.ceil(b*r[0]/100), ok = a >= need;
    const row = el(mw, `<div class="mile"><div class="mp t" style="--sw:5px">${r[0]}%</div><div class="md"><div class="t">${r[2]}</div><div class="s">${r[0]===100?'Title: COLLECTOR. ':''}Find ${need} of ${b}  (${Math.min(a,need)}/${need})</div></div></div>`);
    btn(row, {cls: ok ? 'b-green' : 'b-grey', label: ok ? 'CLAIM' : 'LOCKED', icon: ok ? '' : '<span style="width:22px;height:22px;display:inline-block">'+ICO.lock+'</span>', onClick:() => { if(!ok){ SFX.err(); return; } SFX.chest(); }}).classList.add('mb');
  });
  m.addEventListener('click', e => { if(e.target === m){ SFX.close(); m.remove(); } });
}

/* ================================================================== small fx: stars / coins bursting out of an element */
const FX = [];
function burstAt(node, kind, n){
  n = n || 12; const r = node.getBoundingClientRect(), s = UI.s;
  const cx = (r.left + r.width/2)/s, cy = (r.top + r.height/2)/s;
  for(let i=0;i<n;i++){
    const d = el(ui, `<div class="coinfx">${kind==='coin'?ICO.coin:ICO.starOn}</div>`);
    const a = -Math.PI/2 + (Math.random()-.5)*2.4, sp = 260 + Math.random()*320;
    FX.push({d, x:cx-17, y:cy-17, vx:Math.cos(a)*sp, vy:Math.sin(a)*sp, life:0, max:.9+Math.random()*.4, rot:Math.random()*360, vr:(Math.random()-.5)*720, kind, i});
  }
}
function stepFx(dt){
  for(let i=FX.length-1;i>=0;i--){ const f = FX[i]; f.life += dt; f.vy += 900*dt; f.x += f.vx*dt; f.y += f.vy*dt; f.rot += f.vr*dt;
    const u = f.life/f.max; f.d.style.transform = `translate(${f.x}px,${f.y}px) rotate(${f.rot}deg) scale(${(1-u*.5)*(f.kind==='coin'?1:.8)})`; f.d.style.opacity = u > .7 ? (1-u)/.3 : 1;
    if(f.kind === 'coin' && f.life - dt < .12*((f.i%5)+1) && f.life >= .12*((f.i%5)+1) && f.i < 5) SFX.coin(f.i);
    if(u >= 1){ f.d.remove(); FX.splice(i,1); } }
}
function scrollbars(){
  [WB, WI].forEach(w => { if(!w || w.classList.contains('hide')) return; const sc = w.scrollEl, sb = w.sbar, th = sb.firstElementChild;
    const H = sc.clientHeight, full = sc.scrollHeight; const tr = sb.clientHeight; if(full <= H + 2){ sb.style.visibility = 'hidden'; return; } sb.style.visibility = 'visible';
    const th_h = Math.max(46, tr*H/full); th.style.height = th_h+'px'; th.style.top = ((tr - th_h)*sc.scrollTop/(full-H))+'px'; });
}

/* ================================================================== open / close / swap */
function showWin(w, anim){
  [WB, WI].forEach(o => { if(o !== w) o.classList.add('hide'); });
  w.classList.remove('hide'); w.place();
  if(w === WB) { fillGrid(); fillDetail(); } else fillIndex();
  $('#hudbtns') && ($('#hudbtns').style.display = 'none');
  $('#dim').style.opacity = 1;
  if(anim){ w.style.setProperty('--tx','0px'); w.style.setProperty('--ty','0px'); w.style.animation = 'none'; void w.offsetWidth; w.style.animation = 'winin .34s cubic-bezier(.3,1.5,.5,1)'; SFX.open(); }
  $('#dBal').classList.toggle('on', w === WB); $('#dIdx').classList.toggle('on', w === WI);
}
function swapTo(w){ closePop(); SFX.click(); showWin(w, true); }
function closeWin(w){
  closePop(); SFX.close(); w.style.animation = 'winout .2s ease-in forwards';
  setTimeout(() => { w.classList.add('hide'); w.style.animation = ''; $('#hudbtns').style.display = 'flex'; $('#dim').style.opacity = 0; }, 200);
}
function hudButtons(){
  const h = el(ui, `<div id="hudbtns" style="display:none"></div>`);
  [['BALLOONS','b-blue',() => showWin(WB, true)],['INDEX','b-green',() => showWin(WI, true)]].forEach(b => {
    const n = btn(h, {cls:b[1], label:b[0], w:200, h:84, fs:30, onClick:b[2]}); });
}

/* ================================================================== boot */
function boot(){
  WB = buildBalloonsWin(); WI = buildIndexWin(); hudButtons();
  layout(); drawBackground(); showWin(WB, false);
  window.addEventListener('resize', () => { layout(); });
  $('#dBal').onclick = () => showWin(WB, true); $('#dIdx').onclick = () => showWin(WI, true);
  $('#dSnd').onclick = () => { S.sound = !S.sound; $('#dSnd').textContent = 'Sound: '+(S.sound?'on':'off'); };
  requestAnimationFrame(loop);
}
function exportObj(root){
  root.updateMatrixWorld(true);
  const out = []; const P = new T.Vector3(), Q = new T.Quaternion(), Sc = new T.Vector3(), M = new T.Matrix4();
  function walk(o, path){
    if(o.isInstancedMesh || o.isLight) return;
    if(o.isMesh && o.visible !== false){
      o.matrixWorld.decompose(P, Q, Sc); M.makeRotationFromQuaternion(Q); const e = M.elements;
      let shape = o.geometry === wedgeGeo ? 'Wedge' : o.geometry === geo.sph ? 'Ball' : o.geometry === geo.cyl ? 'Cylinder' : o.geometry === geo.box ? 'Block' : 'Other';
      if(shape === 'Other') return;
      let size = [Sc.x, Sc.y, Sc.z]; let R = [e[0],e[4],e[8], e[1],e[5],e[9], e[2],e[6],e[10]];
      if(shape === 'Ball'){ const d = Math.max(Sc.x,Sc.y,Sc.z)*2; size = [d,d,d]; }
      if(shape === 'Cylinder'){ // three: axis Y, radius scale.x; Roblox: axis X
        const rz = new T.Matrix4().makeRotationZ(Math.PI/2); const m2 = new T.Matrix4().makeRotationFromQuaternion(Q).multiply(rz); const f = m2.elements;
        R = [f[0],f[4],f[8], f[1],f[5],f[9], f[2],f[6],f[10]]; size = [Sc.y, Sc.x*2, Sc.z*2]; }
      const m = o.material; const col = '#'+m.color.getHexString();
      const mat = m.emissive && m.emissiveIntensity >= .5 && m.emissive.getHex() ? 'Neon' : (m.metalness > .2 ? 'Metal' : (m.roughness < .4 ? 'SmoothPlastic' : 'Plastic'));
      out.push({path, shape, pos:[P.x,P.y,P.z], R, size, color:col, mat, transp: m.transparent ? +(1-m.opacity).toFixed(2) : 0});
    }
    o.children.forEach(c => walk(c, o.userData.ename ? path.concat(o.userData.ename) : path));
  }
  walk(root, []); return out;
}
window.__debug = {
  S, B, showWin:k => showWin(k === 'index' ? WI : WB, false), tab:k => { S.itab = k; fillIndex(); }, btab:k => { S.btab = k; fillGrid(); },
  select, scroll:(y) => { const w = WB.classList.contains('hide') ? WI : WB; w.scrollEl.scrollTop = y; },
  advance(sec){ FROZEN = true; const st = 1/30; for(let t=0;t<sec;t+=st){ clock += st; renderViews(st); stepFx(st); } scrollbars(); },
  freeze(f){ FROZEN = f; }, claimFirst(){ const ch = document.querySelector('.chest.ready'); if(ch) ch.querySelector('.btn').click(); },
  pop(i){ const cs = document.querySelectorAll('.icard'); cs[i||0].click(); },
  exportModels(){ const res = {};
    ZONES.forEach(z => res['Zone_'+z.id.replace(/ /g,'')] = exportObj(buildZone(z.id)));
    Object.keys(FUTURE).forEach(k => res['Enemy_'+k.replace(/ /g,'')] = exportObj(FUTURE[k]()));
    const ch = buildChest(); ch.userData.set('claimed'); const u = ch.userData; u.lid.userData.ename = 'Lid'; u.lock.userData.ename = 'Lock'; u.coins.userData.ename = 'Coins';
    res.Chest = exportObj(ch); res.Chest_hinge = [u.lid.position.x, u.lid.position.y, u.lid.position.z];
    res.IndexBook = exportObj(buildBook());
    return res; }, rewards:openRewards, equip:n => { const c = document.querySelector(`.card[data-n="${n}"]`); onCardBtn(n, c); },
};
document.fonts.load('40px "Fredoka One"').then(boot, boot);
