import { chromium } from 'playwright';

export async function testMenuOpening() {
  console.log('🧪 TEST 2: Mobile Menu Opening');
  console.log('==============================');
  
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
    
    // Check initial state
    const initialState = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      const backdrop = document.querySelector('[data-mobile-menu-target="backdrop"]');
      const hamburger = document.querySelector('[data-mobile-menu-target="hamburger"]');
      const button = document.querySelector('[data-mobile-menu-target="button"]');
      
      return {
        drawerClasses: drawer ? drawer.className : 'not found',
        backdropClasses: backdrop ? backdrop.className : 'not found',
        hamburgerClasses: hamburger ? hamburger.className : 'not found',
        buttonVisible: button ? button.offsetParent !== null : false,
        buttonAriaExpanded: button ? button.getAttribute('aria-expanded') : null
      };
    });
    
    console.log('📊 Initial state:');
    console.log(`   Drawer classes: ${initialState.drawerClasses}`);
    console.log(`   Backdrop classes: ${initialState.backdropClasses}`);
    console.log(`   Hamburger classes: ${initialState.hamburgerClasses}`);
    console.log(`   Button visible: ${initialState.buttonVisible}`);
    console.log(`   Button aria-expanded: ${initialState.buttonAriaExpanded}`);
    
    // Click hamburger button to open menu
    console.log('\n🍔 Clicking hamburger button...');
    await page.click('button[data-mobile-menu-target="button"]');
    await page.waitForTimeout(600); // Wait for animation
    
    // Check state after opening
    const openState = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      const backdrop = document.querySelector('[data-mobile-menu-target="backdrop"]');
      const hamburger = document.querySelector('[data-mobile-menu-target="hamburger"]');
      const button = document.querySelector('[data-mobile-menu-target="button"]');
      
      return {
        drawerClasses: drawer ? drawer.className : 'not found',
        backdropClasses: backdrop ? backdrop.className : 'not found',
        hamburgerClasses: hamburger ? hamburger.className : 'not found',
        buttonAriaExpanded: button ? button.getAttribute('aria-expanded') : null,
        drawerOpen: drawer ? drawer.classList.contains('open') : false,
        backdropVisible: backdrop ? backdrop.classList.contains('visible') : false,
        hamburgerAnimated: hamburger ? hamburger.classList.contains('open') : false,
        bodyScrollPrevented: document.body.classList.contains('mobile-menu-open')
      };
    });
    
    console.log('📊 Open state:');
    console.log(`   Drawer classes: ${openState.drawerClasses}`);
    console.log(`   Backdrop classes: ${openState.backdropClasses}`);
    console.log(`   Hamburger classes: ${openState.hamburgerClasses}`);
    console.log(`   Button aria-expanded: ${openState.buttonAriaExpanded}`);
    console.log(`   Drawer open: ${openState.drawerOpen}`);
    console.log(`   Backdrop visible: ${openState.backdropVisible}`);
    console.log(`   Hamburger animated: ${openState.hamburgerAnimated}`);
    console.log(`   Body scroll prevented: ${openState.bodyScrollPrevented}`);
    
    // Take screenshot for verification
    await page.screenshot({ 
      path: './test-02-menu-open.png',
      fullPage: true 
    });
    console.log('📸 Screenshot saved: test-02-menu-open.png');
    
    // Determine if test passed
    const testPassed = openState.drawerOpen && 
                      openState.backdropVisible && 
                      openState.hamburgerAnimated &&
                      openState.buttonAriaExpanded === 'true' &&
                      openState.bodyScrollPrevented;
    
    results.passed = testPassed;
    results.details = {
      initialState,
      openState
    };
    
    console.log(`\n${testPassed ? '✅' : '❌'} TEST 2 RESULT: ${testPassed ? 'PASSED' : 'FAILED'}`);
    
    if (!testPassed) {
      if (!openState.drawerOpen) {
        results.errors.push('Drawer does not have "open" class');
      }
      if (!openState.backdropVisible) {
        results.errors.push('Backdrop does not have "visible" class');
      }
      if (!openState.hamburgerAnimated) {
        results.errors.push('Hamburger does not have "open" class for animation');
      }
      if (openState.buttonAriaExpanded !== 'true') {
        results.errors.push('Button aria-expanded not set to "true"');
      }
      if (!openState.bodyScrollPrevented) {
        results.errors.push('Body scroll not prevented (missing mobile-menu-open class)');
      }
    }
    
  } catch (error) {
    results.errors.push(`Test execution error: ${error.message}`);
    console.error('❌ Test 2 Error:', error);
  }
  
  await browser.close();
  return results;
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  testMenuOpening().then(results => {
    console.log('\n📊 Final Results:', results);
  });
}