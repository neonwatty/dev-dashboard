import { chromium } from 'playwright';

export async function testAccessibility() {
  console.log('🧪 TEST 6: Accessibility Features');
  console.log('================================');
  
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
    
    // Test 1: ARIA attributes on hamburger button
    console.log('🔍 Testing hamburger button ARIA attributes...');
    const buttonAria = await page.evaluate(() => {
      const button = document.querySelector('[data-mobile-menu-target="button"]');
      if (!button) return null;
      
      return {
        hasAriaLabel: !!button.getAttribute('aria-label'),
        ariaLabel: button.getAttribute('aria-label'),
        hasAriaExpanded: button.hasAttribute('aria-expanded'),
        ariaExpanded: button.getAttribute('aria-expanded'),
        hasAriaControls: button.hasAttribute('aria-controls'),
        ariaControls: button.getAttribute('aria-controls')
      };
    });
    
    console.log('🎮 Button ARIA attributes:');
    console.log(`   aria-label: "${buttonAria.ariaLabel}" (${buttonAria.hasAriaLabel ? '✅' : '❌'})`);
    console.log(`   aria-expanded: "${buttonAria.ariaExpanded}" (${buttonAria.hasAriaExpanded ? '✅' : '❌'})`);
    console.log(`   aria-controls: "${buttonAria.ariaControls}" (${buttonAria.hasAriaControls ? '✅' : '❌'})`);
    
    // Test 2: Drawer ARIA attributes
    console.log('\n🔍 Testing drawer ARIA attributes...');
    const drawerAria = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      if (!drawer) return null;
      
      return {
        hasRole: !!drawer.getAttribute('role'),
        role: drawer.getAttribute('role'),
        hasAriaModal: drawer.hasAttribute('aria-modal'),
        ariaModal: drawer.getAttribute('aria-modal'),
        hasAriaHidden: drawer.hasAttribute('aria-hidden'),
        ariaHidden: drawer.getAttribute('aria-hidden'),
        hasAriaLabelledby: drawer.hasAttribute('aria-labelledby'),
        ariaLabelledby: drawer.getAttribute('aria-labelledby'),
        hasId: !!drawer.getAttribute('id'),
        id: drawer.getAttribute('id')
      };
    });
    
    console.log('📱 Drawer ARIA attributes:');
    console.log(`   role: "${drawerAria.role}" (${drawerAria.hasRole ? '✅' : '❌'})`);
    console.log(`   aria-modal: "${drawerAria.ariaModal}" (${drawerAria.hasAriaModal ? '✅' : '❌'})`);
    console.log(`   aria-hidden: "${drawerAria.ariaHidden}" (${drawerAria.hasAriaHidden ? '✅' : '❌'})`);
    console.log(`   aria-labelledby: "${drawerAria.ariaLabelledby}" (${drawerAria.hasAriaLabelledby ? '✅' : '❌'})`);
    console.log(`   id: "${drawerAria.id}" (${drawerAria.hasId ? '✅' : '❌'})`);
    
    // Test 3: ARIA state changes when opening menu
    console.log('\n🔍 Testing ARIA state changes...');
    
    // Open menu and check ARIA updates
    await page.click('button[data-mobile-menu-target="button"]');
    await page.waitForTimeout(600);
    
    const ariaAfterOpen = await page.evaluate(() => {
      const button = document.querySelector('[data-mobile-menu-target="button"]');
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      
      return {
        buttonAriaExpanded: button ? button.getAttribute('aria-expanded') : null,
        buttonAriaLabel: button ? button.getAttribute('aria-label') : null,
        drawerAriaHidden: drawer ? drawer.getAttribute('aria-hidden') : null
      };
    });
    
    console.log('📊 ARIA states after opening:');
    console.log(`   Button aria-expanded: "${ariaAfterOpen.buttonAriaExpanded}"`);
    console.log(`   Button aria-label: "${ariaAfterOpen.buttonAriaLabel}"`);
    console.log(`   Drawer aria-hidden: "${ariaAfterOpen.drawerAriaHidden}"`);
    
    // Test 4: Keyboard navigation within menu
    console.log('\n⌨️ Testing keyboard navigation...');
    
    // Tab through focusable elements
    await page.keyboard.press('Tab');
    await page.waitForTimeout(200);
    
    const focusAfterTab = await page.evaluate(() => {
      const activeElement = document.activeElement;
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      
      return {
        hasActiveElement: !!activeElement,
        activeElementTag: activeElement ? activeElement.tagName : null,
        activeElementText: activeElement ? activeElement.textContent?.trim() : null,
        focusInDrawer: activeElement && drawer ? drawer.contains(activeElement) : false
      };
    });
    
    console.log('🎯 Focus after Tab:');
    console.log(`   Active element: ${focusAfterTab.activeElementTag}`);
    console.log(`   Element text: "${focusAfterTab.activeElementText}"`);
    console.log(`   Focus in drawer: ${focusAfterTab.focusInDrawer}`);
    
    // Test 5: Screen reader labels and descriptions
    console.log('\n🔍 Testing screen reader support...');
    const screenReaderSupport = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      const title = document.querySelector('#mobile-nav-title');
      const closeButton = drawer ? drawer.querySelector('button[aria-label]') : null;
      const navLinks = Array.from(document.querySelectorAll('.mobile-nav-link'));
      
      return {
        drawerHasTitle: !!title,
        titleText: title ? title.textContent.trim() : null,
        closeButtonLabel: closeButton ? closeButton.getAttribute('aria-label') : null,
        linksWithText: navLinks.map(link => ({
          text: link.textContent.trim(),
          hasHref: !!link.getAttribute('href'),
          href: link.getAttribute('href')
        }))
      };
    });
    
    console.log('🗣️ Screen reader support:');
    console.log(`   Drawer title: "${screenReaderSupport.titleText}" (${screenReaderSupport.drawerHasTitle ? '✅' : '❌'})`);
    console.log(`   Close button label: "${screenReaderSupport.closeButtonLabel}" (${!!screenReaderSupport.closeButtonLabel ? '✅' : '❌'})`);
    console.log(`   Navigation links: ${screenReaderSupport.linksWithText.length} links`);
    
    screenReaderSupport.linksWithText.forEach((link, index) => {
      console.log(`      ${index + 1}. "${link.text}" → ${link.href} (${link.hasHref ? '✅' : '❌'})`);
    });
    
    // Test 6: Touch target sizes (accessibility requirement)
    console.log('\n👆 Testing touch target sizes...');
    const touchTargets = await page.evaluate(() => {
      const button = document.querySelector('[data-mobile-menu-target="button"]');
      const closeButton = document.querySelector('[data-mobile-menu-target="drawer"] button');
      const navLinks = Array.from(document.querySelectorAll('.mobile-nav-link'));
      
      const checkTouchTarget = (element) => {
        if (!element) return null;
        const rect = element.getBoundingClientRect();
        const styles = window.getComputedStyle(element);
        
        return {
          width: rect.width,
          height: rect.height,
          minWidth: parseFloat(styles.minWidth) || 0,
          minHeight: parseFloat(styles.minHeight) || 0,
          meetsStandard: rect.width >= 44 && rect.height >= 44
        };
      };
      
      return {
        hamburgerButton: checkTouchTarget(button),
        closeButton: checkTouchTarget(closeButton),
        navLinks: navLinks.map(link => ({
          text: link.textContent.trim(),
          ...checkTouchTarget(link)
        }))
      };
    });
    
    console.log('👆 Touch target analysis:');
    console.log(`   Hamburger button: ${Math.round(touchTargets.hamburgerButton.width)}x${Math.round(touchTargets.hamburgerButton.height)}px (${touchTargets.hamburgerButton.meetsStandard ? '✅' : '❌'})`);
    console.log(`   Close button: ${Math.round(touchTargets.closeButton.width)}x${Math.round(touchTargets.closeButton.height)}px (${touchTargets.closeButton.meetsStandard ? '✅' : '❌'})`);
    
    touchTargets.navLinks.forEach((link, index) => {
      console.log(`   Link ${index + 1} "${link.text}": ${Math.round(link.width)}x${Math.round(link.height)}px (${link.meetsStandard ? '✅' : '❌'})`);
    });
    
    // Close menu for final test
    await page.keyboard.press('Escape');
    await page.waitForTimeout(600);
    
    const ariaAfterClose = await page.evaluate(() => {
      const button = document.querySelector('[data-mobile-menu-target="button"]');
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      
      return {
        buttonAriaExpanded: button ? button.getAttribute('aria-expanded') : null,
        buttonAriaLabel: button ? button.getAttribute('aria-label') : null,
        drawerAriaHidden: drawer ? drawer.getAttribute('aria-hidden') : null
      };
    });
    
    console.log('\n📊 ARIA states after closing:');
    console.log(`   Button aria-expanded: "${ariaAfterClose.buttonAriaExpanded}"`);
    console.log(`   Button aria-label: "${ariaAfterClose.buttonAriaLabel}"`);
    console.log(`   Drawer aria-hidden: "${ariaAfterClose.drawerAriaHidden}"`);
    
    // Determine test success
    const requiredAriaAttributes = buttonAria.hasAriaLabel && buttonAria.hasAriaExpanded &&
                                  drawerAria.hasRole && drawerAria.hasAriaModal && drawerAria.hasAriaHidden;
    
    const correctAriaStates = ariaAfterOpen.buttonAriaExpanded === 'true' &&
                             ariaAfterOpen.drawerAriaHidden === 'false' &&
                             ariaAfterClose.buttonAriaExpanded === 'false' &&
                             ariaAfterClose.drawerAriaHidden === 'true';
    
    const adequateTouchTargets = touchTargets.hamburgerButton.meetsStandard &&
                                touchTargets.closeButton.meetsStandard &&
                                touchTargets.navLinks.every(link => link.meetsStandard);
    
    const screenReaderFriendly = screenReaderSupport.drawerHasTitle &&
                                !!screenReaderSupport.closeButtonLabel &&
                                screenReaderSupport.linksWithText.every(link => link.hasHref);
    
    const testPassed = requiredAriaAttributes && correctAriaStates && 
                      adequateTouchTargets && screenReaderFriendly;
    
    results.passed = testPassed;
    results.details = {
      buttonAria,
      drawerAria,
      ariaStateChanges: {
        afterOpen: ariaAfterOpen,
        afterClose: ariaAfterClose
      },
      keyboardNavigation: focusAfterTab,
      screenReaderSupport,
      touchTargets,
      requirements: {
        requiredAriaAttributes,
        correctAriaStates,
        adequateTouchTargets,
        screenReaderFriendly
      }
    };
    
    console.log(`\n📊 Accessibility Test Summary:`);
    console.log(`   Required ARIA attributes: ${requiredAriaAttributes ? '✅' : '❌'}`);
    console.log(`   Correct ARIA state changes: ${correctAriaStates ? '✅' : '❌'}`);
    console.log(`   Adequate touch targets: ${adequateTouchTargets ? '✅' : '❌'}`);
    console.log(`   Screen reader friendly: ${screenReaderFriendly ? '✅' : '❌'}`);
    
    console.log(`\n${testPassed ? '✅' : '❌'} TEST 6 RESULT: ${testPassed ? 'PASSED' : 'FAILED'}`);
    
    if (!testPassed) {
      if (!requiredAriaAttributes) {
        results.errors.push('Missing required ARIA attributes');
      }
      if (!correctAriaStates) {
        results.errors.push('ARIA states do not update correctly');
      }
      if (!adequateTouchTargets) {
        results.errors.push('Touch targets do not meet 44px minimum size requirement');
      }
      if (!screenReaderFriendly) {
        results.errors.push('Missing screen reader support elements');
      }
    }
    
  } catch (error) {
    results.errors.push(`Test execution error: ${error.message}`);
    console.error('❌ Test 6 Error:', error);
  }
  
  await browser.close();
  return results;
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  testAccessibility().then(results => {
    console.log('\n📊 Final Results:', results);
  });
}