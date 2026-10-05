const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 4000, height: 1200 }, deviceScaleFactor: 1 });
  await p.goto('file://' + __dirname + '/mock.html');
  await p.evaluate(async () => { await document.fonts.ready; await document.fonts.load('40px "Fredoka One"'); window.runFits(); });
  await p.waitForTimeout(300);
  for (const id of ['shop', 'index1', 'index2']) {
    await p.locator('#' + id).screenshot({ path: id + '.png' });
  }
  await b.close();
})();
