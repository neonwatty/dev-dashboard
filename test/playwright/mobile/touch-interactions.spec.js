import { test, expect } from '@playwright/test';
import { TestHelpers, MobileTestHelpers } from '../helpers/test-helpers.js';

test.describe('Advanced Touch Interactions Testing', () => {
  let helpers;
  let mobileHelpers;

  test.beforeEach(async ({ page }) => {
    helpers = new TestHelpers(page);
    mobileHelpers = new MobileTestHelpers(page);
    await helpers.authenticateUser();
    // Set to mobile viewport
    await page.setViewportSize({ width: 375, height: 812 });
  });

  test('Swipe gestures work correctly with existing touch controllers', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    // Verify swipe controllers are initialized
    const swipeElements = await page.locator('[data-controller~="swipe-actions"]').all();
    expect(swipeElements.length).toBeGreaterThan(0);

    const firstSwipeElement = swipeElements[0];

    // Verify swipe indicators are present
    const swipeWrapper = await firstSwipeElement.locator('..').first(); // Parent wrapper
    await expect(swipeWrapper.locator('.swipe-indicator-left, .swipe-indicator-right')).toHaveCount({ min: 1 });

    // Test left swipe (clear action)
    await mobileHelpers.simulateSwipe(firstSwipeElement, 'left', 150);
    await page.waitForTimeout(500);

    // Verify swipe action visual feedback
    const leftIndicator = swipeWrapper.locator('.swipe-indicator-left');
    if (await leftIndicator.count() > 0) {
      const indicatorVisible = await leftIndicator.isVisible();
      // During swipe, indicator should become visible
      expect(indicatorVisible).toBeTruthy();
    }

    // Test right swipe (mark as read action)
    await mobileHelpers.simulateSwipe(firstSwipeElement, 'right', 150);
    await page.waitForTimeout(500);

    // Verify right swipe indicator
    const rightIndicator = swipeWrapper.locator('.swipe-indicator-right');
    if (await rightIndicator.count() > 0) {
      const indicatorVisible = await rightIndicator.isVisible();
      expect(indicatorVisible).toBeTruthy();
    }

    // Test swipe threshold behavior
    await mobileHelpers.simulateSwipe(firstSwipeElement, 'left', 50); // Partial swipe
    await page.waitForTimeout(500);

    // Element should return to original position for partial swipe
    const transform = await firstSwipeElement.evaluate(el => {
      return window.getComputedStyle(el).transform;
    });
    expect(transform).toBe('none'); // Should return to original position
  });

  test('Long press functionality creates contextual menus', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    const longPressElements = await page.locator('[data-controller~="long-press"]').all();
    expect(longPressElements.length).toBeGreaterThan(0);

    const firstElement = longPressElements[0];
    const elementBox = await firstElement.boundingBox();

    // Simulate long press using page coordinates
    await page.mouse.move(elementBox.x + elementBox.width/2, elementBox.y + elementBox.height/2);
    await page.mouse.down();
    await page.waitForTimeout(600); // Wait for long press threshold
    await page.mouse.up();

    // Verify context menu appears
    await expect(page.locator('.long-press-menu')).toBeVisible();

    // Verify menu has action items
    const menuActions = await page.locator('.long-press-menu .long-press-action').all();
    expect(menuActions.length).toBeGreaterThan(0);

    // Verify menu actions have appropriate touch targets
    for (const action of menuActions) {
      const actionBox = await action.boundingBox();
      expect(actionBox.height).toBeGreaterThanOrEqual(44);
      expect(actionBox.width).toBeGreaterThanOrEqual(44);
    }

    // Test menu dismissal
    await page.click('body'); // Click outside menu
    await page.waitForTimeout(300);
    await expect(page.locator('.long-press-menu')).not.toBeVisible();

    // Test auto-dismissal after timeout
    await page.mouse.move(elementBox.x + elementBox.width/2, elementBox.y + elementBox.height/2);
    await page.mouse.down();
    await page.waitForTimeout(600);
    await page.mouse.up();

    await expect(page.locator('.long-press-menu')).toBeVisible();

    // Wait for auto-dismissal (should happen after 3 seconds)
    await page.waitForTimeout(3500);
    await expect(page.locator('.long-press-menu')).not.toBeVisible();
  });

  test('Pull-to-refresh functionality works smoothly', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    // Verify pull-to-refresh controller is present
    await expect(page.locator('[data-controller="pull-to-refresh"]')).toBeVisible();

    // Scroll to top to ensure pull-to-refresh can be triggered
    await page.evaluate(() => window.scrollTo(0, 0));
    await page.waitForTimeout(300);

    // Verify refresh indicator exists but is initially hidden
    const refreshIndicator = page.locator('.pull-refresh-indicator');
    await expect(refreshIndicator).toBeAttached();

    // Simulate pull gesture
    await page.mouse.move(200, 50);
    await page.mouse.down();
    await page.mouse.move(200, 150, { steps: 10 });
    await page.waitForTimeout(300);

    // During pull, indicator should become visible
    const indicatorVisible = await refreshIndicator.isVisible();
    expect(indicatorVisible).toBeTruthy();

    // Complete the pull gesture
    await page.mouse.move(200, 200);
    await page.waitForTimeout(500);
    await page.mouse.up();

    // Verify refresh was triggered (loading state or page refresh)
    const hasLoadingState = await page.locator('.loading, .spinner, .refreshing').count() > 0;
    const hasRefreshMessage = await page.locator('.refreshed, .updated').count() > 0;

    // Either loading state should appear or content should refresh
    expect(hasLoadingState || hasRefreshMessage).toBeTruthy();

    // Test pull-to-refresh only works at top of page
    await page.evaluate(() => window.scrollTo(0, 100)); // Scroll down
    await page.waitForTimeout(300);

    // Try pull gesture when not at top
    await page.mouse.move(200, 100);
    await page.mouse.down();
    await page.mouse.move(200, 200);
    await page.waitForTimeout(300);
    await page.mouse.up();

    // Refresh should not trigger when not at top
    const scrollY = await page.evaluate(() => window.scrollY);
    expect(scrollY).toBeGreaterThan(0); // Should still be scrolled down
  });

  test('Touch feedback provides appropriate visual and haptic response', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    const touchFeedbackElements = await page.locator('[data-controller="touch-feedback"]').all();
    expect(touchFeedbackElements.length).toBeGreaterThan(0);

    for (const element of touchFeedbackElements.slice(0, 3)) {
      if (await element.isVisible()) {
        const elementBox = await element.boundingBox();

        // Simulate touch start
        await page.mouse.move(elementBox.x + elementBox.width/2, elementBox.y + elementBox.height/2);
        await page.mouse.down();
        await page.waitForTimeout(100);

        // Check for active state during touch
        const hasActiveState = await element.evaluate(el => {
          return el.classList.contains('active') ||
                 el.classList.contains('pressed') ||
                 el.classList.contains('touch-active');
        });

        // Check for ripple effect
        const hasRippleEffect = await page.locator('.ripple, .touch-ripple').count() > 0;

        await page.mouse.up();
        await page.waitForTimeout(200);

        // Active state should be removed after touch ends
        const stillActive = await element.evaluate(el => {
          return el.classList.contains('active') ||
                 el.classList.contains('pressed') ||
                 el.classList.contains('touch-active');
        });

        expect(hasActiveState || hasRippleEffect).toBeTruthy();
        expect(stillActive).toBeFalsy();
      }
    }

    // Test that touch feedback doesn't interfere with functionality
    const button = page.locator('button[data-controller="touch-feedback"]').first();
    if (await button.count() > 0) {
      const initialUrl = page.url();
      await button.click();
      await page.waitForTimeout(500);

      // Button should still function normally
      const urlChanged = page.url() !== initialUrl;
      const hasResponse = await page.locator('.notification, .alert, .flash').count() > 0;

      expect(urlChanged || hasResponse).toBeTruthy();
    }
  });

  test('Touch gestures work correctly across different viewport sizes', async ({ page }) => {
    const mobileViewports = [
      { width: 320, height: 568 }, // iPhone 5
      { width: 375, height: 667 }, // iPhone 6/7/8
      { width: 414, height: 896 }, // iPhone XR
      { width: 390, height: 844 }  // iPhone 12
    ];

    for (const viewport of mobileViewports) {
      await page.setViewportSize(viewport);
      await page.goto('/');
      await helpers.waitForPageLoad();

      // Test swipe gestures at different viewport sizes
      const swipeElements = await page.locator('[data-controller~="swipe-actions"]').all();
      if (swipeElements.length > 0) {
        const element = swipeElements[0];
        const success = await mobileHelpers.testTouchGestures();
        expect(success).toBeTruthy();
      }

      // Test pull-to-refresh at different sizes
      const pullRefreshSuccess = await mobileHelpers.testPullToRefresh();
      expect(pullRefreshSuccess).toBeTruthy();

      // Test long press at different sizes
      const longPressSuccess = await mobileHelpers.testLongPress();
      expect(longPressSuccess).toBeTruthy();

      // Verify no horizontal scrolling at any size
      const hasHorizontalScroll = await helpers.hasHorizontalScroll();
      expect(hasHorizontalScroll).toBeFalsy();
    }
  });

  test('Touch gestures handle edge cases correctly', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    const swipeElement = page.locator('[data-controller~="swipe-actions"]').first();
    const elementBox = await swipeElement.boundingBox();

    // Test rapid successive swipes
    for (let i = 0; i < 3; i++) {
      await mobileHelpers.simulateSwipe(swipeElement, 'left', 100);
      await page.waitForTimeout(100);
      await mobileHelpers.simulateSwipe(swipeElement, 'right', 100);
      await page.waitForTimeout(100);
    }

    // Element should handle rapid swipes gracefully
    const finalTransform = await swipeElement.evaluate(el => {
      return window.getComputedStyle(el).transform;
    });
    expect(finalTransform).toBe('none'); // Should return to neutral position

    // Test interrupted swipe (finger moves too far off target)
    await page.mouse.move(elementBox.x + elementBox.width/2, elementBox.y + elementBox.height/2);
    await page.mouse.down();
    await page.mouse.move(elementBox.x - 50, elementBox.y + 100); // Move off target
    await page.mouse.up();

    // Swipe should be cancelled
    const interruptedTransform = await swipeElement.evaluate(el => {
      return window.getComputedStyle(el).transform;
    });
    expect(interruptedTransform).toBe('none');

    // Test swipe with very small movement (should not trigger)
    await mobileHelpers.simulateSwipe(swipeElement, 'left', 10);
    await page.waitForTimeout(300);

    const smallSwipeTransform = await swipeElement.evaluate(el => {
      return window.getComputedStyle(el).transform;
    });
    expect(smallSwipeTransform).toBe('none'); // Should not trigger for small movements

    // Test long press cancellation when finger moves
    const longPressElement = page.locator('[data-controller~="long-press"]').first();
    const longPressBox = await longPressElement.boundingBox();

    await page.mouse.move(longPressBox.x + longPressBox.width/2, longPressBox.y + longPressBox.height/2);
    await page.mouse.down();
    await page.waitForTimeout(300); // Partial long press
    await page.mouse.move(longPressBox.x + 50, longPressBox.y + 50); // Move finger
    await page.waitForTimeout(400);
    await page.mouse.up();

    // Long press menu should not appear
    await expect(page.locator('.long-press-menu')).not.toBeVisible();
  });

  test('Touch interactions work correctly in dark mode', async ({ page }) => {
    // Enable dark mode
    await page.goto('/');
    await helpers.waitForPageLoad();

    // Toggle dark mode if available
    const darkModeToggle = page.locator('[data-controller="dark-mode"], .dark-mode-toggle, [aria-label*="theme"]');
    if (await darkModeToggle.count() > 0) {
      await darkModeToggle.click();
      await page.waitForTimeout(300);
    } else {
      // Force dark mode via JavaScript
      await page.evaluate(() => {
        document.documentElement.classList.add('dark');
      });
    }

    // Verify dark mode is active
    const isDarkMode = await page.evaluate(() => {
      return document.documentElement.classList.contains('dark') ||
             document.body.classList.contains('dark-theme');
    });
    expect(isDarkMode).toBeTruthy();

    // Test all touch interactions in dark mode
    const swipeSuccess = await mobileHelpers.testTouchGestures();
    expect(swipeSuccess).toBeTruthy();

    const pullRefreshSuccess = await mobileHelpers.testPullToRefresh();
    expect(pullRefreshSuccess).toBeTruthy();

    const longPressSuccess = await mobileHelpers.testLongPress();
    expect(longPressSuccess).toBeTruthy();

    // Test touch feedback visibility in dark mode
    const touchFeedbackElement = page.locator('[data-controller="touch-feedback"]').first();
    if (await touchFeedbackElement.count() > 0) {
      await touchFeedbackElement.click();
      await page.waitForTimeout(100);

      // Visual feedback should be visible against dark background
      const hasVisibleFeedback = await page.evaluate(() => {
        const ripples = document.querySelectorAll('.ripple, .touch-ripple');
        for (const ripple of ripples) {
          const style = window.getComputedStyle(ripple);
          if (style.opacity !== '0' && style.display !== 'none') {
            return true;
          }
        }
        return false;
      });

      expect(hasVisibleFeedback).toBeTruthy();
    }
  });

  test('Touch performance remains smooth under load', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    // Measure baseline performance
    const startTime = performance.now();

    // Perform intensive touch interactions
    const swipeElements = await page.locator('[data-controller~="swipe-actions"]').all();

    for (let i = 0; i < Math.min(swipeElements.length, 10); i++) {
      const element = swipeElements[i];

      // Rapid swipe gestures
      await mobileHelpers.simulateSwipe(element, 'left', 100);
      await page.waitForTimeout(50);
      await mobileHelpers.simulateSwipe(element, 'right', 100);
      await page.waitForTimeout(50);
    }

    const swipeTime = performance.now();

    // Test touch feedback performance
    const touchElements = await page.locator('[data-controller="touch-feedback"]').all();

    for (let i = 0; i < Math.min(touchElements.length, 10); i++) {
      await touchElements[i].click();
      await page.waitForTimeout(25);
    }

    const endTime = performance.now();

    // Total time should be reasonable
    const totalTime = endTime - startTime;
    expect(totalTime).toBeLessThan(5000); // Should complete within 5 seconds

    // Check for any JavaScript errors during intensive interactions
    const jsErrors = await page.evaluate(() => {
      return window.jsErrors || [];
    });
    expect(jsErrors.length).toBe(0);

    // Verify memory hasn't grown excessively
    const memoryUsage = await page.evaluate(() => {
      return performance.memory ? performance.memory.usedJSHeapSize : 0;
    });

    if (memoryUsage > 0) {
      expect(memoryUsage).toBeLessThan(50 * 1024 * 1024); // Less than 50MB
    }

    // Verify all touch controllers are still responsive
    const finalSwipeTest = await mobileHelpers.testTouchGestures();
    expect(finalSwipeTest).toBeTruthy();
  });

  test('Touch accessibility features work correctly', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    // Test that touch elements have proper ARIA attributes
    const touchElements = await page.locator('[data-controller~="swipe-actions"], [data-controller~="long-press"], [data-controller="touch-feedback"]').all();

    for (const element of touchElements.slice(0, 5)) {
      if (await element.isVisible()) {
        // Check for accessibility attributes
        const ariaLabel = await element.getAttribute('aria-label');
        const ariaDescribedBy = await element.getAttribute('aria-describedby');
        const role = await element.getAttribute('role');
        const tabIndex = await element.getAttribute('tabindex');

        // Touch elements should be keyboard accessible or have proper ARIA
        const hasAccessibility = ariaLabel || ariaDescribedBy || role || tabIndex !== null;
        expect(hasAccessibility).toBeTruthy();

        // Test keyboard activation of touch elements
        await element.focus();
        const isFocused = await element.evaluate(el => el === document.activeElement);

        if (isFocused) {
          // Try activating with keyboard
          await page.keyboard.press('Enter');
          await page.waitForTimeout(300);

          // Should provide some feedback or action
          const hasKeyboardResponse = await page.locator('.notification, .alert, .active, .selected').count() > 0;
          expect(hasKeyboardResponse).toBeTruthy();
        }
      }
    }

    // Test touch target size compliance for accessibility
    await helpers.verifyAllTouchTargets();

    // Test that swipe actions are announced to screen readers
    const swipeElement = page.locator('[data-controller~="swipe-actions"]').first();
    if (await swipeElement.count() > 0) {
      // Check for screen reader announcements
      const hasAriaLive = await page.locator('[aria-live], [aria-atomic]').count() > 0;

      // Perform swipe action
      await mobileHelpers.simulateSwipe(swipeElement, 'right', 150);
      await page.waitForTimeout(500);

      // Should have some form of announcement or feedback
      const hasStatusUpdate = await page.locator('[aria-live] *', '[role="status"]').count() > 0;
      expect(hasAriaLive || hasStatusUpdate).toBeTruthy();
    }
  });
});
