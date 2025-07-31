import { chromium } from 'playwright';

(async () => {
  console.log('🔍 Inspecting mobile menu HTML structure...');
  
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  try {
    await page.goto('http://localhost:3002', { waitUntil: 'networkidle' });
    await page.setViewportSize({ width: 375, height: 667 });
    await page.waitForTimeout(2000);
    
    // Get the nav element HTML
    const navHTML = await page.locator('nav.mobile-header').innerHTML();
    console.log('📱 Nav HTML structure:');
    console.log(navHTML);
    
    // Check data-controller attribute specifically
    const navElement = await page.locator('nav.mobile-header');
    const dataController = await navElement.getAttribute('data-controller');
    console.log(`🎮 data-controller attribute: "${dataController}"`);
    
    // Check if Stimulus application is loaded
    const stimulusLoaded = await page.evaluate(() => {
      return typeof window.Stimulus !== 'undefined';
    });
    console.log(`⚡ Stimulus loaded: ${stimulusLoaded}`);
    
    // Check if the mobile-menu controller is registered
    const controllerRegistered = await page.evaluate(() => {
      if (window.Stimulus && window.Stimulus.application) {
        const controllers = window.Stimulus.application.controllers;
        return controllers.some(c => c.identifier === 'mobile-menu');
      }
      return false;
    });
    console.log(`📝 mobile-menu controller registered: ${controllerRegistered}`);
    
    // Get all registered controllers
    const registeredControllers = await page.evaluate(() => {
      if (window.Stimulus && window.Stimulus.application) {
        return window.Stimulus.application.controllers.map(c => c.identifier);
      }
      return [];
    });
    console.log(`📋 Registered controllers: ${registeredControllers.join(', ')}`);
    
  } catch (error) {
    console.error('❌ Inspection error:', error);
  }
  
  await browser.close();
})();