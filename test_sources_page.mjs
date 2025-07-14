import puppeteer from 'puppeteer';

(async () => {
  console.log('Testing sources page refresh functionality...');
  
  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  
  const page = await browser.newPage();
  
  // Enable console logging
  page.on('console', msg => console.log('Browser console:', msg.text()));
  page.on('pageerror', error => console.log('Page error:', error.message));
  
  // Monitor WebSocket connections
  page.on('websocket', ws => {
    console.log('WebSocket created:', ws.url());
  });
  
  try {
    console.log('Navigating to sources page...');
    await page.goto('http://localhost:3002/sources', { waitUntil: 'networkidle2' });
    
    const currentUrl = page.url();
    console.log('Current URL:', currentUrl);
    
    // Check if we're on the sources page or redirected
    if (currentUrl.includes('/session/new')) {
      console.log('Redirected to login page - app requires authentication');
    } else {
      // Check for refresh buttons
      const refreshButtons = await page.$$('button[title="Refresh"]');
      console.log(`Found ${refreshButtons.length} refresh buttons`);
      
      // Check for Turbo Stream subscriptions
      const turboStreamSubscriptions = await page.evaluate(() => {
        const subscriptions = document.querySelectorAll('turbo-stream-source');
        return Array.from(subscriptions).map(sub => sub.getAttribute('href'));
      });
      console.log('Turbo Stream subscriptions:', turboStreamSubscriptions);
      
      // Check ActionCable status
      const cableStatus = await page.evaluate(() => {
        if (typeof App !== 'undefined' && App.cable) {
          return {
            connected: App.cable.connection.isActive(),
            state: App.cable.connection.getState()
          };
        }
        return { error: 'ActionCable not found' };
      });
      console.log('ActionCable status:', cableStatus);
      
      // If we have refresh buttons, try clicking one
      if (refreshButtons.length > 0) {
        console.log('\nClicking first refresh button...');
        
        // Monitor network requests
        page.on('request', request => {
          if (request.url().includes('/refresh')) {
            console.log('Refresh request:', request.method(), request.url());
          }
        });
        
        page.on('response', response => {
          if (response.url().includes('/refresh')) {
            console.log('Refresh response:', response.status(), response.headers()['location']);
          }
        });
        
        await refreshButtons[0].click();
        await page.waitForTimeout(2000);
        
        // Check for any notices or alerts
        const notices = await page.evaluate(() => {
          const notice = document.querySelector('[role="alert"]');
          return notice ? notice.textContent : null;
        });
        
        if (notices) {
          console.log('Page notice:', notices);
        }
      }
    }
    
    await page.screenshot({ path: 'sources-page-test.png' });
    console.log('Screenshot saved');
    
  } catch (error) {
    console.error('Test error:', error);
  } finally {
    await browser.close();
  }
})();