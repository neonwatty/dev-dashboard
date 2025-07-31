import { chromium } from 'playwright';

export async function testNavigationLinksSimple() {
  console.log('🧪 TEST 3: Navigation Links Accessibility (Simplified)');
  console.log('====================================================');
  
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
    
    // Open mobile menu
    console.log('🍔 Opening mobile menu...');
    await page.click('button[data-mobile-menu-target="button"]');
    await page.waitForTimeout(600);
    
    // Verify menu is open
    const menuOpen = await page.evaluate(() => {
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      return drawer ? drawer.classList.contains('open') : false;
    });
    
    if (!menuOpen) {
      results.errors.push('Menu failed to open');
      results.passed = false;
      await browser.close();
      return results;
    }
    
    // Get all navigation links
    const navigationLinks = await page.evaluate(() => {
      const links = Array.from(document.querySelectorAll('.mobile-nav-link'));
      return links.map((link, index) => ({
        index: index + 1,
        text: link.textContent.trim(),
        href: link.getAttribute('href'),
        visible: link.offsetParent !== null,
        hasIcon: !!link.querySelector('svg'),
        rect: link.getBoundingClientRect(),
        clickable: true // We'll test this
      }));
    });
    
    console.log('🔗 Found navigation links:');
    navigationLinks.forEach(link => {
      console.log(`   ${link.index}. "${link.text}" → ${link.href}`);
      console.log(`      Visible: ${link.visible}, Has icon: ${link.hasIcon}`);
      console.log(`      Position: (${Math.round(link.rect.x)}, ${Math.round(link.rect.y)})`);
    });
    
    // Test link clickability without navigation
    const clickabilityTests = [];
    
    for (const link of navigationLinks) {
      console.log(`\n🔗 Testing clickability of "${link.text}"...`);
      
      try {
        // Create a custom click test that doesn't navigate
        const clickResult = await page.evaluate((linkIndex) => {
          const links = document.querySelectorAll('.mobile-nav-link');
          const targetLink = links[linkIndex - 1];
          
          if (!targetLink) return { success: false, error: 'Link not found' };
          
          // Check if link is interactable
          const rect = targetLink.getBoundingClientRect();
          const isInViewport = rect.x >= 0 && rect.y >= 0 && 
                              rect.right <= window.innerWidth && 
                              rect.bottom <= window.innerHeight;
          
          const isVisible = targetLink.offsetParent !== null;
          const hasCorrectHref = targetLink.getAttribute('href') !== null;
          
          return {
            success: isInViewport && isVisible && hasCorrectHref,
            isInViewport,
            isVisible,
            hasCorrectHref,
            href: targetLink.getAttribute('href')
          };
        }, link.index);
        
        clickabilityTests.push({
          link: link.text,
          ...clickResult
        });
        
        console.log(`   ${clickResult.success ? '✅' : '❌'} Clickable: ${clickResult.success}`);
        if (!clickResult.success) {
          console.log(`      In viewport: ${clickResult.isInViewport}`);
          console.log(`      Visible: ${clickResult.isVisible}`);
          console.log(`      Has href: ${clickResult.hasCorrectHref}`);
        }
        
      } catch (error) {
        clickabilityTests.push({
          link: link.text,
          success: false,
          error: error.message
        });
        console.log(`   ❌ Error: ${error.message}`);
      }
    }
    
    // Check mobile stats section
    const mobileStats = await page.evaluate(() => {
      const statsContainer = document.querySelector('.mobile-nav-body .px-4.py-3');
      if (statsContainer) {
        const statsTexts = Array.from(statsContainer.querySelectorAll('.text-sm'))
                                .map(el => el.textContent.trim());
        return {
          exists: true,
          visible: statsContainer.offsetParent !== null,
          content: statsTexts
        };
      }
      return { exists: false };
    });
    
    console.log('\n📊 Mobile stats section:');
    console.log(`   Exists: ${mobileStats.exists}`);
    if (mobileStats.exists) {
      console.log(`   Visible: ${mobileStats.visible}`);
      console.log(`   Content: ${mobileStats.content.join(', ')}`);
    }
    
    // Determine test success
    const totalLinks = navigationLinks.length;
    const clickableLinks = clickabilityTests.filter(test => test.success).length;
    const requiredMinimum = 3;
    
    const hasRequiredLinks = totalLinks >= requiredMinimum;
    const allLinksClickable = clickableLinks === totalLinks;
    const hasBasicNavigation = navigationLinks.some(link => link.text === 'Dashboard') &&
                              navigationLinks.some(link => link.text === 'Sources');
    
    const testPassed = hasRequiredLinks && allLinksClickable && hasBasicNavigation;
    
    results.passed = testPassed;
    results.details = {
      navigationLinks,
      clickabilityTests,
      mobileStats,
      summary: {
        totalLinks,
        clickableLinks,
        requiredMinimum,
        hasRequiredLinks,
        allLinksClickable,
        hasBasicNavigation
      }
    };
    
    console.log(`\n📊 Test Summary:`);
    console.log(`   Total links: ${totalLinks}`);
    console.log(`   Clickable links: ${clickableLinks}`);
    console.log(`   Required minimum: ${requiredMinimum}`);
    console.log(`   Has basic navigation: ${hasBasicNavigation}`);
    
    console.log(`\n${testPassed ? '✅' : '❌'} TEST 3 RESULT: ${testPassed ? 'PASSED' : 'FAILED'}`);
    
    if (!testPassed) {
      if (!hasRequiredLinks) {
        results.errors.push(`Insufficient navigation links: ${totalLinks} < ${requiredMinimum}`);
      }
      if (!allLinksClickable) {
        results.errors.push(`Some links not clickable: ${clickableLinks}/${totalLinks}`);
      }
      if (!hasBasicNavigation) {
        results.errors.push('Missing basic navigation links (Dashboard, Sources)');
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
  testNavigationLinksSimple().then(results => {
    console.log('\n📊 Final Results:', results);
  });
}