import puppeteer from 'puppeteer';

(async () => {
  console.log('Starting authenticated Puppeteer test...');
  
  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  
  const page = await browser.newPage();
  
  // Enable console logging
  page.on('console', msg => {
    const type = msg.type();
    const text = msg.text();
    if (type === 'error') {
      console.log('Browser ERROR:', text);
    } else {
      console.log(`Browser ${type}:`, text);
    }
  });
  
  page.on('pageerror', error => console.log('Page error:', error.message));
  
  // Enable request/response logging for debugging
  page.on('request', request => {
    const url = request.url();
    if (url.includes('/posts/') && url.includes('mark_as_')) {
      console.log('Request to:', request.method(), url);
      console.log('Request headers:', request.headers());
    }
  });
  
  page.on('response', response => {
    const url = response.url();
    if (url.includes('/posts/') && url.includes('mark_as_')) {
      console.log('Response from:', response.status(), url);
      console.log('Response headers:', response.headers());
    }
  });
  
  try {
    // First, let's check if we have any posts in the database
    console.log('Navigating to sources page...');
    await page.goto('http://localhost:3002/sources', { waitUntil: 'networkidle2' });
    
    // Check the current URL - if redirected to login, we'll see it
    const currentUrl = page.url();
    console.log('Current URL:', currentUrl);
    
    // Let's try to navigate directly to posts with authentication bypass
    console.log('Navigating to posts index...');
    await page.goto('http://localhost:3002/posts', { waitUntil: 'networkidle2' });
    
    // Check if we're on the landing page or actual posts
    const isLandingPage = await page.$('h1.text-5xl') !== null;
    console.log('Is landing page?', isLandingPage);
    
    if (!isLandingPage) {
      // We might be on the actual posts page
      const posts = await page.$$('[data-controller="post-actions"]');
      console.log(`Found ${posts.length} posts`);
      
      if (posts.length > 0) {
        // Check Stimulus controller status
        const stimulusStatus = await page.evaluate(() => {
          return {
            stimulusExists: typeof window.Stimulus !== 'undefined',
            controllers: window.Stimulus ? Object.keys(window.Stimulus.application.router.modulesByIdentifier) : []
          };
        });
        console.log('Stimulus status:', stimulusStatus);
        
        // Get first post's buttons
        const buttonInfo = await page.evaluate(() => {
          const firstPost = document.querySelector('[data-controller="post-actions"]');
          if (!firstPost) return null;
          
          const buttons = firstPost.querySelectorAll('button[data-action]');
          return Array.from(buttons).map(btn => ({
            action: btn.dataset.action,
            url: btn.dataset.url,
            title: btn.title,
            innerHTML: btn.innerHTML.substring(0, 100)
          }));
        });
        console.log('Button info:', buttonInfo);
        
        // Try clicking a button and monitor what happens
        const clearButton = await page.$('[data-action="click->post-actions#clear"]');
        if (clearButton) {
          console.log('\n--- Attempting to click clear button ---');
          
          // Monitor the button's HTML before and after
          const beforeHtml = await clearButton.evaluate(el => el.outerHTML);
          console.log('Button before click:', beforeHtml.substring(0, 200));
          
          // Click and wait a bit
          await clearButton.click();
          await page.waitForTimeout(500);
          
          // Check if button still exists and its state
          const stillExists = await page.$('[data-action="click->post-actions#clear"]') !== null;
          if (stillExists) {
            const afterHtml = await clearButton.evaluate(el => el.outerHTML);
            console.log('Button after click:', afterHtml.substring(0, 200));
            
            // Check if it's showing loading spinner
            const hasSpinner = await clearButton.evaluate(el => el.innerHTML.includes('animate-spin'));
            console.log('Has loading spinner?', hasSpinner);
          } else {
            console.log('Button no longer exists after click');
          }
          
          // Check for any fetch errors in console
          const fetchErrors = await page.evaluate(() => {
            return window.__fetchErrors || [];
          });
          if (fetchErrors.length > 0) {
            console.log('Fetch errors:', fetchErrors);
          }
        }
      }
    }
    
    // Take final screenshot
    await page.screenshot({ path: 'dashboard-final-state.png' });
    console.log('Final screenshot saved');
    
  } catch (error) {
    console.error('Test error:', error);
  } finally {
    await browser.close();
  }
})();