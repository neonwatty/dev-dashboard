import { chromium } from 'playwright';

(async () => {
  console.log('🔍 Testing mobile menu functionality directly...');
  
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  try {
    await page.goto('http://localhost:3002', { waitUntil: 'networkidle' });
    await page.setViewportSize({ width: 375, height: 667 });
    await page.waitForTimeout(3000);
    
    console.log('📱 Taking screenshot before click...');
    await page.screenshot({ path: './before-click.png', fullPage: true });
    
    // Get initial state
    const beforeClick = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      const backdrop = document.querySelector('[data-mobile-menu-target="backdrop"]');
      const hamburger = document.querySelector('[data-mobile-menu-target="hamburger"]');
      
      return {
        drawerClasses: drawer ? drawer.className : 'not found',
        backdropClasses: backdrop ? backdrop.className : 'not found',
        hamburgerClasses: hamburger ? hamburger.className : 'not found'
      };
    });
    
    console.log('🎯 Before click state:');
    console.log('   Drawer classes:', beforeClick.drawerClasses);
    console.log('   Backdrop classes:', beforeClick.backdropClasses);
    console.log('   Hamburger classes:', beforeClick.hamburgerClasses);
    
    // Click the hamburger button
    console.log('🍔 Clicking hamburger button...');
    await page.click('button[data-mobile-menu-target="button"]');
    await page.waitForTimeout(1000); // Wait for animations
    
    console.log('📱 Taking screenshot after click...');
    await page.screenshot({ path: './after-click.png', fullPage: true });
    
    // Get state after click
    const afterClick = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      const backdrop = document.querySelector('[data-mobile-menu-target="backdrop"]');
      const hamburger = document.querySelector('[data-mobile-menu-target="hamburger"]');
      
      return {
        drawerClasses: drawer ? drawer.className : 'not found',
        backdropClasses: backdrop ? backdrop.className : 'not found',  
        hamburgerClasses: hamburger ? hamburger.className : 'not found'
      };
    });
    
    console.log('🎯 After click state:');
    console.log('   Drawer classes:', afterClick.drawerClasses);
    console.log('   Backdrop classes:', afterClick.backdropClasses);
    console.log('   Hamburger classes:', afterClick.hamburgerClasses);
    
    // Check if classes changed
    const drawerChanged = beforeClick.drawerClasses !== afterClick.drawerClasses;
    const backdropChanged = beforeClick.backdropClasses !== afterClick.backdropClasses;
    const hamburgerChanged = beforeClick.hamburgerClasses !== afterClick.hamburgerClasses;
    
    console.log('📊 Changes detected:');
    console.log('   Drawer changed:', drawerChanged);
    console.log('   Backdrop changed:', backdropChanged);
    console.log('   Hamburger changed:', hamburgerChanged);
    
    // Try to access the controller directly
    const controllerAccess = await page.evaluate(() => {
      const nav = document.querySelector('[data-controller="mobile-menu"]');
      if (nav) {
        // Try different ways to access the controller
        const ways = {
          mobileMenuController: nav.mobileMenuController,
          'mobile-menuController': nav['mobile-menuController'],
          stimulus: nav.stimulus,
          controller: nav.controller
        };
        
        // Check Stimulus application
        let stimulusInfo = {};
        if (window.Stimulus) {
          stimulusInfo = {
            hasApplication: !!window.Stimulus.application,
            debug: window.Stimulus.debug,
            start: typeof window.Stimulus.start === 'function'
          };
        }
        
        return {
          elementFound: true,
          ways: ways,
          stimulusInfo: stimulusInfo
        };
      }
      return { elementFound: false };
    });
    
    console.log('🎮 Controller access:');
    console.log('   Element found:', controllerAccess.elementFound);
    if (controllerAccess.elementFound) {
      console.log('   Access methods:', controllerAccess.ways);
      console.log('   Stimulus info:', controllerAccess.stimulusInfo);
    }
    
  } catch (error) {
    console.error('❌ Test error:', error);
  }
  
  await browser.close();
})();