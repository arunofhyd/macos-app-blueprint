// =============================================================================
//  render_assets.js — High-DPI Vector Asset Generator (Headless Puppeteer)
//  Renders AppLogo.png (transparent) and AppIcon.png (1024x1024 squircle)
// =============================================================================
const puppeteer = require('puppeteer-core');
const fs = require('fs');

const CHROME_EXEC = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"; // or puppeteer headless shell

// 1. Transparent 1:1 Square Brand Mark (for in-app header, About modal)
const BRAND_LOGO_SVG = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="1024" height="1024">
  <defs>
    <linearGradient id="brandGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#F97316"/>
      <stop offset="100%" stop-color="#DC2626"/>
    </linearGradient>
  </defs>
  <!-- Insert vector glyph here -->
  <circle cx="256" cy="256" r="200" fill="url(#brandGrad)"/>
</svg>`;

// 2. macOS Squircle App Icon (for iconutil / Dock / Finder)
const APP_ICON_SVG = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="1024" height="1024">
  <defs>
    <linearGradient id="brandGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#F97316"/>
      <stop offset="100%" stop-color="#DC2626"/>
    </linearGradient>
  </defs>
  <rect x="16" y="16" width="480" height="480" rx="104" fill="#FFFFFF"/>
  <circle cx="256" cy="256" r="160" fill="url(#brandGrad)"/>
</svg>`;

async function renderAssets() {
    const browser = await puppeteer.launch({
        executablePath: CHROME_EXEC,
        headless: 'new',
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    const page = await browser.newPage();
    await page.setViewport({ width: 1024, height: 1024, deviceScaleFactor: 1 });

    // Render transparent AppLogo.png
    await page.setContent(`<!DOCTYPE html><html><body style="margin:0;padding:0;background:transparent;display:flex;align-items:center;justify-content:center;height:100vh;">${BRAND_LOGO_SVG}</body></html>`);
    const logoEl = await page.$('svg');
    await logoEl.screenshot({ path: 'AppLogo.png', omitBackground: true });

    // Render squircle AppIcon.png
    await page.setContent(`<!DOCTYPE html><html><body style="margin:0;padding:0;background:transparent;display:flex;align-items:center;justify-content:center;height:100vh;">${APP_ICON_SVG}</body></html>`);
    const iconEl = await page.$('svg');
    await iconEl.screenshot({ path: 'AppIcon.png', omitBackground: true });

    fs.writeFileSync('logo.svg', BRAND_LOGO_SVG);
    fs.writeFileSync('AppIcon.svg', APP_ICON_SVG);

    await browser.close();
    console.log('✅ Generated AppLogo.png, AppIcon.png, logo.svg');
}

renderAssets().catch(console.error);
