import { chromium } from 'playwright';

export async function testNavigationLinks() {
  console.log('🧪 TEST 3: Navigation Links Accessibility');
  console.log('=========================================');
  
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
    
    // Check if menu is open
    const menuOpen = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      return drawer ? drawer.classList.contains('open') : false;
    });
    
    if (!menuOpen) {
      results.errors.push('Menu failed to open for navigation testing');
      results.passed = false;
      await browser.close();
      return results;
    }
    
    // Get all navigation links in the mobile drawer
    const navigationLinks = await page.evaluate(() => {
      const links = Array.from(document.querySelectorAll('.mobile-nav-link'));
      return links.map((link, index) => ({
        index: index + 1,
        text: link.textContent.trim(),
        href: link.getAttribute('href'),
        visible: link.offsetParent !== null,
        hasIcon: !!link.querySelector('svg'),
        classes: link.className,
        isActive: link.classList.contains('active')
      }));
    });
    
    console.log('🔗 Navigation links found:');
    navigationLinks.forEach(link => {
      console.log(`   ${link.index}. "${link.text}" -> ${link.href}`);
      console.log(`      Visible: ${link.visible}, Has icon: ${link.hasIcon}, Active: ${link.isActive}`);
    });
    
    // Test clicking each navigation link
    const linkTests = [];
    for (let i = 0; i < navigationLinks.length; i++) {
      const link = navigationLinks[i];
      console.log(`\n🔗 Testing link ${link.index}: "${link.text}"`);
      
      try {
        // Click the link
        await page.click(`.mobile-nav-link:nth-child(${link.index})`);
        await page.waitForTimeout(1000);
        
        // Check if we navigated (URL should change or page should update)
        const currentUrl = page.url();
        const expectedPath = link.href;
        
        const linkWorking = currentUrl.includes(expectedPath) || expectedPath === '/';
        
        console.log(`   Current URL: ${currentUrl}`);
        console.log(`   Expected path: ${expectedPath}`);
        console.log(`   Link working: ${linkWorking}`);
        
        linkTests.push({
          link: link.text,
          href: link.href,
          working: linkWorking,
          currentUrl: currentUrl
        });
        
        // Go back to original page if we navigated away
        if (!currentUrl.includes('localhost:3002') || currentUrl !== 'http://localhost:3002/') {
          await page.goto('http://localhost:3002', { waitUntil: 'networkidle' });
          await page.waitForTimeout(1000);
          
          // Reopen menu for next test
          if (i < navigationLinks.length - 1) {
            await page.click('button[data-mobile-menu-target="button"]');
            await page.waitForTimeout(600);
          }
        }
        
      } catch (error) {
        console.log(`   ❌ Error testing link: ${error.message}`);
        linkTests.push({
          link: link.text,
          href: link.href,
          working: false,
          error: error.message
        });
      }
    }
    
    // Check mobile stats visibility
    const mobileStats = await page.evaluate(() => {
      // Open menu again to check stats
      const statsSection = document.querySelector('.mobile-nav-body .px-4.py-3');
      if (statsSection) {
        const statsText = statsSection.textContent;
        return {
          exists: true,
          content: statsText.trim(),
          visible: statsSection.offsetParent !== null
        };
      }
      return { exists: false };
    });
    
    console.log('\n📊 Mobile stats section:');
    console.log(`   Exists: ${mobileStats.exists}`);
    if (mobileStats.exists) {
      console.log(`   Content: ${mobileStats.content}`);
      console.log(`   Visible: ${mobileStats.visible}`);
    }
    
    // Determine if test passed
    const workingLinks = linkTests.filter(test => test.working).length;
    const totalLinks = linkTests.length;
    const minRequiredLinks = 3; // Dashboard, Sources, and at least one auth link
    
    const testPassed = totalLinks >= minRequiredLinks && 
                      workingLinks >= minRequiredLinks &&
                      navigationLinks.length > 0;
    
    results.passed = testPassed;
    results.details = {
      navigationLinks,
      linkTests,
      mobileStats,
      workingLinks,
      totalLinks
    };
    
    console.log(`\n📊 Link test summary:`);
    console.log(`   Total links: ${totalLinks}`);
    console.log(`   Working links: ${workingLinks}`);
    console.log(`   Required minimum: ${minRequiredLinks}`);
    
    console.log(`\n${testPassed ? '✅' : '❌'} TEST 3 RESULT: ${testPassed ? 'PASSED' : 'FAILED'}`);
    
    if (!testPassed) {
      if (totalLinks < minRequiredLinks) {
        results.errors.push(`Insufficient navigation links: found ${totalLinks}, need ${minRequiredLinks}`);
      }
      if (workingLinks < minRequiredLinks) {
        results.errors.push(`Too many broken links: ${workingLinks}/${totalLinks} working`);
      }
      if (navigationLinks.length === 0) {
        results.errors.push('No navigation links found in mobile drawer');
      }
    }
    
  } catch (error) {
    results.errors.push(`Test execution error: ${error.message}`);
    console.error('❌ Test 3 Error:', error);
  }
  
  await browser.close();
  return results;
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  testNavigationLinks().then(results => {
    console.log('\n📊 Final Results:', results);
  });
}