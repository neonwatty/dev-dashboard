import { chromium } from 'playwright';

(async () => {
  console.log('🎉 FINAL COMPREHENSIVE MOBILE MENU TEST');
  console.log('=====================================');
  
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  const testResults = {
    controllerScope: false,
    menuOpens: false,
    backdropClick: false,
    escapeKey: false,
    navigationLinks: false,
    accessibility: false,
    responsiveBehavior: false,
    noConflicts: false
  };
  
  try {
    console.log('🌐 Loading application...');
    await page.goto('http://localhost:3002', { waitUntil: 'networkidle' });
    await page.waitForTimeout(2000);
    
    // Test 1: Controller scope and connection
    console.log('\n📋 Test 1: Controller Scope');
    await page.setViewportSize({ width: 375, height: 667 });
    await page.waitForTimeout(1000);
    
    const scopeCheck = await page.evaluate(() => {
      const body = document.querySelector('body[data-controller="mobile-menu"]');
      const button = document.querySelector('[data-mobile-menu-target="button"]');
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      const backdrop = document.querySelector('[data-mobile-menu-target="backdrop"]');
      
      return {
        controllerOnBody: !!body,
        allTargetsExist: !!(button && drawer && backdrop)
      };
    });
    
    testResults.controllerScope = scopeCheck.controllerOnBody && scopeCheck.allTargetsExist;
    console.log(`${testResults.controllerScope ? '✅' : '❌'} Controller scope correct: ${testResults.controllerScope}`);
    
    // Test 2: Menu opening functionality
    console.log('\n📋 Test 2: Menu Opening');
    await page.click('button[data-mobile-menu-target="button"]');
    await page.waitForTimeout(500);
    
    const openState = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      const backdrop = document.querySelector('[data-mobile-menu-target="backdrop"]');
      const hamburger = document.querySelector('[data-mobile-menu-target="hamburger"]');
      
      return {
        drawerOpen: drawer?.classList.contains('open'),
        backdropVisible: backdrop?.classList.contains('visible'),
        hamburgerAnimated: hamburger?.classList.contains('open')
      };
    });
    
    testResults.menuOpens = openState.drawerOpen && openState.backdropVisible && openState.hamburgerAnimated;
    console.log(`${testResults.menuOpens ? '✅' : '❌'} Menu opens correctly: ${testResults.menuOpens}`);
    
    // Test 3: Navigation links functionality
    console.log('\n📋 Test 3: Navigation Links');
    const linkCount = await page.locator('.mobile-nav-link').count();
    const linkCheck = linkCount >= 3;
    testResults.navigationLinks = linkCheck;
    console.log(`${testResults.navigationLinks ? '✅' : '❌'} Navigation links present: ${linkCount} links found`);
    
    // Test 4: Backdrop click functionality
    console.log('\n📋 Test 4: Backdrop Click');
    await page.click('body', { position: { x: 50, y: 300 } }); // Click left side away from drawer
    await page.waitForTimeout(500);
    
    const backdropCloseState = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      const backdrop = document.querySelector('[data-mobile-menu-target="backdrop"]');
      
      return {
        drawerClosed: drawer?.classList.contains('closed'),
        backdropHidden: backdrop?.classList.contains('hidden')
      };
    });
    
    testResults.backdropClick = backdropCloseState.drawerClosed && backdropCloseState.backdropHidden;
    console.log(`${testResults.backdropClick ? '✅' : '❌'} Backdrop click closes menu: ${testResults.backdropClick}`);
    
    // Test 5: ESC key functionality
    console.log('\n📋 Test 5: ESC Key');
    await page.click('button[data-mobile-menu-target="button"]'); // Open menu again
    await page.waitForTimeout(500);
    await page.keyboard.press('Escape');
    await page.waitForTimeout(500);
    
    const escapeCloseState = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      return drawer?.classList.contains('closed');
    });
    
    testResults.escapeKey = escapeCloseState;
    console.log(`${testResults.escapeKey ? '✅' : '❌'} ESC key closes menu: ${testResults.escapeKey}`);
    
    // Test 6: Accessibility features
    console.log('\n📋 Test 6: Accessibility');
    const accessibilityCheck = await page.evaluate(() => {
      const button = document.querySelector('[data-mobile-menu-target="button"]');
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      
      return {
        buttonHasAriaLabel: !!button?.getAttribute('aria-label'),
        buttonHasAriaExpanded: button?.hasAttribute('aria-expanded'),
        drawerHasRole: drawer?.getAttribute('role') === 'dialog',
        drawerHasAriaModal: drawer?.getAttribute('aria-modal') === 'true'
      };
    });
    
    const accessibilityPassed = Object.values(accessibilityCheck).every(Boolean);
    testResults.accessibility = accessibilityPassed;
    console.log(`${testResults.accessibility ? '✅' : '❌'} Accessibility features: ${testResults.accessibility}`);
    
    // Test 7: Responsive behavior
    console.log('\n📋 Test 7: Responsive Behavior');
    // Open menu on mobile first
    await page.click('button[data-mobile-menu-target="button"]');
    await page.waitForTimeout(500);
    
    // Resize to desktop
    await page.setViewportSize({ width: 1200, height: 800 });
    await page.waitForTimeout(1000);
    
    const responsiveCheck = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      const button = document.querySelector('[data-mobile-menu-target="button"]');
      
      return {
        menuClosedOnResize: drawer?.classList.contains('closed'),
        hamburgerHiddenOnDesktop: !button?.offsetParent // offsetParent is null when hidden
      };
    });
    
    testResults.responsiveBehavior = responsiveCheck.menuClosedOnResize && responsiveCheck.hamburgerHiddenOnDesktop;
    console.log(`${testResults.responsiveBehavior ? '✅' : '❌'} Responsive behavior: ${testResults.responsiveBehavior}`);
    
    // Test 8: No controller conflicts
    console.log('\n📋 Test 8: Controller Conflicts');
    const conflictCheck = await page.evaluate(() => {
      const htmlDarkMode = document.querySelector('html[data-controller="dark-mode"]');
      const bodyMobileMenu = document.querySelector('body[data-controller="mobile-menu"]');
      
      return {
        darkModeStillActive: !!htmlDarkMode,
        mobileMenuActive: !!bodyMobileMenu,
        bothWorkTogether: !!(htmlDarkMode && bodyMobileMenu)
      };
    });
    
    testResults.noConflicts = conflictCheck.bothWorkTogether;
    console.log(`${testResults.noConflicts ? '✅' : '❌'} No controller conflicts: ${testResults.noConflicts}`);
    
  } catch (error) {
    console.error('❌ Test error:', error);
  }
  
  await browser.close();
  
  // Final Results
  console.log('\n🏆 FINAL TEST RESULTS');
  console.log('=====================');
  
  const passedTests = Object.values(testResults).filter(result => result === true).length;
  const totalTests = Object.keys(testResults).length;
  const allPassed = passedTests === totalTests;
  
  console.log(`\n${allPassed ? '🎉 ALL TESTS PASSED!' : '⚠️ SOME TESTS FAILED'}`);
  console.log(`Score: ${passedTests}/${totalTests} tests passed\n`);
  
  Object.entries(testResults).forEach(([test, result], index) => {
    console.log(`${result ? '✅' : '❌'} ${index + 1}. ${test}: ${result}`);
  });
  
  if (allPassed) {
    console.log('\n🎊 MOBILE NAVIGATION FIX COMPLETE!');
    console.log('===================================');
    console.log('✅ Mobile menu opens and closes correctly');
    console.log('✅ Backdrop click functionality works');
    console.log('✅ Keyboard navigation (ESC) works');
    console.log('✅ All navigation links accessible');
    console.log('✅ Accessibility features intact');
    console.log('✅ Responsive behavior working');
    console.log('✅ No controller conflicts');
    console.log('\n🚀 Mobile users can now navigate the app successfully!');
  } else {
    console.log('\n⚠️ Issues that need attention:');
    Object.entries(testResults)
      .filter(([test, result]) => !result)
      .forEach(([test, result]) => {
        console.log(`   ❌ ${test}`);
      });
  }
})();