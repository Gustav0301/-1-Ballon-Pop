const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1280, height: 2300 }, deviceScaleFactor: 1.5 });
  p.on('console', m => console.log('console:', m.text()));
  p.on('pageerror', e => console.log('ERR', e.message));
  await p.goto('file://' + __dirname + '/feel.html');
  await p.evaluate(async () => { await document.fonts.ready; await document.fonts.load('40px "Fredoka One"'); });
  await p.waitForTimeout(400);
  for (const id of ["arrive","zone","parts"]) await p.locator('#' + id).screenshot({ path: id + '.png' });
  await b.close();
})();
