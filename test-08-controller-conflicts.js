import { chromium } from 'playwright';

export async function testControllerConflicts() {
  console.log('🧪 TEST 8: Controller Conflicts');
  console.log('=============================');
  
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
    
    // Test 1: Check both controllers are present and distinct
    console.log('🎮 Testing controller coexistence...');
    
    const controllerSetup = await page.evaluate(() => {
      const htmlElement = document.querySelector('html[data-controller="dark-mode"]');
      const bodyElement = document.querySelector('body[data-controller="mobile-menu"]');
      
      return {
        htmlHasDarkMode: !!htmlElement,
        bodyHasMobileMenu: !!bodyElement,
        htmlController: htmlElement ? htmlElement.getAttribute('data-controller') : null,
        bodyController: bodyElement ? bodyElement.getAttribute('data-controller') : null,
        bothPresent: !!(htmlElement && bodyElement),
        noDuplication: htmlElement !== bodyElement
      };
    });
    
    console.log('🎮 Controller setup:');
    console.log(`   HTML has dark-mode: ${controllerSetup.htmlHasDarkMode} ("${controllerSetup.htmlController}")`);
    console.log(`   Body has mobile-menu: ${controllerSetup.bodyHasMobileMenu} ("${controllerSetup.bodyController}")`);
    console.log(`   Both present: ${controllerSetup.bothPresent}`);
    console.log(`   No duplication: ${controllerSetup.noDuplication}`);
    
    // Test 2: Dark mode functionality still works
    console.log('\n🌙 Testing dark mode functionality...');
    
    // Get initial theme
    const initialTheme = await page.evaluate(() => {
      return {
        htmlClasses: document.documentElement.className,
        hasDarkClass: document.documentElement.classList.contains('dark'),
        localStorage: localStorage.getItem('theme')
      };
    });
    
    console.log('🌙 Initial theme state:');
    console.log(`   HTML classes: "${initialTheme.htmlClasses}"`);
    console.log(`   Has dark class: ${initialTheme.hasDarkClass}`);
    console.log(`   LocalStorage theme: "${initialTheme.localStorage}"`);
    
    // Click dark mode toggle
    const darkModeButton = await page.locator('button[data-action="click->dark-mode#toggle"]');
    const darkModeButtonExists = await darkModeButton.count() > 0;
    
    console.log(`🌙 Dark mode button exists: ${darkModeButtonExists}`);
    
    if (darkModeButtonExists) {
      await darkModeButton.click();
      await page.waitForTimeout(500);
      
      const afterToggle = await page.evaluate(() => {
        return {
          htmlClasses: document.documentElement.className,
          hasDarkClass: document.documentElement.classList.contains('dark'),
          localStorage: localStorage.getItem('theme')
        };
      });
      
      console.log('🌙 After dark mode toggle:');
      console.log(`   HTML classes: "${afterToggle.htmlClasses}"`);
      console.log(`   Has dark class: ${afterToggle.hasDarkClass}`);
      console.log(`   LocalStorage theme: "${afterToggle.localStorage}"`);
      
      const darkModeToggled = initialTheme.hasDarkClass !== afterToggle.hasDarkClass;
      console.log(`🌙 Dark mode toggled: ${darkModeToggled}`);
      
      // Toggle back
      await darkModeButton.click();
      await page.waitForTimeout(500);
    }
    
    // Test 3: Mobile menu functionality still works with both controllers
    console.log('\n📱 Testing mobile menu with dual controllers...');
    
    // Open mobile menu
    await page.click('button[data-mobile-menu-target="button"]');
    await page.waitForTimeout(600);
    
    const mobileMenuTest = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      const backdrop = document.querySelector('[data-mobile-menu-target="backdrop"]');
      const button = document.querySelector('[data-mobile-menu-target="button"]');
      
      return {
        drawerOpen: drawer ? drawer.classList.contains('open') : false,
        backdropVisible: backdrop ? backdrop.classList.contains('visible') : false,
        buttonAriaExpanded: button ? button.getAttribute('aria-expanded') : null,
        bodyScrollPrevented: document.body.classList.contains('mobile-menu-open')
      };
    });
    
    console.log('📱 Mobile menu state:');
    console.log(`   Drawer open: ${mobileMenuTest.drawerOpen}`);
    console.log(`   Backdrop visible: ${mobileMenuTest.backdropVisible}`);
    console.log(`   Button aria-expanded: ${mobileMenuTest.buttonAriaExpanded}`);
    console.log(`   Body scroll prevented: ${mobileMenuTest.bodyScrollPrevented}`);
    
    const mobileMenuWorks = mobileMenuTest.drawerOpen && 
                           mobileMenuTest.backdropVisible &&
                           mobileMenuTest.buttonAriaExpanded === 'true' &&
                           mobileMenuTest.bodyScrollPrevented;
    
    // Close menu
    await page.keyboard.press('Escape');
    await page.waitForTimeout(600);
    
    const menuClosed = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      const backdrop = document.querySelector('[data-mobile-menu-target="backdrop"]');
      
      return {
        drawerClosed: drawer ? drawer.classList.contains('closed') : false,
        backdropHidden: backdrop ? backdrop.classList.contains('hidden') : false
      };
    });
    
    console.log('📱 Menu after close:');
    console.log(`   Drawer closed: ${menuClosed.drawerClosed}`);
    console.log(`   Backdrop hidden: ${menuClosed.backdropHidden}`);
    
    const menuClosesCorrectly = menuClosed.drawerClosed && menuClosed.backdropHidden;
    
    // Test 4: No JavaScript errors or conflicts
    console.log('\n🔍 Testing for JavaScript errors...');
    
    const jsErrors = [];
    
    // Listen for console errors during operation
    page.on('pageerror', error => {
      jsErrors.push(error.message);
    });
    
    // Perform various operations to trigger any potential conflicts
    const operationResults = [];
    
    try {
      // Dark mode toggle
      if (darkModeButtonExists) {
        await darkModeButton.click();
        await page.waitForTimeout(300);
        operationResults.push({ operation: 'dark-mode-toggle', success: true });
      }
      
      // Mobile menu open
      await page.click('button[data-mobile-menu-target="button"]');
      await page.waitForTimeout(300);
      operationResults.push({ operation: 'mobile-menu-open', success: true });
      
      // Mobile menu close via backdrop
      await page.mouse.click(25, 300);
      await page.waitForTimeout(300);
      operationResults.push({ operation: 'mobile-menu-backdrop-close', success: true });
      
      // Mobile menu open and close via ESC
      await page.click('button[data-mobile-menu-target="button"]');
      await page.waitForTimeout(300);
      await page.keyboard.press('Escape');
      await page.waitForTimeout(300);
      operationResults.push({ operation: 'mobile-menu-esc-close', success: true });
      
    } catch (error) {
      operationResults.push({ 
        operation: 'operation-error', 
        success: false, 
        error: error.message 
      });
    }
    
    console.log('🔍 Operation results:');
    operationResults.forEach(result => {
      console.log(`   ${result.operation}: ${result.success ? '✅' : '❌'}`);
      if (!result.success) {
        console.log(`     Error: ${result.error}`);
      }
    });
    
    console.log(`🔍 JavaScript errors found: ${jsErrors.length}`);
    jsErrors.forEach((error, index) => {
      console.log(`   ${index + 1}. ${error}`);
    });
    
    // Test 5: Performance check - no excessive event listeners
    console.log('\n⚡ Testing performance impact...');
    
    const performanceInfo = await page.evaluate(() => {
      // Count event listeners (approximation)
      const elements = document.querySelectorAll('*');
      let elementCount = elements.length;
      
      // Check for controller-related classes
      const controllerElements = document.querySelectorAll('[data-controller]');
      const targetElements = document.querySelectorAll('[data-mobile-menu-target], [data-dark-mode-target]');
      const actionElements = document.querySelectorAll('[data-action]');
      
      return {
        totalElements: elementCount,
        controllerElements: controllerElements.length,
        targetElements: targetElements.length,
        actionElements: actionElements.length,
        memoryUsage: performance.memory ? {
          used: Math.round(performance.memory.usedJSHeapSize / 1024 / 1024),
          total: Math.round(performance.memory.totalJSHeapSize / 1024 / 1024)
        } : null
      };
    });
    
    console.log('⚡ Performance metrics:');
    console.log(`   Total DOM elements: ${performanceInfo.totalElements}`);
    console.log(`   Controller elements: ${performanceInfo.controllerElements}`);
    console.log(`   Target elements: ${performanceInfo.targetElements}`);
    console.log(`   Action elements: ${performanceInfo.actionElements}`);
    if (performanceInfo.memoryUsage) {
      console.log(`   Memory usage: ${performanceInfo.memoryUsage.used}MB / ${performanceInfo.memoryUsage.total}MB`);
    }
    
    // Determine overall test success
    const allOperationsSucceeded = operationResults.every(result => result.success);
    const noJavaScriptErrors = jsErrors.length === 0;
    const reasonablePerformance = performanceInfo.controllerElements <= 5 && 
                                 performanceInfo.targetElements <= 10;
    
    const testPassed = controllerSetup.bothPresent && 
                      controllerSetup.noDuplication &&
                      mobileMenuWorks && 
                      menuClosesCorrectly &&
                      allOperationsSucceeded &&
                      noJavaScriptErrors &&
                      reasonablePerformance;
    
    results.passed = testPassed;
    results.details = {
      controllerSetup,
      initialTheme,
      mobileMenuTest: {
        opens: mobileMenuWorks,
        closes: menuClosesCorrectly
      },
      operationResults,
      jsErrors,
      performanceInfo,
      requirements: {
        bothPresent: controllerSetup.bothPresent,
        noDuplication: controllerSetup.noDuplication,
        mobileMenuWorks,
        menuClosesCorrectly,
        allOperationsSucceeded,
        noJavaScriptErrors,
        reasonablePerformance
      }
    };
    
    console.log(`\n📊 Controller Conflicts Summary:`);
    console.log(`   Both controllers present: ${controllerSetup.bothPresent ? '✅' : '❌'}`);
    console.log(`   No element duplication: ${controllerSetup.noDuplication ? '✅' : '❌'}`);
    console.log(`   Mobile menu works: ${mobileMenuWorks ? '✅' : '❌'}`);
    console.log(`   Menu closes correctly: ${menuClosesCorrectly ? '✅' : '❌'}`);
    console.log(`   All operations succeeded: ${allOperationsSucceeded ? '✅' : '❌'}`);
    console.log(`   No JS errors: ${noJavaScriptErrors ? '✅' : '❌'}`);
    console.log(`   Reasonable performance: ${reasonablePerformance ? '✅' : '❌'}`);
    
    console.log(`\n${testPassed ? '✅' : '❌'} TEST 8 RESULT: ${testPassed ? 'PASSED' : 'FAILED'}`);
    
    if (!testPassed) {
      if (!controllerSetup.bothPresent) {
        results.errors.push('Both controllers are not present');
      }
      if (!controllerSetup.noDuplication) {
        results.errors.push('Controller elements are duplicated');
      }
      if (!mobileMenuWorks) {
        results.errors.push('Mobile menu functionality broken with dual controllers');
      }
      if (!menuClosesCorrectly) {
        results.errors.push('Mobile menu closing broken with dual controllers');
      }
      if (!allOperationsSucceeded) {
        results.errors.push('Some operations failed during conflict testing');
      }
      if (!noJavaScriptErrors) {
        results.errors.push(`JavaScript errors detected: ${jsErrors.join(', ')}`);
      }
      if (!reasonablePerformance) {
        results.errors.push('Performance impact from dual controllers');
      }
    }
    
  } catch (error) {
    results.errors.push(`Test execution error: ${error.message}`);
    console.error('❌ Test 8 Error:', error);
  }
  
  await browser.close();
  return results;
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  testControllerConflicts().then(results => {
    console.log('\n📊 Final Results:', results);
  });
}