import { chromium } from 'playwright';

(async () => {
  console.log('🔍 Debugging bottom navigation...');
  
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  try {
    await page.goto('http://localhost:3002', { waitUntil: 'networkidle' });
    await page.setViewportSize({ width: 375, height: 667 });
    await page.waitForTimeout(2000);
    
    // Check if bottom nav exists in DOM
    const bottomNavInfo = await page.evaluate(() => {
      const bottomNav = document.querySelector('.bottom-nav');
      if (bottomNav) {
        const rect = bottomNav.getBoundingClientRect();
        const styles = window.getComputedStyle(bottomNav);
        
        return {
          exists: true,
          classes: bottomNav.className,
          rect: {
            x: rect.x,
            y: rect.y,
            width: rect.width,
            height: rect.height,
            bottom: rect.bottom
          },
          styles: {
            display: styles.display,
            position: styles.position,
            bottom: styles.bottom,
            visibility: styles.visibility,
            opacity: styles.opacity,
            zIndex: styles.zIndex
          },
          offsetParent: !!bottomNav.offsetParent,
          innerHTML: bottomNav.innerHTML.substring(0, 200) + '...'
        };
      }
      return { exists: false };
    });
    
    console.log('📱 Bottom navigation analysis:');
    console.log('   Exists:', bottomNavInfo.exists);
    
    if (bottomNavInfo.exists) {
      console.log('   Classes:', bottomNavInfo.classes);
      console.log('   Display:', bottomNavInfo.styles.display);
      console.log('   Position:', bottomNavInfo.styles.position);
      console.log('   Bottom:', bottomNavInfo.styles.bottom);
      console.log('   Visibility:', bottomNavInfo.styles.visibility);
      console.log('   Opacity:', bottomNavInfo.styles.opacity);
      console.log('   Z-index:', bottomNavInfo.styles.zIndex);
      console.log('   Has offsetParent:', bottomNavInfo.offsetParent);
      console.log('   Position:', bottomNavInfo.rect);
    }
    
    // Check CSS media queries
    const mediaQueryInfo = await page.evaluate(() => {
      // Check if CSS rules are applying correctly
      const bottomNav = document.querySelector('.bottom-nav');
      if (!bottomNav) return null;
      
      const viewportWidth = window.innerWidth;
      const matchesMedia = window.matchMedia('(max-width: 767px)').matches;
      const matchesDesktopMedia = window.matchMedia('(min-width: 768px)').matches;
      
      return {
        viewportWidth,
        matchesMobileMedia: matchesMedia,
        matchesDesktopMedia,
        shouldBeVisible: viewportWidth < 768
      };
    });
    
    console.log('   Media query info:');
    console.log('     Viewport width:', mediaQueryInfo.viewportWidth);
    console.log('     Matches mobile media:', mediaQueryInfo.matchesMobileMedia);
    console.log('     Matches desktop media:', mediaQueryInfo.matchesDesktopMedia);
    console.log('     Should be visible:', mediaQueryInfo.shouldBeVisible);
    
    // Take screenshot for visual inspection
    await page.screenshot({ 
      path: './debug-bottom-nav.png',
      fullPage: true 
    });
    console.log('📸 Screenshot saved: debug-bottom-nav.png');
    
    // Check if main content has proper padding
    const mainPaddingInfo = await page.evaluate(() => {
      const main = document.querySelector('main');
      if (main) {
        const styles = window.getComputedStyle(main);
        return {
          paddingBottom: styles.paddingBottom,
          marginBottom: styles.marginBottom
        };
      }
      return null;
    });
    
    console.log('   Main element padding:');
    console.log('     Padding bottom:', mainPaddingInfo?.paddingBottom);
    console.log('     Margin bottom:', mainPaddingInfo?.marginBottom);
    
  } catch (error) {
    console.error('❌ Debug error:', error);
  }
  
  await browser.close();
})();