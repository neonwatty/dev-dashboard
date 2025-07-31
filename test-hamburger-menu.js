import { chromium, devices } from 'playwright';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function testHamburgerMenu() {
  console.log('🚀 Starting hamburger menu test...');
  
  // Create screenshots directory if it doesn't exist
  const screenshotsDir = path.join(__dirname, 'hamburger-test-screenshots');
  if (!fs.existsSync(screenshotsDir)) {
    fs.mkdirSync(screenshotsDir);
  }

  const browser = await chromium.launch({ 
    headless: true // Set to true for automated testing
  });
  
  // Use Playwright's predefined iPhone 13 device which should have a modern user agent
  const iPhone13 = devices['iPhone 13'];
  const context = await browser.newContext({
    ...iPhone13,
    // Override with additional headers for Rails
    extraHTTPHeaders: {
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9'
    }
  });

  const page = await context.newPage();
  
  // Log the user agent being used
  const userAgent = await page.evaluate(() => navigator.userAgent);
  console.log('🔧 User Agent:', userAgent);
  
  // Enable console logging with error details
  page.on('console', msg => {
    const type = msg.type();
    if (type === 'error') {
      console.error('❌ Console Error:', msg.text());
    } else {
      console.log('📋 Console:', msg.text());
    }
  });
  page.on('pageerror', error => console.error('❌ Page error:', error));

  try {
    // 1. Navigate to the page
    console.log('📱 Navigating to http://localhost:3002...');
    const response = await page.goto('http://localhost:3002', { waitUntil: 'networkidle' });
    console.log(`📊 Response status: ${response.status()}`);
    console.log(`📊 Response headers:`, response.headers());
    
    // Check page content
    const pageTitle = await page.title();
    console.log(`📄 Page title: ${pageTitle}`);
    
    // Check if we got an error page
    const bodyText = await page.textContent('body');
    if (bodyText.includes('Not Acceptable') || bodyText.includes('406')) {
      console.error('❌ Got 406 Not Acceptable error - Rails format negotiation issue');
      console.log('📄 Page content:', bodyText.substring(0, 200));
    }

    // 2. Take initial screenshot
    await page.screenshot({ 
      path: path.join(screenshotsDir, '1-initial-mobile-view.png'),
      fullPage: false 
    });
    console.log('📸 Screenshot 1: Initial mobile view saved');

    // Wait for Stimulus to initialize and check for mobile menu controller
    console.log('⏳ Waiting for Stimulus controllers to initialize...');
    await page.waitForFunction(() => {
      const button = document.querySelector('[data-mobile-menu-target="button"]');
      return button && button.dataset.action;
    }, { timeout: 5000 });
    
    // Wait specifically for mobile menu controller messages
    await page.waitForTimeout(1000); // Give time for controller connection messages

    // 3. Check if hamburger menu button is visible
    console.log('🔍 Looking for hamburger menu button...');
    const hamburgerButton = await page.locator('button[aria-label="Open navigation menu"]').first();
    const isHamburgerVisible = await hamburgerButton.isVisible();
    console.log(`✅ Hamburger menu button visible: ${isHamburgerVisible}`);

    if (!isHamburgerVisible) {
      // Try alternative selectors
      console.log('🔍 Trying alternative selectors...');
      const altSelectors = [
        'button.mobile-menu-button',
        'button#mobile-menu-button',
        'button[data-mobile-menu-button]',
        'button svg[class*="hamburger"]',
        'button:has(svg path[d*="M3 12h18M3 6h18M3 18h18"])',
        '.mobile-menu-trigger',
        '[data-action*="mobile-navigation"]'
      ];

      for (const selector of altSelectors) {
        const element = await page.locator(selector).first();
        if (await element.isVisible()) {
          console.log(`✅ Found hamburger button with selector: ${selector}`);
          break;
        }
      }
    }

    // Get button position and properties
    const buttonBox = await hamburgerButton.boundingBox();
    console.log('📍 Hamburger button position:', buttonBox);

    // Check for Stimulus controller and button structure
    const buttonInfo = await page.evaluate(() => {
      const button = document.querySelector('[data-mobile-menu-target="button"]');
      if (!button) return { found: false };
      
      return {
        found: true,
        hasController: button.hasAttribute('data-controller'),
        controller: button.getAttribute('data-controller'),
        action: button.getAttribute('data-action'),
        innerHTML: button.innerHTML.substring(0, 100),
        classes: button.className,
        ariaLabel: button.getAttribute('aria-label')
      };
    });
    console.log('🎮 Button info:', buttonInfo);
    
    // Also check for mobile menu controller in DOM
    const mobileMenuController = await page.evaluate(() => {
      const elements = document.querySelectorAll('[data-controller*="mobile"]');
      return Array.from(elements).map(el => ({
        tag: el.tagName,
        controller: el.getAttribute('data-controller'),
        classes: el.className
      }));
    });
    console.log('📱 Mobile controllers found:', mobileMenuController);
    
    // Check for required targets
    const targetsInfo = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      const backdrop = document.querySelector('[data-mobile-menu-target="backdrop"]');
      return {
        drawer: drawer ? { found: true, classes: drawer.className, id: drawer.id } : { found: false },
        backdrop: backdrop ? { found: true, classes: backdrop.className } : { found: false }
      };
    });
    console.log('🎯 Required targets:', targetsInfo);

    // 4. Click the hamburger menu
    console.log('👆 Clicking hamburger menu button...');
    await hamburgerButton.click();
    
    // 5. Wait for animation and check for state changes
    console.log('⏳ Waiting for drawer animation...');
    await page.waitForTimeout(600); // Wait for typical drawer animation duration
    
    // Check if drawer opened by looking for state changes
    const drawerState = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      if (!drawer) return 'not found';
      
      const classes = drawer.className;
      const styles = window.getComputedStyle(drawer);
      return {
        classes,
        transform: styles.transform,
        display: styles.display,
        visibility: styles.visibility,
        isHidden: drawer.classList.contains('hidden'),
        isOpen: drawer.classList.contains('open'),
        isClosed: drawer.classList.contains('closed')
      };
    });
    console.log('🔍 Drawer state after click:', drawerState);

    // 6. Take screenshot with open drawer
    await page.screenshot({ 
      path: path.join(screenshotsDir, '2-drawer-open.png'),
      fullPage: false 
    });
    console.log('📸 Screenshot 2: Drawer open saved');

    // 7. Check if mobile drawer is visible
    console.log('🔍 Checking for mobile drawer...');
    const drawer = await page.locator('[data-mobile-menu-target="drawer"]').first();
    const drawerVisible = await drawer.isVisible();
    
    if (drawerVisible) {
      console.log(`✅ Mobile drawer is now visible!`);
      
      // Get drawer CSS classes and computed styles
      const classes = await drawer.getAttribute('class');
      console.log(`📋 Drawer CSS classes: ${classes}`);
      
      const styles = await drawer.evaluate(el => {
        const computed = window.getComputedStyle(el);
        return {
          transform: computed.transform,
          opacity: computed.opacity,
          display: computed.display,
          visibility: computed.visibility,
          position: computed.position,
          left: computed.left,
          right: computed.right,
          width: computed.width
        };
      });
      console.log('🎨 Drawer computed styles:', styles);
    } else {
      console.log('❌ Mobile drawer is NOT visible');
      console.log('Drawer state details:', drawerState);
    }

    if (!drawerVisible) {
      console.log('⚠️  Mobile drawer not visible. Checking DOM structure...');
      const allElements = await page.locator('*[class*="mobile"], *[class*="drawer"], *[id*="mobile"], *[id*="drawer"]').all();
      console.log(`Found ${allElements.length} elements with mobile/drawer in class/id`);
    }

    // 8. Check for backdrop overlay
    console.log('🔍 Checking for backdrop overlay...');
    const backdrop = await page.locator('[data-mobile-menu-target="backdrop"]').first();
    const backdropVisible = await backdrop.isVisible();
    
    if (backdropVisible) {
      console.log(`✅ Backdrop is visible!`);
      const backdropClasses = await backdrop.getAttribute('class');
      console.log(`📋 Backdrop CSS classes: ${backdropClasses}`);
    } else {
      console.log('❌ Backdrop is NOT visible');
    }

    // 9. Test closing by clicking backdrop
    if (backdropVisible && backdrop) {
      console.log('👆 Clicking backdrop to close drawer...');
      await backdrop.click();
      await page.waitForTimeout(600); // Wait for close animation
    } else {
      console.log('⚠️  No backdrop found, trying to close by clicking hamburger again...');
      await hamburgerButton.click();
      await page.waitForTimeout(600);
    }

    // 10. Take final screenshot
    await page.screenshot({ 
      path: path.join(screenshotsDir, '3-drawer-closed.png'),
      fullPage: false 
    });
    console.log('📸 Screenshot 3: Drawer closed saved');

    // Final report
    console.log('\n📊 Test Summary:');
    console.log(`- Hamburger button visible: ${isHamburgerVisible}`);
    console.log(`- Mobile drawer visible after click: ${drawerVisible}`);
    console.log(`- Backdrop overlay visible: ${backdropVisible}`);
    console.log(`- Screenshots saved in: ${screenshotsDir}`);

    // Check for any console errors
    const errors = [];
    page.on('pageerror', error => errors.push(error));
    if (errors.length > 0) {
      console.log('\n❌ Console errors found:');
      errors.forEach(error => console.log(error));
    }

  } catch (error) {
    console.error('❌ Test failed:', error);
    await page.screenshot({ 
      path: path.join(screenshotsDir, 'error-screenshot.png'),
      fullPage: false 
    });
  } finally {
    await browser.close();
    console.log('\n✅ Test completed');
  }
}

// Run the test
testHamburgerMenu().catch(console.error);