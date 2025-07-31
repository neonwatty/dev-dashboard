import { chromium } from 'playwright';

(async () => {
  console.log('🔍 Checking JavaScript loading...');
  
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  const consoleMessages = [];
  
  // Capture all console messages
  page.on('console', msg => {
    consoleMessages.push({
      type: msg.type(),
      text: msg.text(),
      timestamp: new Date().toISOString()
    });
    console.log(`📝 ${msg.type().toUpperCase()}: ${msg.text()}`);
  });
  
  // Capture JavaScript errors
  page.on('pageerror', error => {
    console.log(`❌ JavaScript Error: ${error.message}`);
  });
  
  try {
    await page.goto('http://localhost:3002', { waitUntil: 'networkidle' });
    await page.waitForTimeout(3000); // Give time for all JS to load
    
    // Check what's available on window
    const windowInfo = await page.evaluate(() => {
      return {
        hasTurbo: typeof window.Turbo !== 'undefined',
        hasStimulus: typeof window.Stimulus !== 'undefined',
        stimulusApplication: window.Stimulus ? !!window.Stimulus.application : false,
        stimulusControllers: window.Stimulus && window.Stimulus.application ? 
          window.Stimulus.application.controllers.map(c => c.identifier) : [],
        stimulusDebug: window.Stimulus ? window.Stimulus.debug : false
      };
    });
    
    console.log('🌐 Window objects:');
    console.log('   Turbo loaded:', windowInfo.hasTurbo);
    console.log('   Stimulus loaded:', windowInfo.hasStimulus);
    console.log('   Stimulus application:', windowInfo.stimulusApplication);
    console.log('   Stimulus debug:', windowInfo.stimulusDebug);
    console.log('   Controllers:', windowInfo.stimulusControllers);
    
    // Check specifically for mobile-menu controller files
    const controllerCheck = await page.evaluate(() => {
      // Try to find any elements with data-controller attributes
      const controllerElements = Array.from(document.querySelectorAll('[data-controller]'))
        .map(el => ({
          tagName: el.tagName,
          controller: el.getAttribute('data-controller'),
          className: el.className
        }));
      
      return {
        totalControllerElements: controllerElements.length,
        controllerElements: controllerElements
      };
    });
    
    console.log('🎮 Controller elements found:');
    console.log('   Total:', controllerCheck.totalControllerElements);
    controllerCheck.controllerElements.forEach((el, i) => {
      console.log(`   ${i + 1}. ${el.tagName} with data-controller="${el.controller}"`);
    });
    
  } catch (error) {
    console.error('❌ Check error:', error);
  }
  
  await browser.close();
  
  console.log('\n📋 All console messages:');
  consoleMessages.forEach((msg, i) => {
    console.log(`${i + 1}. [${msg.type}] ${msg.text}`);
  });
})();