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
    slowMo: 50,      // Slow down actions to see what's happening
  });

  const page = await browser.newPage();
  
  // Set viewport size
  await page.setViewport({ width: 1280, height: 800 });

  // Collect console messages
  const consoleLogs = [];
  page.on('console', msg => {
    consoleLogs.push({
      type: msg.type(),
      text: msg.text(),
      location: msg.location()
    });
  });

  // Collect page errors
  const pageErrors = [];
  page.on('pageerror', error => {
    pageErrors.push({
      message: error.message,
      stack: error.stack
    });
  });

  // Monitor network requests
  const networkRequests = [];
  page.on('request', request => {
    if (request.url().includes('localhost')) {
      networkRequests.push({
        method: request.method(),
        url: request.url(),
        headers: request.headers()
      });
    }
  });

  page.on('response', response => {
    if (response.url().includes('localhost')) {
      console.log(`Response: ${response.status()} ${response.url()}`);
    }
  });

  try {
    console.log('Navigating to dashboard...');
    await page.goto('http://localhost:3002', { waitUntil: 'networkidle2' });
    
    // Take initial screenshot
    await page.screenshot({ 
      path: path.join(screenshotsDir, '01_initial_page.png'),
      fullPage: true 
    });
    
    console.log('Current URL:', page.url());

    // Check if we're on the landing page by looking for the heading
    const isLandingPage = await page.$('h1') !== null && 
      await page.$eval('h1', el => el.textContent.includes('Never Miss a Developer Question Again')).catch(() => false);
    
    if (isLandingPage) {
      console.log('Landing page detected. Clicking Sign In...');
      await page.screenshot({ 
        path: path.join(screenshotsDir, '02_landing_page.png'),
        fullPage: true 
      });
      
      // Click Sign In button in navigation
      try {
        await Promise.all([
          page.waitForNavigation({ waitUntil: 'networkidle2' }),
          page.click('text=Sign in')
        ]);
      } catch (e) {
        // Fallback: find link by text content
        const links = await page.$$('a');
        for (const link of links) {
          const text = await link.evaluate(el => el.textContent);
          if (text && text.trim() === 'Sign in') {
            await Promise.all([
              page.waitForNavigation({ waitUntil: 'networkidle2' }),
              link.click()
            ]);
            break;
          }
        }
      }
        
        // Now we should be on the login page
        await page.screenshot({ 
          path: path.join(screenshotsDir, '03_login_page.png'),
          fullPage: true 
        });
        
        // Check if we have login form
        const emailInput = await page.$('input[type="email"]');
        const passwordInput = await page.$('input[type="password"]');
        
        if (emailInput && passwordInput) {
          console.log('Login form found. Using test credentials...');
          
          // Fill in test credentials (from seed data)
          await emailInput.type('dev@example.com');
          await passwordInput.type('password123');
          
          // Submit the form
          const submitButton = await page.$('button[type="submit"]');
          if (submitButton) {
            await Promise.all([
              page.waitForNavigation({ waitUntil: 'networkidle2' }),
              submitButton.click()
            ]);
            
            console.log('Login submitted, checking result...');
            await page.screenshot({ 
              path: path.join(screenshotsDir, '04_after_login.png'),
              fullPage: true 
            });
          }
        } else {
          console.log('Login form not found. Please login manually and run the test again.');
          await browser.close();
          return;
        }
      } else {
        console.log('Sign in button not found');
        await browser.close();
        return;
      }
    }

    // Wait for posts to load
    console.log('Waiting for posts to load...');
    const postsExist = await page.waitForSelector('[data-controller="post-actions"]', { 
      timeout: 10000 
    }).catch(() => null);

    if (!postsExist) {
      console.log('No posts found on the page.');
      await page.screenshot({ 
        path: path.join(screenshotsDir, '03_no_posts.png'),
        fullPage: true 
      });
      await browser.close();
      return;
    }

    // Get all post cards
    const postCards = await page.$$('[data-controller="post-actions"]');
    console.log(`Found ${postCards.length} posts on the page.`);

    // Take screenshot with posts loaded
    await page.screenshot({ 
      path: path.join(screenshotsDir, '05_posts_loaded.png'),
      fullPage: true 
    });

    // Test the first post if available
    if (postCards.length > 0) {
      console.log('\nTesting post action buttons on the first post...');
      
      // Check for action buttons
      const readButton = await postCards[0].$('button[data-action*="markAsRead"]');
      const clearButton = await postCards[0].$('button[data-action*="clear"]');
      const respondButton = await postCards[0].$('button[data-action*="markAsResponded"]');

      console.log('Action buttons found:');
      console.log('- Read button:', readButton !== null);
      console.log('- Clear button:', clearButton !== null);
      console.log('- Respond button:', respondButton !== null);

      // Test Mark as Read button
      if (readButton) {
        console.log('\nTesting "Mark as Read" button...');
        
        // Clear network requests
        networkRequests.length = 0;
        
        // Take screenshot before clicking
        await page.screenshot({ 
          path: path.join(screenshotsDir, '05_before_mark_as_read.png'),
          fullPage: true 
        });

        // Click the read button
        await readButton.click();
        
        // Wait a bit for the request to complete
        await page.waitForTimeout(2000);
        
        // Take screenshot after clicking
        await page.screenshot({ 
          path: path.join(screenshotsDir, '06_after_mark_as_read.png'),
          fullPage: true 
        });

        // Check network requests
        const readRequests = networkRequests.filter(req => 
          req.url.includes('mark_as_read')
        );
        console.log(`Network requests for mark_as_read: ${readRequests.length}`);
        readRequests.forEach(req => {
          console.log(`  - ${req.method} ${req.url}`);
        });
      }

      // Test Clear button on another post
      const secondPost = postCards[1];
      if (secondPost) {
        const clearButton2 = await secondPost.$('button[data-action*="clear"]');
        
        if (clearButton2) {
          console.log('\nTesting "Clear" button on second post...');
          
          // Clear network requests
          networkRequests.length = 0;
          
          // Take screenshot before clicking
          await page.screenshot({ 
            path: path.join(screenshotsDir, '07_before_clear.png'),
            fullPage: true 
          });

          // Click the clear button
          await clearButton2.click();
          
          // Wait for animation and request
          await page.waitForTimeout(2000);
          
          // Take screenshot after clicking
          await page.screenshot({ 
            path: path.join(screenshotsDir, '08_after_clear.png'),
            fullPage: true 
          });

          // Check network requests
          const clearRequests = networkRequests.filter(req => 
            req.url.includes('mark_as_ignored')
          );
          console.log(`Network requests for mark_as_ignored: ${clearRequests.length}`);
          clearRequests.forEach(req => {
            console.log(`  - ${req.method} ${req.url}`);
          });
        }
      }

      // Test Respond button on third post
      const thirdPost = postCards[2];
      if (thirdPost) {
        const respondButton3 = await thirdPost.$('button[data-action*="markAsResponded"]');
        
        if (respondButton3) {
          console.log('\nTesting "Responded" button on third post...');
          
          // Clear network requests
          networkRequests.length = 0;
          
          // Take screenshot before clicking
          await page.screenshot({ 
            path: path.join(screenshotsDir, '09_before_responded.png'),
            fullPage: true 
          });

          // Click the respond button
          await respondButton3.click();
          
          // Wait for request
          await page.waitForTimeout(2000);
          
          // Take screenshot after clicking
          await page.screenshot({ 
            path: path.join(screenshotsDir, '10_after_responded.png'),
            fullPage: true 
          });

          // Check network requests
          const respondRequests = networkRequests.filter(req => 
            req.url.includes('mark_as_responded')
          );
          console.log(`Network requests for mark_as_responded: ${respondRequests.length}`);
          respondRequests.forEach(req => {
            console.log(`  - ${req.method} ${req.url}`);
          });
        }
      }
    }

    // Print console logs
    console.log('\n=== Browser Console Logs ===');
    consoleLogs.forEach(log => {
      console.log(`[${log.type}] ${log.text}`);
    });

    // Print any errors
    if (pageErrors.length > 0) {
      console.log('\n=== Page Errors ===');
      pageErrors.forEach(error => {
        console.log(error.message);
        if (error.stack) {
          console.log(error.stack);
        }
      });
    } else {
      console.log('\n✅ No JavaScript errors detected!');
    }

    // Take final screenshot
    await page.screenshot({ 
      path: path.join(screenshotsDir, '11_final_state.png'),
      fullPage: true 
    });

    console.log(`\n📸 Screenshots saved to: ${screenshotsDir}`);

  } catch (error) {
    console.error('Error during test:', error);
    await page.screenshot({ 
      path: path.join(screenshotsDir, 'error_state.png'),
      fullPage: true 
    });
  } finally {
    // Keep browser open for inspection
    console.log('\n⏸️  Browser will remain open for inspection. Press Ctrl+C to close.');
    // await browser.close();
  }
}

// Run the test
testPostActions().catch(console.error);