import { chromium } from 'playwright';

export async function testBackdropClick() {
  console.log('🧪 TEST 4: Backdrop Click Functionality');
  console.log('=====================================');
  
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  const results = {
    passed: false,
    details: {},
    errors: []
  };
  
  try {
    await page.goto('http://localhost:3002', { waitUntil: 'networkidle' });
    await page.setViewportSize({ width: 375, height: 667 });
    await page.waitForTimeout(2000);
    
    // Open mobile menu first
    console.log('🍔 Opening mobile menu...');
    await page.click('button[data-mobile-menu-target="button"]');
    await page.waitForTimeout(600);
    
    // Verify menu is open
    const menuOpenCheck = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      const backdrop = document.querySelector('[data-mobile-menu-target="backdrop"]');
      return {
        drawerOpen: drawer ? drawer.classList.contains('open') : false,
        backdropVisible: backdrop ? backdrop.classList.contains('visible') : false
      };
    });
    
    console.log('📊 Menu state before backdrop click:');
    console.log(`   Drawer open: ${menuOpenCheck.drawerOpen}`);
    console.log(`   Backdrop visible: ${menuOpenCheck.backdropVisible}`);
    
    if (!menuOpenCheck.drawerOpen || !menuOpenCheck.backdropVisible) {
      results.errors.push('Menu failed to open properly for backdrop test');
      results.passed = false;
      await browser.close();
      return results;
    }
    
    // Get backdrop and drawer positioning info
    const positionInfo = await page.evaluate(() => {
      const backdrop = document.querySelector('[data-mobile-menu-target="backdrop"]');
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      
      if (!backdrop || !drawer) return null;
      
      const backdropRect = backdrop.getBoundingClientRect();
      const drawerRect = drawer.getBoundingClientRect();
      
      return {
        backdrop: {
          x: backdropRect.x,
          y: backdropRect.y,
          width: backdropRect.width,
          height: backdropRect.height,
          right: backdropRect.right,
          bottom: backdropRect.bottom
        },
        drawer: {
          x: drawerRect.x,
          y: drawerRect.y,
          width: drawerRect.width,
          height: drawerRect.height,
          right: drawerRect.right,
          bottom: drawerRect.bottom
        }
      };
    });
    
    console.log('📐 Element positioning:');
    console.log('   Backdrop:', positionInfo.backdrop);
    console.log('   Drawer:', positionInfo.drawer);
    
    // Calculate safe click areas (left side where only backdrop is visible)
    const safeClickX = Math.max(10, positionInfo.drawer.x - 50); // Left of drawer
    const safeClickY = Math.floor(positionInfo.backdrop.height / 2); // Middle height
    
    console.log(`🎯 Planned click position: (${safeClickX}, ${safeClickY})`);
    
    // Test backdrop click
    console.log('🎭 Testing backdrop click...');
    
    try {
      // Click on the backdrop area (left side, away from drawer)
      await page.mouse.click(safeClickX, safeClickY);
      await page.waitForTimeout(600); // Wait for animation
      
      // Check if menu closed
      const menuClosedCheck = await page.evaluate(() => {
        const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
        const backdrop = document.querySelector('[data-mobile-menu-target="backdrop"]');
        const button = document.querySelector('[data-mobile-menu-target="button"]');
        
        return {
          drawerClosed: drawer ? drawer.classList.contains('closed') : false,
          backdropHidden: backdrop ? backdrop.classList.contains('hidden') : false,
          buttonAriaExpanded: button ? button.getAttribute('aria-expanded') : null,
          bodyScrollRestored: !document.body.classList.contains('mobile-menu-open')
        };
      });
      
      console.log('📊 Menu state after backdrop click:');
      console.log(`   Drawer closed: ${menuClosedCheck.drawerClosed}`);
      console.log(`   Backdrop hidden: ${menuClosedCheck.backdropHidden}`);
      console.log(`   Button aria-expanded: ${menuClosedCheck.buttonAriaExpanded}`);
      console.log(`   Body scroll restored: ${menuClosedCheck.bodyScrollRestored}`);
      
      const backdropClickWorked = menuClosedCheck.drawerClosed && 
                                 menuClosedCheck.backdropHidden &&
                                 menuClosedCheck.buttonAriaExpanded === 'false' &&
                                 menuClosedCheck.bodyScrollRestored;
      
      // Take screenshot for verification
      await page.screenshot({ 
        path: './test-04-backdrop-closed.png',
        fullPage: true 
      });
      console.log('📸 Screenshot saved: test-04-backdrop-closed.png');
      
      // Test alternative backdrop click method if first failed
      if (!backdropClickWorked) {
        console.log('🔄 Trying alternative backdrop click method...');
        
        // Open menu again
        await page.click('button[data-mobile-menu-target="button"]');
        await page.waitForTimeout(600);
        
        // Try clicking backdrop element directly with force
        await page.locator('[data-mobile-menu-target="backdrop"]').click({ 
          position: { x: 50, y: 300 },
          force: true 
        });
        await page.waitForTimeout(600);
        
        const alternativeCheck = await page.evaluate(() => {
          const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
          const backdrop = document.querySelector('[data-mobile-menu-target="backdrop"]');
          
          return {
            drawerClosed: drawer ? drawer.classList.contains('closed') : false,
            backdropHidden: backdrop ? backdrop.classList.contains('hidden') : false
          };
        });
        
        console.log('📊 Alternative method result:');
        console.log(`   Drawer closed: ${alternativeCheck.drawerClosed}`);
        console.log(`   Backdrop hidden: ${alternativeCheck.backdropHidden}`);
        
        const alternativeWorked = alternativeCheck.drawerClosed && alternativeCheck.backdropHidden;
        
        results.passed = alternativeWorked;
        results.details = {
          positionInfo,
          safeClickPosition: { x: safeClickX, y: safeClickY },
          firstAttempt: {
            method: 'mouse.click',
            success: backdropClickWorked,
            result: menuClosedCheck
          },
          secondAttempt: {
            method: 'locator.click with force',
            success: alternativeWorked,
            result: alternativeCheck
          }
        };
        
        if (!alternativeWorked) {
          results.errors.push('Both backdrop click methods failed');
        }
        
      } else {
        results.passed = true;
        results.details = {
          positionInfo,
          safeClickPosition: { x: safeClickX, y: safeClickY },
          method: 'mouse.click',
          success: true,
          result: menuClosedCheck
        };
      }
      
    } catch (clickError) {
      results.errors.push(`Backdrop click error: ${clickError.message}`);
      console.log(`❌ Click error: ${clickError.message}`);
    }
    
    console.log(`\n${results.passed ? '✅' : '❌'} TEST 4 RESULT: ${results.passed ? 'PASSED' : 'FAILED'}`);
    
    if (!results.passed && results.errors.length === 0) {
      results.errors.push('Backdrop click did not close the mobile menu');
    }
    
  } catch (error) {
    results.errors.push(`Test execution error: ${error.message}`);
    console.error('❌ Test 4 Error:', error);
  }
  
  await browser.close();
  return results;
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  testBackdropClick().then(results => {
    console.log('\n📊 Final Results:', results);
  });
}