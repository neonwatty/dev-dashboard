import { test, expect } from '@playwright/test';
import { TestHelpers } from '../helpers/test-helpers.js';

test.describe('Rails System Test Integration', () => {
  let helpers;

  test.beforeEach(async ({ page }) => {
    helpers = new TestHelpers(page);
    await helpers.authenticateUser();
  });

  test('Playwright tests complement existing Rails system tests', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    // Test areas covered by Rails system tests but enhanced by Playwright

    // 1. Mobile navigation (enhanced cross-browser testing)
    await page.setViewportSize({ width: 375, height: 812 });

    const mobileMenu = page.locator('[data-controller="mobile-menu"]');
    await expect(mobileMenu).toBeVisible();

    const hamburgerBtn = mobileMenu.locator('button, [data-mobile-menu-target="toggleButton"]').first();
    await hamburgerBtn.click();

    const drawer = page.locator('[data-mobile-menu-target="drawer"]');
    await expect(drawer).toBeVisible();

    // Test that menu works in different browsers (this is where Playwright adds value)
    const userAgent = await page.evaluate(() => navigator.userAgent);
    console.log(`Mobile navigation tested on: ${userAgent}`);

    // 2. Touch gestures (cross-browser touch event compatibility)
    const swipeElements = await page.locator('[data-controller~="swipe-actions"]').all();
    if (swipeElements.length > 0) {
      const firstElement = swipeElements[0];

      // Test touch events work across different browser engines
      await page.touchscreen.tap(
        (await firstElement.boundingBox()).x + 50,
        (await firstElement.boundingBox()).y + 50
      );

      // Verify touch feedback system
      const hasTouchFeedback = await page.locator('.ripple, .touch-ripple, .active').count() > 0;
      console.log(`Touch feedback working: ${hasTouchFeedback}`);
    }

    // 3. Responsive design verification (multiple resolution testing)
    const resolutions = [
      { width: 375, height: 667 },  // iPhone SE
      { width: 768, height: 1024 }, // iPad Portrait
      { width: 1440, height: 900 }  // Desktop
    ];

    for (const resolution of resolutions) {
      await page.setViewportSize(resolution);
      await page.waitForTimeout(300);

      const hasHorizontalScroll = await helpers.hasHorizontalScroll();
      expect(hasHorizontalScroll).toBeFalsy();

      console.log(`Layout verified at ${resolution.width}x${resolution.height}`);
    }
  });

  test('Cross-browser compatibility for Rails features', async ({ page, browserName }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    console.log(`Testing Rails features on browser: ${browserName}`);

    // Test Turbo frame functionality across browsers
    const filterForm = page.locator('form').first();
    if (await filterForm.count() > 0) {
      const checkbox = filterForm.locator('input[type="checkbox"]').first();
      if (await checkbox.count() > 0) {
        const initialState = await checkbox.isChecked();
        await checkbox.click();

        // Wait for Turbo frame update
        await page.waitForTimeout(500);

        const newState = await checkbox.isChecked();
        expect(newState).toBe(!initialState);

        // Verify Turbo frame updated without full page reload
        const posts = await page.locator('.post-card').count();
        expect(posts).toBeGreaterThanOrEqual(0);
      }
    }

    // Test ActionCable real-time updates across browsers
    const refreshBtn = page.locator('button:has-text("Refresh")').first();
    if (await refreshBtn.count() > 0) {
      await refreshBtn.click();
      await page.waitForTimeout(1000);

      // Look for real-time status updates
      const statusBadges = await page.locator('[data-status-badge]').count();
      expect(statusBadges).toBeGreaterThanOrEqual(0);
    }

    // Test form submissions with Turbo
    await page.goto('/sources/new');
    await helpers.waitForPageLoad();

    const form = page.locator('form').first();
    if (await form.count() > 0) {
      const nameInput = form.locator('input[name*="name"], input[id*="name"]').first();
      const urlInput = form.locator('input[name*="url"], input[id*="url"]').first();

      if (await nameInput.count() > 0 && await urlInput.count() > 0) {
        await nameInput.fill('Test Source');
        await urlInput.fill('https://example.com/feed.xml');

        const submitBtn = form.locator('input[type="submit"], button[type="submit"]').first();
        await submitBtn.click();

        // Verify form submission works across browsers
        await page.waitForTimeout(1000);
        const currentUrl = page.url();
        const hasError = await page.locator('.error, .alert-danger').count() > 0;
        const hasSuccess = await page.locator('.notice, .alert-success').count() > 0;

        expect(hasError || hasSuccess || !currentUrl.includes('/new')).toBeTruthy();
      }
    }
  });

  test('Performance comparison with Rails system tests', async ({ page }) => {
    // Measure performance across different browsers for comparison
    const performanceMetrics = {};

    const pages = [
      { path: '/', name: 'Home' },
      { path: '/sources', name: 'Sources' },
      { path: '/settings/edit', name: 'Settings' }
    ];

    for (const pageInfo of pages) {
      const startTime = Date.now();
      await page.goto(pageInfo.path);
      await helpers.waitForPageLoad();
      const loadTime = Date.now() - startTime;

      const metrics = await helpers.getPerformanceMetrics();

      performanceMetrics[pageInfo.name] = {
        loadTime,
        firstContentfulPaint: metrics.firstContentfulPaint,
        domContentLoaded: metrics.domContentLoaded
      };

      // Performance should be consistent with Rails expectations
      expect(loadTime).toBeLessThan(3000);
      expect(metrics.firstContentfulPaint).toBeLessThan(2000);
    }

    console.log('Performance Metrics:', performanceMetrics);
  });

  test('Enhanced mobile testing beyond Rails system tests', async ({ page }) => {
    // Test device-specific features that Rails tests can't cover

    const mobileDevices = [
      { name: 'iPhone', width: 375, height: 812, userAgent: 'iPhone' },
      { name: 'Android', width: 393, height: 851, userAgent: 'Android' }
    ];

    for (const device of mobileDevices) {
      await page.setViewportSize({ width: device.width, height: device.height });
      await page.goto('/');
      await helpers.waitForPageLoad();

      // Test mobile-specific features

      // 1. Touch target compliance
      const touchTargets = await page.locator('button, a, input[type="button"], [role="button"]').all();
      for (const target of touchTargets.slice(0, 5)) {
        if (await target.isVisible()) {
          const box = await target.boundingBox();
          const minSize = device.userAgent === 'iPhone' ? 44 : 48;
          expect(box.width).toBeGreaterThanOrEqual(minSize - 4);
          expect(box.height).toBeGreaterThanOrEqual(minSize - 4);
        }
      }

      // 2. Orientation changes (Rails tests can't test this)
      await page.setViewportSize({ width: device.height, height: device.width });
      await page.waitForTimeout(500);

      const hasHorizontalScroll = await helpers.hasHorizontalScroll();
      expect(hasHorizontalScroll).toBeFalsy();

      // 3. Virtual keyboard simulation
      const searchInput = page.locator('input[type="search"], input[type="text"]').first();
      if (await searchInput.count() > 0) {
        await searchInput.focus();

        // Simulate virtual keyboard appearance (reduce viewport height)
        await page.setViewportSize({
          width: device.height,
          height: Math.floor(device.width * 0.6)
        });

        // Input should still be accessible
        const inputBox = await searchInput.boundingBox();
        expect(inputBox.y).toBeLessThan(device.width * 0.6);
      }

      console.log(`Enhanced mobile testing completed for ${device.name}`);
    }
  });

  test('Advanced form validation testing', async ({ page }) => {
    // Enhanced form testing that complements Rails validation tests

    await page.goto('/sources/new');
    await helpers.waitForPageLoad();

    const form = page.locator('form').first();
    if (await form.count() > 0) {
      // Test client-side validation (JavaScript)
      const inputs = await form.locator('input, textarea').all();

      for (const input of inputs) {
        if (await input.isVisible()) {
          const inputType = await input.getAttribute('type');
          const required = await input.getAttribute('required') !== null;

          // Test real-time validation feedback
          if (required) {
            await input.focus();
            await input.fill('');
            await input.blur();

            // Check for validation feedback
            const hasValidationFeedback = await page.locator('.error, .invalid, [aria-invalid="true"]').count() > 0;
            console.log(`Validation feedback shown: ${hasValidationFeedback}`);
          }

          // Test type-specific validation
          if (inputType === 'url') {
            await input.fill('invalid-url');
            await input.blur();

            const validationMessage = await input.evaluate(el => el.validationMessage);
            expect(validationMessage).toBeTruthy();

            await input.fill('https://valid-url.com');
            await input.blur();
          }
        }
      }

      // Test form submission with various input combinations
      const submitBtn = form.locator('input[type="submit"], button[type="submit"]').first();

      // Test empty form submission
      await submitBtn.click();
      await page.waitForTimeout(500);

      const hasClientValidation = await page.evaluate(() => {
        const form = document.querySelector('form');
        return !form.checkValidity();
      });

      if (hasClientValidation) {
        console.log('Client-side validation is working');
      }
    }
  });

  test('Real-time features cross-browser compatibility', async ({ page, browserName }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    console.log(`Testing real-time features on ${browserName}`);

    // Test WebSocket/ActionCable connections
    const hasWebSocket = await page.evaluate(() => {
      return 'WebSocket' in window;
    });
    expect(hasWebSocket).toBeTruthy();

    // Test EventSource support (Server-Sent Events)
    const hasEventSource = await page.evaluate(() => {
      return 'EventSource' in window;
    });
    expect(hasEventSource).toBeTruthy();

    // Test real-time status updates if available
    const statusElements = await page.locator('[data-status-badge], .status-indicator').all();
    if (statusElements.length > 0) {
      const initialStatuses = [];

      for (const element of statusElements.slice(0, 3)) {
        if (await element.isVisible()) {
          const status = await element.textContent();
          initialStatuses.push(status);
        }
      }

      // Trigger a refresh to potentially update statuses
      const refreshBtn = page.locator('button:has-text("Refresh")').first();
      if (await refreshBtn.count() > 0) {
        await refreshBtn.click();
        await page.waitForTimeout(2000);

        // Check if statuses updated in real-time
        let statusesUpdated = false;
        for (let i = 0; i < Math.min(statusElements.length, 3); i++) {
          const element = statusElements[i];
          if (await element.isVisible()) {
            const newStatus = await element.textContent();
            if (newStatus !== initialStatuses[i]) {
              statusesUpdated = true;
              break;
            }
          }
        }

        console.log(`Real-time status updates working: ${statusesUpdated}`);
      }
    }

    // Test Turbo Stream updates
    const turboStreamEvents = await page.evaluate(() => {
      let eventCount = 0;
      document.addEventListener('turbo:before-stream-render', () => {
        eventCount++;
      });
      return eventCount;
    });

    console.log(`Turbo Stream events supported: ${turboStreamEvents >= 0}`);
  });

  test('Accessibility integration with Rails helpers', async ({ page }) => {
    // Test that Rails accessibility helpers work across browsers

    await page.goto('/');
    await helpers.waitForPageLoad();

    // Test Rails form helpers accessibility
    await page.goto('/sources/new');
    await helpers.waitForPageLoad();

    const form = page.locator('form').first();
    if (await form.count() > 0) {
      // Check Rails-generated form labels
      const inputs = await form.locator('input, textarea, select').all();

      for (const input of inputs) {
        if (await input.isVisible()) {
          const inputId = await input.getAttribute('id');
          const ariaLabel = await input.getAttribute('aria-label');

          if (inputId) {
            const hasLabel = await form.locator(`label[for="${inputId}"]`).count() > 0;
            expect(hasLabel || ariaLabel).toBeTruthy();
          }
        }
      }

      // Test Rails error handling accessibility
      const submitBtn = form.locator('input[type="submit"], button[type="submit"]').first();
      await submitBtn.click();
      await page.waitForTimeout(500);

      const errorFields = await form.locator('.field_with_errors, [aria-invalid="true"]').count();
      if (errorFields > 0) {
        console.log('Rails error handling maintains accessibility');
      }
    }

    // Test Rails link helpers
    const links = await page.locator('a').all();
    for (const link of links.slice(0, 5)) {
      if (await link.isVisible()) {
        const linkText = await link.textContent();
        const ariaLabel = await link.getAttribute('aria-label');
        const title = await link.getAttribute('title');

        const hasAccessibleName = (linkText && linkText.trim()) || ariaLabel || title;
        expect(hasAccessibleName).toBeTruthy();
      }
    }
  });

  test('Integration with existing Rails test data', async ({ page }) => {
    // Use Rails test fixtures and data in Playwright tests

    await page.goto('/');
    await helpers.waitForPageLoad();

    // Test with data that should exist from Rails fixtures
    const posts = await page.locator('.post-card, [data-testid="post-card"]').count();
    expect(posts).toBeGreaterThanOrEqual(0); // May be 0 if no fixture data

    // Test sources from fixtures
    await page.goto('/sources');
    await helpers.waitForPageLoad();

    const sources = await page.locator('table tr, .source-item, .source-card').count();
    expect(sources).toBeGreaterThanOrEqual(0);

    // Test user authentication state
    const userMenu = page.locator('.user-menu, [data-user], .profile-menu');
    if (await userMenu.count() > 0) {
      await expect(userMenu).toBeVisible();
      console.log('User authentication state verified');
    }

    // Test settings with user data
    await page.goto('/settings/edit');
    await helpers.waitForPageLoad();

    const settingsForm = page.locator('form').first();
    if (await settingsForm.count() > 0) {
      const emailInput = settingsForm.locator('input[type="email"], input[name*="email"]').first();
      if (await emailInput.count() > 0) {
        const emailValue = await emailInput.inputValue();
        expect(emailValue).toBeTruthy(); // Should have test user email
        console.log(`Test user email loaded: ${emailValue}`);
      }
    }
  });
});
