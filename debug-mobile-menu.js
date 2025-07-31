import { chromium } from 'playwright';

(async () => {
  console.log('🔍 Debugging mobile menu controller...');
  
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  try {
    await page.goto('http://localhost:3002', { waitUntil: 'networkidle' });
    await page.setViewportSize({ width: 375, height: 667 });
    await page.waitForTimeout(2000);
    
    // Check if all required targets exist
    console.log('🎯 Checking Stimulus targets...');
    
    const button = await page.locator('button[data-mobile-menu-target="button"]');
    const hamburger = await page.locator('[data-mobile-menu-target="hamburger"]');
    const backdrop = await page.locator('[data-mobile-menu-target="backdrop"]');
    const drawer = await page.locator('[data-mobile-menu-target="drawer"]');
    
    console.log(`🍔 Button exists: ${await button.count()}`);
    console.log(`🍔 Hamburger exists: ${await hamburger.count()}`);
    console.log(`🎭 Backdrop exists: ${await backdrop.count()}`);
    console.log(`📱 Drawer exists: ${await drawer.count()}`);
    
    if (await button.count() > 0) {
      const buttonClasses = await button.getAttribute('class');
      console.log(`🍔 Button classes: ${buttonClasses}`);
    }
    
    if (await drawer.count() > 0) {
      const drawerClasses = await drawer.getAttribute('class');
      console.log(`📱 Drawer classes: ${drawerClasses}`);
    }
    
    if (await backdrop.count() > 0) {
      const backdropClasses = await backdrop.getAttribute('class');
      console.log(`🎭 Backdrop classes: ${backdropClasses}`);
    }
    
    // Test clicking the button and check what happens
    console.log('🍔 Testing button click...');
    if (await button.count() > 0) {
      await button.click();
      await page.waitForTimeout(1000);
      
      // Check states after click
      if (await drawer.count() > 0) {
        const drawerClassesAfter = await drawer.getAttribute('class');
        console.log(`📱 Drawer classes after click: ${drawerClassesAfter}`);
      }
      
      if (await backdrop.count() > 0) {
        const backdropClassesAfter = await backdrop.getAttribute('class');
        console.log(`🎭 Backdrop classes after click: ${backdropClassesAfter}`);
      }
      
      // Check the controller state via console
      const controllerState = await page.evaluate(() => {
        const nav = document.querySelector('[data-controller="mobile-menu"]');
        if (nav && nav.mobileMenuController) {
          return nav.mobileMenuController.menuState;
        }
        return null;
      });
      
      console.log('🎮 Controller state:', controllerState);
    }
    
  } catch (error) {
    console.error('❌ Debug error:', error);
  }
  
  await browser.close();
})();