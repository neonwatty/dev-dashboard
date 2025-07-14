import puppeteer from 'puppeteer';
import { mkdir } from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

// Get dirname for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function testPostActions() {
  // Create screenshots directory if it doesn't exist
  const screenshotsDir = path.join(__dirname, 'puppeteer_screenshots');
  await mkdir(screenshotsDir, { recursive: true });

  const browser = await puppeteer.launch({
    headless: false, // Show browser for debugging
    devtools: true,  // Open DevTools automatically
    slowMo: 100,     // Slow down actions to see what's happening
  });

  const page = await browser.newPage();
  
  // Set viewport size
  await page.setViewport({ width: 1280, height: 800 });

  // Collect console messages
  const consoleLogs = [];
  page.on('console', msg => {
    const text = msg.text();
    console.log(`Browser console [${msg.type()}]: ${text}`);
    consoleLogs.push({
      type: msg.type(),
      text: text,
      location: msg.location()
    });
  });

  // Collect page errors
  const pageErrors = [];
  page.on('pageerror', error => {
    console.error('Page error:', error.message);
    pageErrors.push({
      message: error.message,
      stack: error.stack
    });
  });

  // Monitor network requests for action buttons
  const actionRequests = [];
  page.on('request', request => {
    const url = request.url();
    if (url.includes('mark_as_read') || url.includes('mark_as_ignored') || url.includes('mark_as_responded')) {
      console.log(`Action request: ${request.method()} ${url}`);
      actionRequests.push({
        method: request.method(),
        url: url,
        timestamp: new Date()
      });
    }
  });

  page.on('response', response => {
    const url = response.url();
    if (url.includes('mark_as_read') || url.includes('mark_as_ignored') || url.includes('mark_as_responded')) {
      console.log(`Action response: ${response.status()} ${url}`);
    }
  });

  try {
    console.log('Step 1: Navigating to sign in page directly...');
    await page.goto('http://localhost:3002/session/new', { waitUntil: 'networkidle2' });
    
    // Take screenshot of login page
    await page.screenshot({ 
      path: path.join(screenshotsDir, '01_login_page.png'),
      fullPage: true 
    });

    console.log('Step 2: Logging in with test credentials...');
    // Fill in the login form
    await page.type('input[type="email"]', 'dev@example.com');
    await page.type('input[type="password"]', 'password123');
    
    // Submit the form - look for the Sign in button
    const submitButton = await page.$('input[type="submit"][value="Sign in"]') || 
                        await page.$('button:has-text("Sign in")') ||
                        await page.$('input[value="Sign in"]');
    
    if (submitButton) {
      await Promise.all([
        page.waitForNavigation({ waitUntil: 'networkidle2' }),
        submitButton.click()
      ]);
    } else {
      // Fallback: submit the form directly
      await Promise.all([
        page.waitForNavigation({ waitUntil: 'networkidle2' }),
        page.evaluate(() => document.querySelector('form').submit())
      ]);
    }

    console.log('Step 3: Logged in, current URL:', page.url());
    
    // Take screenshot after login
    await page.screenshot({ 
      path: path.join(screenshotsDir, '02_after_login.png'),
      fullPage: true 
    });

    // Wait for posts to load
    console.log('Step 4: Waiting for posts to load...');
    await page.waitForSelector('[data-controller="post-actions"]', { timeout: 10000 });

    // Get all post cards
    const postCards = await page.$$('[data-controller="post-actions"]');
    console.log(`\nFound ${postCards.length} posts on the page.`);

    // Take screenshot with posts
    await page.screenshot({ 
      path: path.join(screenshotsDir, '03_posts_loaded.png'),
      fullPage: true 
    });

    if (postCards.length === 0) {
      console.log('No posts found to test.');
      await browser.close();
      return;
    }

    // Test different action buttons
    console.log('\n=== Testing Post Action Buttons ===\n');

    // Test 1: Mark as Read
    console.log('Test 1: Testing "Mark as Read" button...');
    const firstPost = postCards[0];
    const readButton = await firstPost.$('[data-action*="markAsRead"]');
    
    if (readButton) {
      console.log('Found read button, clicking...');
      actionRequests.length = 0; // Clear previous requests
      
      await readButton.click();
      await new Promise(resolve => setTimeout(resolve, 2000)); // Wait for request to complete
      
      await page.screenshot({ 
        path: path.join(screenshotsDir, '04_after_mark_as_read.png'),
        fullPage: true 
      });
      
      console.log(`Mark as read requests: ${actionRequests.filter(r => r.url.includes('mark_as_read')).length}`);
    } else {
      console.log('No read button found on first post (might already be read)');
    }

    // Test 2: Clear/Ignore
    console.log('\nTest 2: Testing "Clear" button...');
    const secondPost = postCards.length > 1 ? postCards[1] : postCards[0];
    const clearButton = await secondPost.$('[data-action*="clear"]');
    
    if (clearButton) {
      console.log('Found clear button, clicking...');
      actionRequests.length = 0; // Clear previous requests
      
      await clearButton.click();
      await new Promise(resolve => setTimeout(resolve, 2000)); // Wait for request and animation
      
      await page.screenshot({ 
        path: path.join(screenshotsDir, '05_after_clear.png'),
        fullPage: true 
      });
      
      console.log(`Clear/ignore requests: ${actionRequests.filter(r => r.url.includes('mark_as_ignored')).length}`);
      
      // Check if the post was removed from DOM
      const remainingPosts = await page.$$('[data-controller="post-actions"]');
      console.log(`Posts remaining after clear: ${remainingPosts.length}`);
    } else {
      console.log('No clear button found');
    }

    // Test 3: Mark as Responded
    console.log('\nTest 3: Testing "Responded" button...');
    // Refresh to get fresh posts
    await page.reload({ waitUntil: 'networkidle2' });
    await page.waitForSelector('[data-controller="post-actions"]', { timeout: 10000 });
    
    const freshPosts = await page.$$('[data-controller="post-actions"]');
    if (freshPosts.length > 0) {
      const respondButton = await freshPosts[0].$('[data-action*="markAsResponded"]');
      
      if (respondButton) {
        console.log('Found respond button, clicking...');
        actionRequests.length = 0; // Clear previous requests
        
        await respondButton.click();
        await new Promise(resolve => setTimeout(resolve, 2000)); // Wait for request
        
        await page.screenshot({ 
          path: path.join(screenshotsDir, '06_after_responded.png'),
          fullPage: true 
        });
        
        console.log(`Responded requests: ${actionRequests.filter(r => r.url.includes('mark_as_responded')).length}`);
      } else {
        console.log('No respond button found');
      }
    }

    // Summary
    console.log('\n=== Test Summary ===');
    console.log(`Total console logs: ${consoleLogs.length}`);
    console.log(`Total page errors: ${pageErrors.length}`);
    console.log(`Total action requests: ${actionRequests.length}`);
    
    if (pageErrors.length > 0) {
      console.log('\n⚠️  JavaScript Errors Detected:');
      pageErrors.forEach(error => {
        console.log(`- ${error.message}`);
      });
    } else {
      console.log('\n✅ No JavaScript errors detected!');
    }

    console.log(`\n📸 Screenshots saved to: ${screenshotsDir}`);
    
    // Take final screenshot
    await page.screenshot({ 
      path: path.join(screenshotsDir, '07_final_state.png'),
      fullPage: true 
    });

  } catch (error) {
    console.error('Test error:', error);
    await page.screenshot({ 
      path: path.join(screenshotsDir, 'error_state.png'),
      fullPage: true 
    });
  } finally {
    console.log('\n⏸️  Browser will remain open for inspection. Press Ctrl+C to close.');
    // Don't close browser so we can inspect
    // await browser.close();
  }
}

// Run the test
testPostActions().catch(console.error);