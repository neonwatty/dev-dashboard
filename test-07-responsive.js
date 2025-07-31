import { chromium } from 'playwright';

export async function testResponsiveBehavior() {
  console.log('🧪 TEST 7: Responsive Behavior');
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
    await page.waitForTimeout(2000);
    
    // Test 1: Hamburger visibility on mobile vs desktop
    console.log('📱 Testing hamburger button visibility across viewports...');
    
    const viewportTests = [];
    
    // Mobile viewport (375x667)
    await page.setViewportSize({ width: 375, height: 667 });
    await page.waitForTimeout(1000);
    
    const mobileVisibility = await page.evaluate(() => {
      const button = document.querySelector('[data-mobile-menu-target="button"]');
      const desktopNav = document.querySelector('.hidden.md\\:ml-10.md\\:flex.md\\:space-x-8');
      
      return {
        hamburgerVisible: button ? button.offsetParent !== null : false,
        desktopNavVisible: desktopNav ? desktopNav.offsetParent !== null : false,
        viewportWidth: window.innerWidth,
        viewportHeight: window.innerHeight
      };
    });
    
    viewportTests.push({
      viewport: 'Mobile (375x667)',
      ...mobileVisibility
    });
    
    console.log(`   Mobile: Hamburger ${mobileVisibility.hamburgerVisible ? 'visible ✅' : 'hidden ❌'}, Desktop nav ${mobileVisibility.desktopNavVisible ? 'visible ❌' : 'hidden ✅'}`);
    
    // Tablet viewport (768x1024)
    await page.setViewportSize({ width: 768, height: 1024 });
    await page.waitForTimeout(1000);
    
    const tabletVisibility = await page.evaluate(() => {
      const button = document.querySelector('[data-mobile-menu-target="button"]');
      const desktopNav = document.querySelector('.hidden.md\\:ml-10.md\\:flex.md\\:space-x-8');
      
      return {
        hamburgerVisible: button ? button.offsetParent !== null : false,
        desktopNavVisible: desktopNav ? desktopNav.offsetParent !== null : false,
        viewportWidth: window.innerWidth,
        viewportHeight: window.innerHeight
      };
    });
    
    viewportTests.push({
      viewport: 'Tablet (768x1024)',
      ...tabletVisibility
    });
    
    console.log(`   Tablet: Hamburger ${tabletVisibility.hamburgerVisible ? 'visible ❌' : 'hidden ✅'}, Desktop nav ${tabletVisibility.desktopNavVisible ? 'visible ✅' : 'hidden ❌'}`);
    
    // Desktop viewport (1200x800)
    await page.setViewportSize({ width: 1200, height: 800 });
    await page.waitForTimeout(1000);
    
    const desktopVisibility = await page.evaluate(() => {
      const button = document.querySelector('[data-mobile-menu-target="button"]');
      const desktopNav = document.querySelector('.hidden.md\\:ml-10.md\\:flex.md\\:space-x-8');
      
      return {
        hamburgerVisible: button ? button.offsetParent !== null : false,
        desktopNavVisible: desktopNav ? desktopNav.offsetParent !== null : false,
        viewportWidth: window.innerWidth,
        viewportHeight: window.innerHeight
      };
    });
    
    viewportTests.push({
      viewport: 'Desktop (1200x800)',
      ...desktopVisibility
    });
    
    console.log(`   Desktop: Hamburger ${desktopVisibility.hamburgerVisible ? 'visible ❌' : 'hidden ✅'}, Desktop nav ${desktopVisibility.desktopNavVisible ? 'visible ✅' : 'hidden ❌'}`);
    
    // Test 2: Menu auto-close on viewport resize
    console.log('\n🔄 Testing menu auto-close on viewport resize...');
    
    // Start with mobile and open menu
    await page.setViewportSize({ width: 375, height: 667 });
    await page.waitForTimeout(1000);
    
    await page.click('button[data-mobile-menu-target="button"]');
    await page.waitForTimeout(600);
    
    // Verify menu is open
    const menuOpenBefore = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      const backdrop = document.querySelector('[data-mobile-menu-target="backdrop"]');
      
      return {
        drawerOpen: drawer ? drawer.classList.contains('open') : false,
        backdropVisible: backdrop ? backdrop.classList.contains('visible') : false
      };
    });
    
    console.log(`   Menu state before resize: Drawer ${menuOpenBefore.drawerOpen ? 'open' : 'closed'}, Backdrop ${menuOpenBefore.backdropVisible ? 'visible' : 'hidden'}`);
    
    // Resize to desktop
    await page.setViewportSize({ width: 1200, height: 800 });
    await page.waitForTimeout(1500); // Wait for resize handler + animation
    
    // Check if menu closed automatically
    const menuStateAfterResize = await page.evaluate(() => {
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
    
    console.log(`   Menu state after resize: Drawer ${menuStateAfterResize.drawerClosed ? 'closed' : 'open'}, Backdrop ${menuStateAfterResize.backdropHidden ? 'hidden' : 'visible'}`);
    console.log(`   Button aria-expanded: ${menuStateAfterResize.buttonAriaExpanded}`);
    console.log(`   Body scroll restored: ${menuStateAfterResize.bodyScrollRestored}`);
    
    const autoCloseWorks = menuStateAfterResize.drawerClosed && 
                          menuStateAfterResize.backdropHidden &&
                          menuStateAfterResize.buttonAriaExpanded === 'false' &&
                          menuStateAfterResize.bodyScrollRestored;
    
    // Test 3: Mobile drawer and backdrop positioning
    console.log('\n📐 Testing mobile drawer positioning...');
    
    await page.setViewportSize({ width: 375, height: 667 });
    await page.waitForTimeout(1000);
    
    // Open menu to test positioning
    await page.click('button[data-mobile-menu-target="button"]');
    await page.waitForTimeout(600);
    
    const positioningInfo = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      const backdrop = document.querySelector('[data-mobile-menu-target="backdrop"]');
      
      if (!drawer || !backdrop) return null;
      
      const drawerRect = drawer.getBoundingClientRect();
      const backdropRect = backdrop.getBoundingClientRect();
      const drawerStyles = window.getComputedStyle(drawer);
      const backdropStyles = window.getComputedStyle(backdrop);
      
      return {
        drawer: {
          rect: {
            x: drawerRect.x,
            y: drawerRect.y,
            width: drawerRect.width,
            height: drawerRect.height,
            right: drawerRect.right
          },
          styles: {
            position: drawerStyles.position,
            right: drawerStyles.right,
            top: drawerStyles.top,
            zIndex: drawerStyles.zIndex,
            transform: drawerStyles.transform
          }
        },
        backdrop: {
          rect: {
            x: backdropRect.x,
            y: backdropRect.y,
            width: backdropRect.width,
            height: backdropRect.height
          },
          styles: {
            position: backdropStyles.position,
            zIndex: backdropStyles.zIndex
          }
        },
        viewport: {
          width: window.innerWidth,
          height: window.innerHeight
        }
      };
    });
    
    console.log(`   Drawer positioning:`);
    console.log(`     Position: ${positioningInfo.drawer.styles.position}`);
    console.log(`     Transform: ${positioningInfo.drawer.styles.transform}`);
    console.log(`     Z-index: ${positioningInfo.drawer.styles.zIndex}`);
    console.log(`     Dimensions: ${Math.round(positioningInfo.drawer.rect.width)}x${Math.round(positioningInfo.drawer.rect.height)}px`);
    
    console.log(`   Backdrop positioning:`);
    console.log(`     Position: ${positioningInfo.backdrop.styles.position}`);
    console.log(`     Z-index: ${positioningInfo.backdrop.styles.zIndex}`);
    console.log(`     Covers viewport: ${positioningInfo.backdrop.rect.width >= positioningInfo.viewport.width && positioningInfo.backdrop.rect.height >= positioningInfo.viewport.height}`);
    
    // Test 4: Bottom navigation visibility
    console.log('\n📱 Testing bottom navigation responsive behavior...');
    
    const bottomNavTests = [];
    
    // Mobile - should show bottom nav
    await page.setViewportSize({ width: 375, height: 667 });
    await page.waitForTimeout(1000);
    
    const mobileBottomNav = await page.evaluate(() => {
      const bottomNav = document.querySelector('.bottom-nav');
      return {
        exists: !!bottomNav,
        visible: bottomNav ? bottomNav.offsetParent !== null : false
      };
    });
    
    bottomNavTests.push({
      viewport: 'Mobile',
      ...mobileBottomNav
    });
    
    // Desktop - should hide bottom nav  
    await page.setViewportSize({ width: 1200, height: 800 });
    await page.waitForTimeout(1000);
    
    const desktopBottomNav = await page.evaluate(() => {
      const bottomNav = document.querySelector('.bottom-nav');
      return {
        exists: !!bottomNav,
        visible: bottomNav ? bottomNav.offsetParent !== null : false
      };
    });
    
    bottomNavTests.push({
      viewport: 'Desktop',
      ...desktopBottomNav
    });
    
    console.log(`   Mobile bottom nav: ${mobileBottomNav.visible ? 'visible ✅' : 'hidden ❌'}`);
    console.log(`   Desktop bottom nav: ${desktopBottomNav.visible ? 'visible ❌' : 'hidden ✅'}`);
    
    // Determine test success
    const responsiveVisibility = !mobileVisibility.desktopNavVisible && 
                                mobileVisibility.hamburgerVisible &&
                                !tabletVisibility.hamburgerVisible &&
                                tabletVisibility.desktopNavVisible &&
                                !desktopVisibility.hamburgerVisible &&
                                desktopVisibility.desktopNavVisible;
    
    const correctBottomNavBehavior = mobileBottomNav.visible && !desktopBottomNav.visible;
    
    const correctPositioning = positioningInfo.drawer.styles.position === 'fixed' &&
                              positioningInfo.backdrop.styles.position === 'fixed' &&
                              positioningInfo.backdrop.rect.width >= positioningInfo.viewport.width;
    
    const testPassed = responsiveVisibility && autoCloseWorks && 
                      correctBottomNavBehavior && correctPositioning;
    
    results.passed = testPassed;
    results.details = {
      viewportTests,
      autoCloseOnResize: {
        worked: autoCloseWorks,
        beforeState: menuOpenBefore,
        afterState: menuStateAfterResize
      },
      positioning: positioningInfo,
      bottomNavTests,
      requirements: {
        responsiveVisibility,
        autoCloseWorks,
        correctBottomNavBehavior,
        correctPositioning
      }
    };
    
    console.log(`\n📊 Responsive Behavior Summary:`);
    console.log(`   Responsive visibility: ${responsiveVisibility ? '✅' : '❌'}`);
    console.log(`   Auto-close on resize: ${autoCloseWorks ? '✅' : '❌'}`);
    console.log(`   Bottom nav behavior: ${correctBottomNavBehavior ? '✅' : '❌'}`);
    console.log(`   Correct positioning: ${correctPositioning ? '✅' : '❌'}`);
    
    console.log(`\n${testPassed ? '✅' : '❌'} TEST 7 RESULT: ${testPassed ? 'PASSED' : 'FAILED'}`);
    
    if (!testPassed) {
      if (!responsiveVisibility) {
        results.errors.push('Navigation elements do not show/hide correctly across viewports');
      }
      if (!autoCloseWorks) {
        results.errors.push('Mobile menu does not auto-close when resizing to desktop');
      }
      if (!correctBottomNavBehavior) {
        results.errors.push('Bottom navigation visibility incorrect across viewports');
      }
      if (!correctPositioning) {
        results.errors.push('Mobile drawer or backdrop positioning is incorrect');
      }
    }
    
  } catch (error) {
    results.errors.push(`Test execution error: ${error.message}`);
    console.error('❌ Test 7 Error:', error);
  }
  
  await browser.close();
  return results;
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  testResponsiveBehavior().then(results => {
    console.log('\n📊 Final Results:', results);
  });
}