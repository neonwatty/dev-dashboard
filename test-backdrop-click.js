import { chromium } from 'playwright';

(async () => {
  console.log('🧪 Testing backdrop click fix...');
  
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  try {
    await page.goto('http://localhost:3002', { waitUntil: 'networkidle' });
    await page.setViewportSize({ width: 375, height: 667 });
    await page.waitForTimeout(2000);
    
    console.log('🍔 Opening mobile menu...');
    await page.click('button[data-mobile-menu-target="button"]');
    await page.waitForTimeout(500);
    
    // Check that menu is open
    const menuOpen = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      return drawer ? drawer.classList.contains('open') : false;
    });
    
    console.log(`📱 Menu open: ${menuOpen}`);
    
    if (menuOpen) {
      console.log('🎭 Testing backdrop click on left side (away from drawer)...');
      
      // Click on the left side of the screen where only backdrop is visible
      // Drawer is on right side, so click on left side at coordinates (50, 300)
      await page.click('body', { position: { x: 50, y: 300 } });
      await page.waitForTimeout(500);
      
      // Check if menu closed
      const menuClosed = await page.evaluate(() => {
        const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
        const backdrop = document.querySelector('[data-mobile-menu-target="backdrop"]');
        return {
          drawerClosed: drawer ? drawer.classList.contains('closed') : false,
          backdropHidden: backdrop ? backdrop.classList.contains('hidden') : false
        };
      });
      
      const success = menuClosed.drawerClosed && menuClosed.backdropHidden;
      console.log(`${success ? '✅' : '❌'} Backdrop click closes menu: ${success}`);
      console.log('   Drawer closed:', menuClosed.drawerClosed);
      console.log('   Backdrop hidden:', menuClosed.backdropHidden);
      
      if (success) {
        console.log('🎉 Backdrop click is working correctly!');
        
        // Test ESC key too
        console.log('⌨️ Testing ESC key...');
        await page.click('button[data-mobile-menu-target="button"]'); // Open again
        await page.waitForTimeout(500);
        await page.keyboard.press('Escape');
        await page.waitForTimeout(500);
        
        const escClosed = await page.evaluate(() => {
          const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
          return drawer ? drawer.classList.contains('closed') : false;
        });
        
        console.log(`${escClosed ? '✅' : '❌'} ESC key closes menu: ${escClosed}`);
        
        if (escClosed) {
          console.log('🎉 ALL MOBILE MENU FUNCTIONALITY IS WORKING!');
        }
      }
    }
    
  } catch (error) {
    console.error('❌ Test error:', error);
  }
  
  await browser.close();
})();