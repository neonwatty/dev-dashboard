import { chromium } from 'playwright';

export async function testEscapeKey() {
  console.log('🧪 TEST 5: ESC Key Functionality');
  console.log('===============================');
  
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
    
    // Test 1: ESC key closes menu
    console.log('🍔 Opening mobile menu for ESC test...');
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
    
    console.log('📊 Menu state before ESC:');
    console.log(`   Drawer open: ${menuOpenCheck.drawerOpen}`);
    console.log(`   Backdrop visible: ${menuOpenCheck.backdropVisible}`);
    
    if (!menuOpenCheck.drawerOpen || !menuOpenCheck.backdropVisible) {
      results.errors.push('Menu failed to open for ESC key test');
      results.passed = false;
      await browser.close();
      return results;
    }
    
    // Press ESC key
    console.log('⌨️ Pressing ESC key...');
    await page.keyboard.press('Escape');
    await page.waitForTimeout(600); // Wait for animation
    
    // Check if menu closed
    const escapeCloseCheck = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      const backdrop = document.querySelector('[data-mobile-menu-target="backdrop"]');
      const button = document.querySelector('[data-mobile-menu-target="button"]');
      const hamburger = document.querySelector('[data-mobile-menu-target="hamburger"]');
      
      return {
        drawerClosed: drawer ? drawer.classList.contains('closed') : false,
        backdropHidden: backdrop ? backdrop.classList.contains('hidden') : false,
        buttonAriaExpanded: button ? button.getAttribute('aria-expanded') : null,
        hamburgerReset: hamburger ? !hamburger.classList.contains('open') : false,
        bodyScrollRestored: !document.body.classList.contains('mobile-menu-open'),
        focusReturned: document.activeElement === button
      };
    });
    
    console.log('📊 Menu state after ESC:');
    console.log(`   Drawer closed: ${escapeCloseCheck.drawerClosed}`);
    console.log(`   Backdrop hidden: ${escapeCloseCheck.backdropHidden}`);
    console.log(`   Button aria-expanded: ${escapeCloseCheck.buttonAriaExpanded}`);
    console.log(`   Hamburger reset: ${escapeCloseCheck.hamburgerReset}`);
    console.log(`   Body scroll restored: ${escapeCloseCheck.bodyScrollRestored}`);
    console.log(`   Focus returned: ${escapeCloseCheck.focusReturned}`);
    
    const escapeKeyWorked = escapeCloseCheck.drawerClosed && 
                           escapeCloseCheck.backdropHidden &&
                           escapeCloseCheck.buttonAriaExpanded === 'false' &&
                           escapeCloseCheck.hamburgerReset &&
                           escapeCloseCheck.bodyScrollRestored;
    
    // Test 2: ESC key doesn't close when menu is already closed
    console.log('\n⌨️ Testing ESC key when menu is closed...');
    await page.keyboard.press('Escape');
    await page.waitForTimeout(300);
    
    const noEffectCheck = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      const backdrop = document.querySelector('[data-mobile-menu-target="backdrop"]');
      
      return {
        drawerStillClosed: drawer ? drawer.classList.contains('closed') : false,
        backdropStillHidden: backdrop ? backdrop.classList.contains('hidden') : false
      };
    });
    
    console.log('📊 State after ESC on closed menu:');
    console.log(`   Drawer still closed: ${noEffectCheck.drawerStillClosed}`);
    console.log(`   Backdrop still hidden: ${noEffectCheck.backdropStillHidden}`);
    
    const noUnwantedEffect = noEffectCheck.drawerStillClosed && noEffectCheck.backdropStillHidden;
    
    // Test 3: Focus management during ESC
    console.log('\n🎯 Testing focus management with ESC...');
    await page.click('button[data-mobile-menu-target="button"]'); // Open menu
    await page.waitForTimeout(600);
    
    // Check focus is trapped in menu
    const focusBeforeEsc = await page.evaluate(() => {
      return {
        activeElementTag: document.activeElement ? document.activeElement.tagName : null,
        activeElementClass: document.activeElement ? document.activeElement.className : null,
        isInDrawer: document.activeElement ? 
          document.querySelector('[data-mobile-menu-target="drawer"]').contains(document.activeElement) : false
      };
    });
    
    console.log('🎯 Focus before ESC:');
    console.log(`   Active element: ${focusBeforeEsc.activeElementTag}`);
    console.log(`   Element class: ${focusBeforeEsc.activeElementClass}`);
    console.log(`   Focus in drawer: ${focusBeforeEsc.isInDrawer}`);
    
    await page.keyboard.press('Escape');
    await page.waitForTimeout(600);
    
    const focusAfterEsc = await page.evaluate(() => {
      const button = document.querySelector('[data-mobile-menu-target="button"]');
      return {
        activeElementTag: document.activeElement ? document.activeElement.tagName : null,
        focusReturnedToButton: document.activeElement === button,
        buttonHasFocus: button === document.activeElement
      };
    });
    
    console.log('🎯 Focus after ESC:');
    console.log(`   Active element: ${focusAfterEsc.activeElementTag}`);
    console.log(`   Focus returned to button: ${focusAfterEsc.focusReturnedToButton}`);
    
    // Take screenshot for verification
    await page.screenshot({ 
      path: './test-05-escape-closed.png',
      fullPage: true 
    });
    console.log('📸 Screenshot saved: test-05-escape-closed.png');
    
    // Determine overall test result
    const testPassed = escapeKeyWorked && noUnwantedEffect && focusAfterEsc.focusReturnedToButton;
    
    results.passed = testPassed;
    results.details = {
      escapeKeyClose: {
        worked: escapeKeyWorked,
        result: escapeCloseCheck
      },
      noUnwantedEffect: {
        worked: noUnwantedEffect,
        result: noEffectCheck
      },
      focusManagement: {
        beforeEsc: focusBeforeEsc,
        afterEsc: focusAfterEsc,
        focusReturned: focusAfterEsc.focusReturnedToButton
      }
    };
    
    console.log(`\n📊 ESC Key Test Summary:`);
    console.log(`   ESC closes menu: ${escapeKeyWorked ? '✅' : '❌'}`);
    console.log(`   No effect when closed: ${noUnwantedEffect ? '✅' : '❌'}`);
    console.log(`   Focus management: ${focusAfterEsc.focusReturnedToButton ? '✅' : '❌'}`);
    
    console.log(`\n${testPassed ? '✅' : '❌'} TEST 5 RESULT: ${testPassed ? 'PASSED' : 'FAILED'}`);
    
    if (!testPassed) {
      if (!escapeKeyWorked) {
        results.errors.push('ESC key does not close the mobile menu');
      }
      if (!noUnwantedEffect) {
        results.errors.push('ESC key has unwanted effects when menu is closed');
      }
      if (!focusAfterEsc.focusReturnedToButton) {
        results.errors.push('Focus is not returned to hamburger button after ESC');
      }
    }
    
  } catch (error) {
    results.errors.push(`Test execution error: ${error.message}`);
    console.error('❌ Test 5 Error:', error);
  }
  
  await browser.close();
  return results;
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  testEscapeKey().then(results => {
    console.log('\n📊 Final Results:', results);
  });
}