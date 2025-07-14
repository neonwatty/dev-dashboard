const puppeteer = require('puppeteer');

(async () => {
  console.log('Starting Puppeteer test...');
  
  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  
  const page = await browser.newPage();
  
  // Enable console logging
  page.on('console', msg => console.log('Browser console:', msg.text()));
  page.on('pageerror', error => console.log('Page error:', error.message));
  
  // Enable request logging
  page.on('request', request => {
    if (request.url().includes('/posts/')) {
      console.log('Request:', request.method(), request.url());
    }
  });
  
  page.on('response', response => {
    if (response.url().includes('/posts/')) {
      console.log('Response:', response.status(), response.url());
    }
  });
  
  try {
    // Visit the dashboard
    console.log('Navigating to http://localhost:3002...');
    await page.goto('http://localhost:3002', { waitUntil: 'networkidle2' });
    
    // Take initial screenshot
    await page.screenshot({ path: 'dashboard-initial.png' });
    console.log('Initial screenshot saved');
    
    // Check if there are any posts
    const posts = await page.$$('[data-controller="post-actions"]');
    console.log(`Found ${posts.length} posts on the page`);
    
    if (posts.length > 0) {
      // Get button information
      const buttons = await page.evaluate(() => {
        const buttons = document.querySelectorAll('[data-action*="post-actions"]');
        return Array.from(buttons).map(btn => ({
          action: btn.dataset.action,
          url: btn.dataset.url,
          title: btn.title,
          hasOnclick: !!btn.onclick
        }));
      });
      console.log('Buttons found:', JSON.stringify(buttons, null, 2));
      
      // Try clicking the first clear button
      const clearButton = await page.$('[data-action="click->post-actions#clear"]');
      if (clearButton) {
        console.log('Clicking clear button...');
        
        // Get initial HTML of button
        const initialHTML = await page.evaluate(el => el.innerHTML, clearButton);
        console.log('Initial button HTML:', initialHTML);
        
        await clearButton.click();
        await page.waitForTimeout(1000);
        
        // Get HTML after click
        const afterHTML = await page.evaluate(el => el ? el.innerHTML : 'Button removed', clearButton);
        console.log('Button HTML after click:', afterHTML);
        
        // Take screenshot after click
        await page.screenshot({ path: 'dashboard-after-clear.png' });
        console.log('Screenshot after clear saved');
      }
      
      // Check for any network errors
      const errors = await page.evaluate(() => {
        return window.__errors || [];
      });
      if (errors.length > 0) {
        console.log('JavaScript errors:', errors);
      }
    }
    
  } catch (error) {
    console.error('Test error:', error);
  } finally {
    await browser.close();
  }
})();