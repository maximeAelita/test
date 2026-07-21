// Rasterizes icon.html into the PNG sizes iOS and Steam want.
// Usage: node make-icons.js   (requires playwright + a Chromium at CHROME env or the default path)
const { chromium } = require('playwright');
const path = require('path');

const SIZES = [1024, 512, 256, 180, 167, 152, 120, 76, 64, 32];
const CHROME = process.env.CHROME || '/opt/pw-browsers/chromium-1194/chrome-linux/chrome';

(async () => {
  const browser = await chromium.launch({ executablePath: CHROME });
  const url = 'file://' + path.join(__dirname, 'icon.html');
  for (const s of SIZES) {
    const page = await browser.newPage({ viewport: { width: s, height: s }, deviceScaleFactor: 1 });
    await page.goto(url + '?s=' + s);
    await page.waitForFunction(() => window.__ready === true);
    await page.locator('#c').screenshot({ path: path.join(__dirname, 'icon-' + s + '.png') });
    await page.close();
    console.log('wrote icon-' + s + '.png');
  }
  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
