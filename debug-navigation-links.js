import { chromium } from 'playwright';

(async () => {
  console.log('🔍 Debugging navigation links visibility...');
  
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  try {
    await page.goto('http://localhost:3002', { waitUntil: 'networkidle' });
    await page.setViewportSize({ width: 375, height: 667 });
    await page.waitForTimeout(2000);
    
    // Open mobile menu
    console.log('🍔 Opening mobile menu...');
    await page.click('button[data-mobile-menu-target="button"]');
    await page.waitForTimeout(1000);
    
    // Take screenshot of open menu
    await page.screenshot({ 
      path: './debug-navigation-menu.png',
      fullPage: true 
    });
    console.log('📸 Screenshot saved: debug-navigation-menu.png');
    
    // Check drawer positioning and visibility
    const drawerInfo = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      if (drawer) {
        const rect = drawer.getBoundingClientRect();
        const styles = window.getComputedStyle(drawer);
        
        return {
          classes: drawer.className,
          rect: {
            x: rect.x,
            y: rect.y,
            width: rect.width,
            height: rect.height,
            right: rect.right,
            bottom: rect.bottom
          },
          styles: {
            position: styles.position,
            transform: styles.transform,
            zIndex: styles.zIndex,
            right: styles.right,
            top: styles.top
          },
          isVisible: drawer.offsetParent !== null
        };
      }
      return null;
    });
    
    console.log('📱 Drawer information:');
    console.log('   Classes:', drawerInfo.classes);
    console.log('   Position:', drawerInfo.rect);
    console.log('   Styles:', drawerInfo.styles);
    console.log('   Visible:', drawerInfo.isVisible);
    
    // Check navigation links positioning
    const linksInfo = await page.evaluate(() => {
      const links = Array.from(document.querySelectorAll('.mobile-nav-link'));
      return links.map((link, index) => {
        const rect = link.getBoundingClientRect();
        return {
          index: index + 1,
          text: link.textContent.trim(),
          rect: {
            x: rect.x,
            y: rect.y,
            width: rect.width,
            height: rect.height,
            right: rect.right,
            bottom: rect.bottom
          },
          visible: link.offsetParent !== null,
          inViewport: rect.x >= 0 && rect.y >= 0 && rect.right <= window.innerWidth && rect.bottom <= window.innerHeight
        };
      });
    });
    
    console.log('\n🔗 Navigation links positioning:');
    linksInfo.forEach(link => {
      console.log(`   ${link.index}. "${link.text}"`);
      console.log(`      Position: x=${link.rect.x}, y=${link.rect.y}`);
      console.log(`      Size: ${link.rect.width}x${link.rect.height}`);
      console.log(`      Visible: ${link.visible}, In viewport: ${link.inViewport}`);
    });
    
    // Test clicking links with better selectors
    console.log('\n🧪 Testing link clicks with improved selectors...');
    
    // Try clicking the Sources link specifically
    const sourcesLinkSelector = 'a[href="/sources"].mobile-nav-link';
    const sourcesExists = await page.locator(sourcesLinkSelector).count() > 0;
    
    console.log(`🔗 Sources link exists: ${sourcesExists}`);
    
    if (sourcesExists) {
      try {
        console.log('🔗 Attempting to click Sources link...');
        await page.locator(sourcesLinkSelector).first().click({ timeout: 5000 });
        await page.waitForTimeout(2000);
        
        const newUrl = page.url();
        console.log(`✅ Successfully navigated to: ${newUrl}`);
        
        // Check if we're on the sources page
        const isSourcesPage = newUrl.includes('/sources');
        console.log(`📍 On sources page: ${isSourcesPage}`);
        
      } catch (error) {
        console.log(`❌ Error clicking Sources link: ${error.message}`);
        
        // Try scrolling the drawer and clicking again
        console.log('🔄 Trying to scroll drawer content...');
        try {
          await page.locator('.mobile-nav-body').first().scroll({ x: 0, y: 100 });
          await page.waitForTimeout(500);
          await page.locator(sourcesLinkSelector).first().click({ timeout: 5000 });
          
          const newUrl2 = page.url();
          console.log(`✅ After scroll, navigated to: ${newUrl2}`);
        } catch (scrollError) {
          console.log(`❌ Scroll attempt also failed: ${scrollError.message}`);
        }
      }
    }
    
  } catch (error) {
    console.error('❌ Debug error:', error);
  }
  
  await browser.close();
})();