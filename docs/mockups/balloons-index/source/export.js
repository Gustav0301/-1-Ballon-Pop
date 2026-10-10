const { chromium } = require('playwright'); const fs = require('fs');
(async()=>{ const b = await chromium.launch({args:['--use-gl=swiftshader','--enable-unsafe-swiftshader']});
const p = await b.newPage({viewport:{width:1280,height:800}}); p.on('pageerror',e=>console.log('ERR',e.stack));
await p.goto('file://'+__dirname+'/index.html'); await p.waitForTimeout(1500);
const r = await p.evaluate(()=>__debug.exportModels()); fs.writeFileSync(__dirname+'/out/models.json', JSON.stringify(r));
for(const k in r) if(Array.isArray(r[k])) console.log(k, r[k].length);
await b.close(); })();
