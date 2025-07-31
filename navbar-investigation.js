import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';

(async () => {
  console.log('🔍 Starting navbar investigation...');
  
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  // Create screenshots directory
  const screenshotsDir = './navbar-investigation-screenshots';
  if (!fs.existsSync(screenshotsDir)) {
    fs.mkdirSync(screenshotsDir, { recursive: true });
  }
  
  const errors = [];
  const consoleMessages = [];
  
  // Capture console messages and errors
  page.on('console', msg => {
    consoleMessages.push({
      type: msg.type(),
      text: msg.text(),
      timestamp: new Date().toISOString()
    });
    console.log(`📝 Console ${msg.type()}: ${msg.text()}`);
  });
  
  page.on('pageerror', error => {
    errors.push({
      type: 'Page Error',
      message: error.message,
      stack: error.stack,
      timestamp: new Date().toISOString()
    });
    console.log(`❌ Page Error: ${error.message}`);
  });
  
  try {
    console.log('🌐 Navigating to localhost:3002...');
    await page.goto('http://localhost:3002', { waitUntil: 'networkidle' });
    await page.waitForTimeout(2000); // Allow time for JS to load
    
    console.log('📱 TESTING MOBILE VIEW (375x667)');
    console.log('================================');
    
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    await page.waitForTimeout(1000);
    
    // Take initial mobile screenshot
    await page.screenshot({ 
      path: `${screenshotsDir}/01-mobile-initial.png`,
      fullPage: true 
    });
    console.log('📸 Mobile initial screenshot captured');
    
    // Check if hamburger menu button exists and is visible
    console.log('🔍 Checking hamburger menu button...');
    const hamburgerButton = await page.locator('button[data-mobile-menu-target="button"]');
    const isHamburgerVisible = await hamburgerButton.isVisible();
    console.log(`🍔 Hamburger button visible: ${isHamburgerVisible}`);
    
    if (!isHamburgerVisible) {
      errors.push({
        type: 'Mobile Navigation Error',
        message: 'Hamburger menu button is not visible on mobile',
        timestamp: new Date().toISOString()
      });
    }
    
    // Check hamburger button attributes
    if (isHamburgerVisible) {
      const ariaLabel = await hamburgerButton.getAttribute('aria-label');
      const ariaExpanded = await hamburgerButton.getAttribute('aria-expanded');
      console.log(`🍔 Hamburger aria-label: ${ariaLabel}`);
      console.log(`🍔 Hamburger aria-expanded: ${ariaExpanded}`);
      
      if (!ariaLabel) {
        errors.push({
          type: 'Accessibility Error',
          message: 'Hamburger button missing aria-label',
          timestamp: new Date().toISOString()
        });
      }
    }
    
    // Test hamburger menu functionality
    if (isHamburgerVisible) {
      console.log('🍔 Testing hamburger menu open...');
      await hamburgerButton.click();
      await page.waitForTimeout(500); // Wait for animation
      
      // Take screenshot with menu open
      await page.screenshot({ 
        path: `${screenshotsDir}/02-mobile-menu-open.png`,
        fullPage: true 
      });
      console.log('📸 Mobile menu open screenshot captured');
      
      // Check if drawer is open
      const drawer = await page.locator('[data-mobile-menu-target="drawer"]');
      const drawerClasses = await drawer.getAttribute('class');
      const isDrawerOpen = drawerClasses.includes('open');
      console.log(`📱 Mobile drawer open: ${isDrawerOpen}`);
      
      if (!isDrawerOpen) {
        errors.push({
          type: 'Mobile Navigation Error',
          message: 'Mobile drawer does not open when hamburger is clicked',
          timestamp: new Date().toISOString()
        });
      }
      
      // Check backdrop visibility
      const backdrop = await page.locator('[data-mobile-menu-target="backdrop"]');
      const backdropClasses = await backdrop.getAttribute('class');
      const isBackdropVisible = backdropClasses.includes('visible');
      console.log(`🎭 Backdrop visible: ${isBackdropVisible}`);
      
      if (!isBackdropVisible) {
        errors.push({
          type: 'Mobile Navigation Error',
          message: 'Mobile backdrop not visible when menu is open',
          timestamp: new Date().toISOString()
        });
      }
      
      // Test navigation links in mobile drawer
      console.log('🔗 Testing mobile navigation links...');
      const mobileNavLinks = await page.locator('.mobile-nav-link').all();
      console.log(`🔗 Found ${mobileNavLinks.length} mobile navigation links`);
      
      for (let i = 0; i < mobileNavLinks.length; i++) {
        const link = mobileNavLinks[i];
        const href = await link.getAttribute('href');
        const text = await link.textContent();
        console.log(`🔗 Mobile link ${i + 1}: ${text.trim()} -> ${href}`);
      }
      
      // Test backdrop close functionality
      console.log('🎭 Testing backdrop close...');
      await backdrop.click();
      await page.waitForTimeout(500);
      
      const drawerClassesAfterBackdropClick = await drawer.getAttribute('class');
      const isDrawerClosedAfterBackdrop = drawerClassesAfterBackdropClick.includes('closed');
      console.log(`📱 Drawer closed after backdrop click: ${isDrawerClosedAfterBackdrop}`);
      
      if (!isDrawerClosedAfterBackdrop) {
        errors.push({
          type: 'Mobile Navigation Error',
          message: 'Mobile drawer does not close when backdrop is clicked',
          timestamp: new Date().toISOString()
        });
      }
      
      // Take screenshot with menu closed
      await page.screenshot({ 
        path: `${screenshotsDir}/03-mobile-menu-closed.png`,
        fullPage: true 
      });
      console.log('📸 Mobile menu closed screenshot captured');
    }
    
    console.log('\n💻 TESTING DESKTOP VIEW (1200x800)');
    console.log('==================================');
    
    // Set desktop viewport
    await page.setViewportSize({ width: 1200, height: 800 });
    await page.waitForTimeout(1000);
    
    // Take initial desktop screenshot
    await page.screenshot({ 
      path: `${screenshotsDir}/04-desktop-initial.png`,
      fullPage: true 
    });
    console.log('📸 Desktop initial screenshot captured');
    
    // Check if hamburger menu is hidden on desktop
    const hamburgerVisibleOnDesktop = await hamburgerButton.isVisible();
    console.log(`🍔 Hamburger button visible on desktop: ${hamburgerVisibleOnDesktop}`);
    
    if (hamburgerVisibleOnDesktop) {
      errors.push({
        type: 'Desktop Navigation Error',
        message: 'Hamburger menu button should be hidden on desktop but is visible',
        timestamp: new Date().toISOString()
      });
    }
    
    // Check desktop navigation links
    console.log('🔗 Testing desktop navigation links...');
    const desktopNavLinks = await page.locator('.hidden.md\\:ml-10.md\\:flex.md\\:space-x-8 a').all();
    console.log(`🔗 Found ${desktopNavLinks.length} desktop navigation links`);
    
    for (let i = 0; i < desktopNavLinks.length; i++) {
      const link = desktopNavLinks[i];
      const href = await link.getAttribute('href');
      const text = await link.textContent();
      const classes = await link.getAttribute('class');
      const isVisible = await link.isVisible();
      console.log(`🔗 Desktop link ${i + 1}: ${text.trim()} -> ${href} (visible: ${isVisible})`);
      
      if (!isVisible) {
        errors.push({
          type: 'Desktop Navigation Error',
          message: `Desktop navigation link "${text.trim()}" is not visible`,
          timestamp: new Date().toISOString()
        });
      }
    }
    
    // Check desktop stats
    console.log('📊 Testing desktop stats visibility...');
    const desktopStats = await page.locator('.hidden.md\\:flex.items-center.space-x-4');
    const statsVisible = await desktopStats.isVisible();
    console.log(`📊 Desktop stats visible: ${statsVisible}`);
    
    if (!statsVisible) {
      errors.push({
        type: 'Desktop Navigation Error',
        message: 'Desktop stats section is not visible',
        timestamp: new Date().toISOString()
      });
    } else {
      const statsText = await desktopStats.textContent();
      console.log(`📊 Stats content: ${statsText}`);
    }
    
    // Check dark mode toggle
    console.log('🌙 Testing dark mode toggle...');
    const darkModeToggle = await page.locator('button[data-action="click->dark-mode#toggle"]');
    const darkModeVisible = await darkModeToggle.isVisible();
    console.log(`🌙 Dark mode toggle visible: ${darkModeVisible}`);
    
    if (!darkModeVisible) {
      errors.push({
        type: 'Desktop Navigation Error',
        message: 'Dark mode toggle is not visible',
        timestamp: new Date().toISOString()
      });
    }
    
    // Test responsive behavior - switch back to mobile to see if menu works
    console.log('📱 Testing responsive behavior...');
    await page.setViewportSize({ width: 375, height: 667 });
    await page.waitForTimeout(1000);
    
    const hamburgerAfterResize = await page.locator('button[data-mobile-menu-target="button"]');
    const isHamburgerVisibleAfterResize = await hamburgerAfterResize.isVisible();
    console.log(`🍔 Hamburger visible after resize to mobile: ${isHamburgerVisibleAfterResize}`);
    
    if (!isHamburgerVisibleAfterResize) {
      errors.push({
        type: 'Responsive Navigation Error',
        message: 'Hamburger menu does not reappear when resizing to mobile',
        timestamp: new Date().toISOString()
      });
    }
    
    // Take final screenshot
    await page.screenshot({ 
      path: `${screenshotsDir}/05-mobile-after-resize.png`,
      fullPage: true 
    });
    console.log('📸 Mobile after resize screenshot captured');
    
  } catch (error) {
    console.error('❌ Test execution error:', error);
    errors.push({
      type: 'Test Execution Error',
      message: error.message,
      stack: error.stack,
      timestamp: new Date().toISOString()
    });
  }
  
  await browser.close();
  
  // Generate comprehensive report
  console.log('\n📋 NAVBAR INVESTIGATION REPORT');
  console.log('===============================');
  
  console.log(`\n🔍 Total Errors Found: ${errors.length}`);
  if (errors.length > 0) {
    errors.forEach((error, index) => {
      console.log(`\n❌ Error ${index + 1}: ${error.type}`);
      console.log(`   Message: ${error.message}`);
      console.log(`   Time: ${error.timestamp}`);
      if (error.stack) {
        console.log(`   Stack: ${error.stack.substring(0, 200)}...`);
      }
    });
  } else {
    console.log('✅ No errors found in navbar functionality!');
  }
  
  console.log(`\n📝 Console Messages: ${consoleMessages.length}`);
  const errorMessages = consoleMessages.filter(msg => msg.type === 'error');
  const warningMessages = consoleMessages.filter(msg => msg.type === 'warning');
  
  if (errorMessages.length > 0) {
    console.log(`\n❌ Console Errors (${errorMessages.length}):`);
    errorMessages.forEach((msg, index) => {
      console.log(`   ${index + 1}. ${msg.text}`);
    });
  }
  
  if (warningMessages.length > 0) {
    console.log(`\n⚠️  Console Warnings (${warningMessages.length}):`);
    warningMessages.forEach((msg, index) => {
      console.log(`   ${index + 1}. ${msg.text}`);
    });
  }
  
  // Save detailed report to file
  const reportData = {
    timestamp: new Date().toISOString(),
    summary: {
      totalErrors: errors.length,
      consoleErrors: errorMessages.length,
      consoleWarnings: warningMessages.length,
      totalConsoleMessages: consoleMessages.length
    },
    errors: errors,
    consoleMessages: consoleMessages
  };
  
  fs.writeFileSync(
    `${screenshotsDir}/navbar-investigation-report.json`,
    JSON.stringify(reportData, null, 2)
  );
  
  console.log(`\n📁 Investigation complete. Screenshots and report saved to: ${screenshotsDir}`);
  console.log('📋 Detailed JSON report: navbar-investigation-report.json');
})();