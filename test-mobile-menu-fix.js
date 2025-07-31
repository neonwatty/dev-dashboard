import { chromium } from 'playwright';

(async () => {
  console.log('🧪 Testing mobile menu fix...');
  
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  // Create screenshots directory
  const screenshotsDir = './mobile-menu-fix-screenshots';
  const fs = await import('fs');
  if (!fs.existsSync(screenshotsDir)) {
    fs.mkdirSync(screenshotsDir, { recursive: true });
  }
  
  const testResults = {
    controllerConnection: false,
    menuOpens: false,
    menuCloses: false,
    backdropClick: false,
    escapeKey: false,
    noConflicts: false
  };
  
  try {
    console.log('🌐 Navigating to localhost:3002...');
    await page.goto('http://localhost:3002', { waitUntil: 'networkidle' });
    await page.setViewportSize({ width: 375, height: 667 });
    await page.waitForTimeout(2000);
    
    console.log('📸 Taking initial screenshot...');
    await page.screenshot({ 
      path: `${screenshotsDir}/01-initial-state.png`,
      fullPage: true 
    });
    
    // Test 1: Check if controller is properly connected
    console.log('🎮 Testing controller connection...');
    const controllerConnected = await page.evaluate(() => {
      const body = document.querySelector('body[data-controller="mobile-menu"]');
      return !!body;
    });
    
    console.log(`✅ Controller attached to body: ${controllerConnected}`);
    testResults.controllerConnection = controllerConnected;
    
    // Test 2: Check initial state
    console.log('🔍 Checking initial state...');
    const initialState = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      const backdrop = document.querySelector('[data-mobile-menu-target="backdrop"]');
      const hamburger = document.querySelector('[data-mobile-menu-target="hamburger"]');
      
      return {
        drawerClasses: drawer ? drawer.className : 'not found',
        backdropClasses: backdrop ? backdrop.className : 'not found',
        hamburgerClasses: hamburger ? hamburger.className : 'not found'
      };
    });
    
    console.log('📊 Initial state:');
    console.log('   Drawer:', initialState.drawerClasses);
    console.log('   Backdrop:', initialState.backdropClasses);
    console.log('   Hamburger:', initialState.hamburgerClasses);
    
    // Test 3: Test menu opening
    console.log('🍔 Testing menu opening...');
    await page.click('button[data-mobile-menu-target="button"]');
    await page.waitForTimeout(500); // Wait for animation
    
    await page.screenshot({ 
      path: `${screenshotsDir}/02-menu-opened.png`,
      fullPage: true 
    });
    
    const openState = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      const backdrop = document.querySelector('[data-mobile-menu-target="backdrop"]');
      const hamburger = document.querySelector('[data-mobile-menu-target="hamburger"]');
      
      return {
        drawerOpen: drawer ? drawer.classList.contains('open') : false,
        backdropVisible: backdrop ? backdrop.classList.contains('visible') : false,
        hamburgerOpen: hamburger ? hamburger.classList.contains('open') : false
      };
    });
    
    console.log('📊 Open state:');
    console.log('   Drawer open:', openState.drawerOpen);
    console.log('   Backdrop visible:', openState.backdropVisible);
    console.log('   Hamburger open:', openState.hamburgerOpen);
    
    testResults.menuOpens = openState.drawerOpen && openState.backdropVisible;
    console.log(`${testResults.menuOpens ? '✅' : '❌'} Menu opens: ${testResults.menuOpens}`);
    
    // Test 4: Test backdrop click to close
    if (testResults.menuOpens) {
      console.log('🎭 Testing backdrop click to close...');
      await page.click('[data-mobile-menu-target="backdrop"]');
      await page.waitForTimeout(500);
      
      const closedState = await page.evaluate(() => {
        const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
        const backdrop = document.querySelector('[data-mobile-menu-target="backdrop"]');
        
        return {
          drawerClosed: drawer ? drawer.classList.contains('closed') : false,
          backdropHidden: backdrop ? backdrop.classList.contains('hidden') : false
        };
      });
      
      testResults.backdropClick = closedState.drawerClosed && closedState.backdropHidden;
      console.log(`${testResults.backdropClick ? '✅' : '❌'} Backdrop click closes: ${testResults.backdropClick}`);
      
      await page.screenshot({ 
        path: `${screenshotsDir}/03-backdrop-closed.png`,
        fullPage: true 
      });
    }
    
    // Test 5: Test ESC key to close
    console.log('⌨️ Testing ESC key functionality...');
    // First open the menu again
    await page.click('button[data-mobile-menu-target="button"]');
    await page.waitForTimeout(500);
    
    // Then press ESC
    await page.keyboard.press('Escape');
    await page.waitForTimeout(500);
    
    const escState = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      const backdrop = document.querySelector('[data-mobile-menu-target="backdrop"]');
      
      return {
        drawerClosed: drawer ? drawer.classList.contains('closed') : false,
        backdropHidden: backdrop ? backdrop.classList.contains('hidden') : false
      };
    });
    
    testResults.escapeKey = escState.drawerClosed && escState.backdropHidden;
    console.log(`${testResults.escapeKey ? '✅' : '❌'} ESC key closes: ${testResults.escapeKey}`);
    
    await page.screenshot({ 
      path: `${screenshotsDir}/04-esc-closed.png`,
      fullPage: true 
    });
    
    // Test 6: Check for controller conflicts
    console.log('🔍 Checking for controller conflicts...');
    const conflicts = await page.evaluate(() => {
      // Check if dark-mode controller still works
      const htmlElement = document.querySelector('html[data-controller="dark-mode"]');
      const bodyElement = document.querySelector('body[data-controller="mobile-menu"]');
      
      return {
        darkModeOnHtml: !!htmlElement,
        mobileMenuOnBody: !!bodyElement,
        bothExist: !!(htmlElement && bodyElement)
      };
    });
    
    testResults.noConflicts = conflicts.bothExist;
    console.log(`${testResults.noConflicts ? '✅' : '❌'} No controller conflicts: ${testResults.noConflicts}`);
    console.log('   Dark mode on HTML:', conflicts.darkModeOnHtml);
    console.log('   Mobile menu on body:', conflicts.mobileMenuOnBody);
    
  } catch (error) {
    console.error('❌ Test error:', error);
  }
  
  await browser.close();
  
  // Results summary
  console.log('\n📋 TEST RESULTS SUMMARY');
  console.log('========================');
  
  const allTestsPassed = Object.values(testResults).every(result => result === true);
  const passedTests = Object.values(testResults).filter(result => result === true).length;
  const totalTests = Object.keys(testResults).length;
  
  console.log(`Overall Status: ${allTestsPassed ? '✅ ALL TESTS PASSED' : '❌ SOME TESTS FAILED'}`);
  console.log(`Results: ${passedTests}/${totalTests} tests passed\n`);
  
  Object.entries(testResults).forEach(([test, result]) => {
    console.log(`${result ? '✅' : '❌'} ${test}: ${result}`);
  });
  
  if (allTestsPassed) {
    console.log('\n🎉 Mobile navigation fix successful!');
    console.log('The mobile menu now opens, closes, and works correctly.');
  } else {
    console.log('\n⚠️ Some issues remain. Check the failed tests above.');
  }
  
  console.log(`\n📁 Screenshots saved to: ${screenshotsDir}`);
})();