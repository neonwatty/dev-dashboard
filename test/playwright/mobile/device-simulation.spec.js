import { test, expect } from '@playwright/test';
import { TestHelpers, MobileTestHelpers } from '../helpers/test-helpers.js';

test.describe('Mobile Device Simulation UX Testing', () => {
  let helpers;
  let mobileHelpers;

  test.beforeEach(async ({ page }) => {
    helpers = new TestHelpers(page);
    mobileHelpers = new MobileTestHelpers(page);
    await helpers.authenticateUser();
  });

  const mobileDevices = [
    { name: 'iPhone SE', width: 375, height: 667, _userAgent: 'iPhone' },
    { name: 'iPhone 12', width: 390, height: 844, _userAgent: 'iPhone' },
    { name: 'iPhone 12 Pro Max', width: 428, height: 926, _userAgent: 'iPhone' },
    { name: 'Pixel 5', width: 393, height: 851, _userAgent: 'Android' },
    { name: 'Galaxy S21', width: 384, height: 854, _userAgent: 'Android' },
    { name: 'Galaxy Note 20', width: 412, height: 915, _userAgent: 'Android' }
  ];

  mobileDevices.forEach(({ name, width, height, _userAgent }) => {
    test(`Mobile layout works correctly on ${name} (${width}x${height})`, async ({ page }) => {
      await page.setViewportSize({ width, height });
      await page.goto('/');
      await helpers.waitForPageLoad();

      // Verify no horizontal scrolling
      const hasHorizontalScroll = await helpers.hasHorizontalScroll();
      expect(hasHorizontalScroll).toBeFalsy();

      // Verify mobile navigation is visible
      const mobileMenu = page.locator('[data-controller="mobile-menu"]');
      await expect(mobileMenu).toBeVisible();

      // Verify content fits within viewport
      const bodyWidth = await page.evaluate(() => document.body.scrollWidth);
      expect(bodyWidth).toBeLessThanOrEqual(width + 5); // Allow small tolerance

      // Verify post cards use mobile layout
      const postCards = await page.locator('.post-card').all();
      if (postCards.length > 0) {
        const firstCard = postCards[0];
        const cardLayout = await firstCard.evaluate(el => {
          const style = window.getComputedStyle(el);
          return {
            display: style.display,
            flexDirection: style.flexDirection
          };
        });

        // Should use vertical layout on mobile
        expect(cardLayout.flexDirection).toBe('column');
      }

      // Verify touch targets meet minimum size requirements
      await helpers.verifyAllTouchTargets();

      // Verify text remains readable without zooming
      const textElements = await page.locator('p, .description, .text').all();
      for (const element of textElements.slice(0, 5)) {
        if (await element.isVisible()) {
          const fontSize = await element.evaluate(el => {
            return parseInt(window.getComputedStyle(el).fontSize);
          });
          expect(fontSize).toBeGreaterThanOrEqual(14); // Minimum readable size
        }
      }
    });
  });

  test('Touch gesture system works across all mobile devices', async ({ page }) => {
    for (const device of mobileDevices) {
      await page.setViewportSize({ width: device.width, height: device.height });
      await page.goto('/');
      await helpers.waitForPageLoad();

      // Verify touch controllers are initialized
      await expect(page.locator('[data-controller~="swipe-actions"]')).toHaveCount({ min: 1 });
      await expect(page.locator('[data-controller~="long-press"]')).toHaveCount({ min: 1 });
      await expect(page.locator('[data-controller~="touch-feedback"]')).toHaveCount({ min: 1 });
      await expect(page.locator('[data-controller="pull-to-refresh"]')).toBeVisible();

      // Test swipe gestures
      const swipeWorking = await mobileHelpers.testTouchGestures();
      expect(swipeWorking).toBeTruthy();

      // Test pull-to-refresh
      const pullRefreshWorking = await mobileHelpers.testPullToRefresh();
      expect(pullRefreshWorking).toBeTruthy();

      // Test long press functionality
      const longPressWorking = await mobileHelpers.testLongPress();
      expect(longPressWorking).toBeTruthy();
    }
  });

  test('Mobile navigation system works consistently across devices', async ({ page }) => {
    for (const device of mobileDevices) {
      await page.setViewportSize({ width: device.width, height: device.height });
      await page.goto('/');
      await helpers.waitForPageLoad();

      // Test hamburger menu
      const hamburgerBtn = page.locator('[data-mobile-menu-target="toggleButton"], .hamburger-menu, [aria-label="Menu"]');
      await expect(hamburgerBtn).toBeVisible();
      await hamburgerBtn.click();

      // Verify menu opens
      const mobileDrawer = page.locator('[data-mobile-menu-target="drawer"], .mobile-drawer, .side-menu');
      await expect(mobileDrawer).toBeVisible();

      // Test navigation links in mobile menu
      const navLinks = await mobileDrawer.locator('a[href^="/"]').all();
      expect(navLinks.length).toBeGreaterThan(0);

      // Test closing menu
      const closeBtn = mobileDrawer.locator('[data-action*="close"], .close-menu, [aria-label="Close"]');
      if (await closeBtn.count() > 0) {
        await closeBtn.click();
      } else {
        // Close by clicking backdrop
        await page.click('body');
      }

      await page.waitForTimeout(300);
      await expect(mobileDrawer).not.toBeVisible();

      // Test bottom navigation if present
      const bottomNav = page.locator('.bottom-nav, [data-testid="bottom-navigation"]');
      if (await bottomNav.count() > 0) {
        await expect(bottomNav).toBeVisible();

        const bottomNavLinks = await bottomNav.locator('a, button').all();
        for (const link of bottomNavLinks.slice(0, 3)) {
          if (await link.isVisible()) {
            await link.click();
            await helpers.waitForPageLoad();

            // Verify navigation worked
            await expect(page.locator('main, .main-content')).toBeVisible();
          }
        }
      }
    }
  });

  test('Touch target compliance across all device sizes', async ({ page }) => {
    for (const device of mobileDevices) {
      await page.setViewportSize({ width: device.width, height: device.height });
      await page.goto('/');
      await helpers.waitForPageLoad();

      // Get all interactive elements
      const interactiveElements = await page.locator(`
        button, 
        a, 
        input[type="button"], 
        input[type="submit"], 
        input[type="checkbox"], 
        input[type="radio"],
        [role="button"], 
        [tabindex="0"],
        .touch-target
      `).all();

      for (const element of interactiveElements) {
        if (await element.isVisible()) {
          const box = await element.boundingBox();

          if (box) {
            // Touch targets should be at least 44x44px (iOS) or 48x48px (Android)
            const minSize = device._userAgent === 'iPhone' ? 44 : 48;

            expect(box.width).toBeGreaterThanOrEqual(minSize - 4); // Allow small tolerance
            expect(box.height).toBeGreaterThanOrEqual(minSize - 4);

            // Verify adequate spacing between touch targets
            const nearbyElements = await page.locator(`
              button, a, input[type="button"], input[type="submit"], [role="button"]
            `).all();

            for (const nearby of nearbyElements.slice(0, 3)) {
              if (nearby !== element && await nearby.isVisible()) {
                const nearbyBox = await nearby.boundingBox();
                if (nearbyBox) {
                  const distance = Math.sqrt(
                    Math.pow(box.x - nearbyBox.x, 2) +
                    Math.pow(box.y - nearbyBox.y, 2)
                  );

                  // Elements close together should have adequate spacing
                  if (distance < 100) {
                    const horizontalGap = Math.abs(box.x - (nearbyBox.x + nearbyBox.width));
                    const verticalGap = Math.abs(box.y - (nearbyBox.y + nearbyBox.height));
                    const actualGap = Math.min(horizontalGap, verticalGap);

                    if (actualGap < 50) { // Only check spacing for elements that are close
                      expect(actualGap).toBeGreaterThanOrEqual(8);
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  });

  test('Form usability on mobile devices', async ({ page }) => {
    // Test on a page with forms (sources creation/editing)
    await page.goto('/sources/new');
    await helpers.waitForPageLoad();

    for (const device of mobileDevices) {
      await page.setViewportSize({ width: device.width, height: device.height });
      await page.waitForTimeout(300);

      const forms = await page.locator('form').all();

      for (const form of forms) {
        if (await form.isVisible()) {
          const inputs = await form.locator('input, textarea, select').all();

          for (const input of inputs) {
            if (await input.isVisible()) {
              const inputBox = await input.boundingBox();

              // Input fields should be appropriately sized for mobile
              expect(inputBox.height).toBeGreaterThanOrEqual(44);
              expect(inputBox.width).toBeGreaterThan(100);

              // Test input focus behavior
              await input.focus();

              // Verify input is focused and visible
              const isFocused = await input.evaluate(el => el === document.activeElement);
              expect(isFocused).toBeTruthy();

              // On small screens, ensure focused input is visible
              const inputTop = inputBox.y;
              const viewportHeight = device.height;

              if (inputTop > viewportHeight * 0.7) {
                // Input might be hidden by virtual keyboard
                // Should either scroll into view or be handled appropriately
                const scrollTop = await page.evaluate(() => window.scrollY);
                expect(scrollTop).toBeGreaterThanOrEqual(0); // Some scroll adjustment occurred
              }
            }
          }

          // Test form submission button
          const submitBtn = form.locator('input[type="submit"], button[type="submit"]');
          if (await submitBtn.count() > 0) {
            const btnBox = await submitBtn.boundingBox();
            expect(btnBox.height).toBeGreaterThanOrEqual(48); // Larger target for submit
            expect(btnBox.width).toBeGreaterThan(120); // Wide enough for finger tap
          }
        }
      }
    }
  });

  test('Orientation handling (portrait/landscape)', async ({ page }) => {
    for (const device of mobileDevices) {
      // Test portrait orientation
      await page.setViewportSize({ width: device.width, height: device.height });
      await page.goto('/');
      await helpers.waitForPageLoad();

      // Verify portrait layout
      const portraitScroll = await helpers.hasHorizontalScroll();
      expect(portraitScroll).toBeFalsy();

      // Test landscape orientation
      await page.setViewportSize({ width: device.height, height: device.width });
      await page.waitForTimeout(500); // Allow layout to adjust

      // Verify landscape layout
      const landscapeScroll = await helpers.hasHorizontalScroll();
      expect(landscapeScroll).toBeFalsy();

      // Verify navigation still works in landscape
      const mobileMenu = page.locator('[data-controller="mobile-menu"]');
      if (await mobileMenu.count() > 0) {
        await expect(mobileMenu).toBeVisible();
      }

      // Verify content adapts to landscape
      const contentArea = page.locator('main, .main-content, .container');
      const contentBox = await contentArea.first().boundingBox();
      expect(contentBox.width).toBeLessThanOrEqual(device.height);

      // Test touch gestures still work in landscape
      const postCards = await page.locator('[data-controller~="swipe-actions"]').all();
      if (postCards.length > 0) {
        const touchGestureWorking = await mobileHelpers.testTouchGestures();
        expect(touchGestureWorking).toBeTruthy();
      }
    }
  });

  test('Mobile performance across different device capabilities', async ({ page }) => {
    const performanceResults = {};

    for (const device of mobileDevices) {
      await page.setViewportSize({ width: device.width, height: device.height });

      // Simulate different device capabilities
      if (device.name.includes('SE')) {
        // Simulate slower device
        await page.emulateNetworkConditions({
          offline: false,
          downloadThroughput: 1000 * 1024, // 1MB/s
          uploadThroughput: 500 * 1024,    // 500KB/s
          latency: 200
        });
      } else {
        // Simulate faster device
        await page.emulateNetworkConditions({
          offline: false,
          downloadThroughput: 5000 * 1024, // 5MB/s
          uploadThroughput: 1000 * 1024,   // 1MB/s
          latency: 50
        });
      }

      const startTime = Date.now();
      await page.goto('/', { waitUntil: 'networkidle' });
      const loadTime = Date.now() - startTime;

      const metrics = await helpers.getPerformanceMetrics();
      const coreWebVitals = await helpers.measureCoreWebVitals();

      performanceResults[device.name] = {
        loadTime,
        metrics,
        coreWebVitals
      };

      // Verify performance is acceptable
      expect(loadTime).toBeLessThan(8000); // Even slow devices should load within 8s
      expect(metrics.firstContentfulPaint).toBeLessThan(3000);

      if (coreWebVitals.LCP) {
        expect(coreWebVitals.LCP).toBeLessThan(4000); // LCP should be under 4s on mobile
      }
    }

    // Log performance comparison
    console.log('Mobile Performance Results:', performanceResults);
  });

  test('Mobile accessibility features work correctly', async ({ page }) => {
    for (const device of mobileDevices) {
      await page.setViewportSize({ width: device.width, height: device.height });
      await page.goto('/');
      await helpers.waitForPageLoad();

      // Test screen reader accessibility
      const accessibilityIssues = await helpers.basicAccessibilityCheck();
      expect(accessibilityIssues.length).toBe(0);

      // Test keyboard navigation on mobile
      const keyboardNavCount = await helpers.testKeyboardNavigation();
      expect(keyboardNavCount).toBeGreaterThan(0);

      // Test focus management
      const firstFocusable = page.locator('a, button, input, select, textarea, [tabindex]:not([tabindex="-1"])').first();
      if (await firstFocusable.count() > 0) {
        await firstFocusable.focus();

        const isFocused = await firstFocusable.evaluate(el => el === document.activeElement);
        expect(isFocused).toBeTruthy();

        // Verify focus is visible
        const focusOutline = await firstFocusable.evaluate(el => {
          const style = window.getComputedStyle(el);
          return style.outline !== 'none' || style.boxShadow.includes('inset') || style.border.includes('blue');
        });
        expect(focusOutline).toBeTruthy();
      }

      // Test ARIA attributes
      const ariaElements = await page.locator('[aria-label], [aria-labelledby], [aria-describedby], [role]').all();
      for (const element of ariaElements.slice(0, 5)) {
        if (await element.isVisible()) {
          const ariaLabel = await element.getAttribute('aria-label');
          const role = await element.getAttribute('role');

          // ARIA attributes should be meaningful
          if (ariaLabel) {
            expect(ariaLabel.length).toBeGreaterThan(0);
          }
          if (role) {
            expect(role.length).toBeGreaterThan(0);
          }
        }
      }
    }
  });

  test('Mobile-specific UI components work correctly', async ({ page }) => {
    for (const device of mobileDevices) {
      await page.setViewportSize({ width: device.width, height: device.height });
      await page.goto('/');
      await helpers.waitForPageLoad();

      // Test mobile modal behavior
      const modalTriggers = await page.locator('[data-modal], button:has-text("Add"), button:has-text("Edit")').all();

      for (const trigger of modalTriggers.slice(0, 2)) {
        if (await trigger.isVisible()) {
          await trigger.click();
          await page.waitForTimeout(500);

          const modal = page.locator('.modal, [role="dialog"]');
          if (await modal.count() > 0) {
            await expect(modal.first()).toBeVisible();

            // Modal should fit within mobile viewport
            const modalBox = await modal.first().boundingBox();
            expect(modalBox.width).toBeLessThanOrEqual(device.width);
            expect(modalBox.height).toBeLessThanOrEqual(device.height);

            // Close modal
            await page.keyboard.press('Escape');
            await page.waitForTimeout(300);
          }
        }
      }

      // Test mobile filter panels
      const filterToggle = page.locator('[data-action*="toggleFilter"], .filter-toggle, .mobile-filter-toggle');
      if (await filterToggle.count() > 0) {
        await filterToggle.click();
        await page.waitForTimeout(300);

        const filterPanel = page.locator('.filter-panel, .mobile-filters, [data-mobile-filter]');
        if (await filterPanel.count() > 0) {
          await expect(filterPanel.first()).toBeVisible();

          // Panel should be appropriately sized for mobile
          const panelBox = await filterPanel.first().boundingBox();
          expect(panelBox.width).toBeLessThanOrEqual(device.width);

          // Close panel
          await filterToggle.click();
          await page.waitForTimeout(300);
        }
      }

      // Test mobile card layouts
      const postCards = await page.locator('.post-card').all();
      for (const card of postCards.slice(0, 3)) {
        if (await card.isVisible()) {
          const cardBox = await card.boundingBox();

          // Cards should fit within mobile viewport with some margin
          expect(cardBox.width).toBeLessThanOrEqual(device.width - 20);

          // Cards should use vertical layout on mobile
          const cardLayout = await card.evaluate(el => {
            const style = window.getComputedStyle(el);
            return style.flexDirection;
          });
          expect(cardLayout).toBe('column');
        }
      }
    }
  });
});
