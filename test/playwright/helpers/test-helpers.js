import { expect } from '@playwright/test';

/**
 * Helper functions for Playwright tests
 */

export class TestHelpers {
  constructor(page) {
    this.page = page;
  }

  /**
   * Wait for page to be fully loaded including all async content
   */
  async waitForPageLoad() {
    await this.page.waitForLoadState('networkidle');
    await this.page.waitForLoadState('domcontentloaded');
    // Wait for Stimulus controllers to initialize
    await this.page.waitForTimeout(500);
  }

  /**
   * Authenticate user for tests that require login
   */
  async authenticateUser(email = 'user@example.com', password = 'password') {
    await this.page.goto('/sessions/new');
    await this.page.fill('input[name="email_address"]', email);
    await this.page.fill('input[name="password"]', password);
    await this.page.click('button[type="submit"]');
    await this.page.waitForURL('/');
    await this.waitForPageLoad();
  }

  /**
   * Check if element meets minimum touch target size
   */
  async verifyTouchTargetSize(selector, minSize = 44) {
    const element = this.page.locator(selector);
    const box = await element.boundingBox();

    if (box) {
      expect(box.width).toBeGreaterThanOrEqual(minSize);
      expect(box.height).toBeGreaterThanOrEqual(minSize);
    }
  }

  /**
   * Verify all touch targets on page meet accessibility standards
   */
  async verifyAllTouchTargets() {
    const touchTargets = await this.page.locator('button, a, input[type="button"], input[type="submit"], [role="button"]').all();

    for (const target of touchTargets) {
      if (await target.isVisible()) {
        const box = await target.boundingBox();
        if (box) {
          expect(box.width).toBeGreaterThanOrEqual(44);
          expect(box.height).toBeGreaterThanOrEqual(44);
        }
      }
    }
  }

  /**
   * Measure Core Web Vitals
   */
  async measureCoreWebVitals() {
    const metrics = await this.page.evaluate(() => {
      return new Promise((resolve) => {
        const observer = new PerformanceObserver((list) => {
          const entries = list.getEntries();
          const vitals = {};

          entries.forEach((entry) => {
            if (entry.entryType === 'largest-contentful-paint') {
              vitals.LCP = entry.startTime;
            }
            if (entry.entryType === 'first-input') {
              vitals.FID = entry.processingStart - entry.startTime;
            }
          });

          resolve(vitals);
        });

        observer.observe({ entryTypes: ['largest-contentful-paint', 'first-input'] });

        // Fallback timeout
        setTimeout(() => resolve({}), 5000);
      });
    });

    return metrics;
  }

  /**
   * Test responsive breakpoints
   */
  async testResponsiveBreakpoints() {
    const breakpoints = [
      { name: 'mobile', width: 375, height: 812 },
      { name: 'tablet-portrait', width: 768, height: 1024 },
      { name: 'tablet-landscape', width: 1024, height: 768 },
      { name: 'desktop', width: 1440, height: 900 },
      { name: 'wide-desktop', width: 1920, height: 1080 }
    ];

    const results = {};

    for (const breakpoint of breakpoints) {
      await this.page.setViewportSize({
        width: breakpoint.width,
        height: breakpoint.height
      });
      await this.page.waitForTimeout(300); // Allow layout to settle

      results[breakpoint.name] = {
        viewport: `${breakpoint.width}x${breakpoint.height}`,
        hasHorizontalScroll: await this.hasHorizontalScroll(),
        mobileMenuVisible: await this.isMobileMenuVisible(),
        touchTargetsValid: await this.areAllTouchTargetsValid()
      };
    }

    return results;
  }

  /**
   * Check for horizontal scrolling
   */
  async hasHorizontalScroll() {
    return await this.page.evaluate(() => {
      return document.documentElement.scrollWidth > document.documentElement.clientWidth;
    });
  }

  /**
   * Check if mobile menu is visible
   */
  async isMobileMenuVisible() {
    try {
      const mobileMenu = this.page.locator('[data-controller="mobile-menu"]');
      return await mobileMenu.isVisible();
    } catch {
      return false;
    }
  }

  /**
   * Check if all touch targets meet size requirements
   */
  async areAllTouchTargetsValid() {
    try {
      await this.verifyAllTouchTargets();
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Simulate touch gesture
   */
  async simulateSwipe(element, direction = 'left', distance = 100) {
    const box = await element.boundingBox();
    const startX = box.x + box.width / 2;
    const startY = box.y + box.height / 2;

    let endX = startX;
    let endY = startY;

    switch (direction) {
    case 'left':
      endX = startX - distance;
      break;
    case 'right':
      endX = startX + distance;
      break;
    case 'up':
      endY = startY - distance;
      break;
    case 'down':
      endY = startY + distance;
      break;
    }

    await this.page.mouse.move(startX, startY);
    await this.page.mouse.down();
    await this.page.mouse.move(endX, endY);
    await this.page.mouse.up();
  }

  /**
   * Test keyboard navigation
   */
  async testKeyboardNavigation() {
    const focusableElements = await this.page.locator('a, button, input, select, textarea, [tabindex]:not([tabindex="-1"])').all();

    let currentIndex = 0;

    for (const element of focusableElements) {
      if (await element.isVisible()) {
        await this.page.keyboard.press('Tab');
        const focused = await this.page.locator(':focus').first();

        // Verify focus is on expected element
        const isSameElement = await this.page.evaluate((el1, el2) => {
          return el1 === el2;
        }, await element.elementHandle(), await focused.elementHandle());

        if (!isSameElement) {
          console.warn(`Focus skipped element at index ${currentIndex}`);
        }

        currentIndex++;
      }
    }

    return currentIndex;
  }

  /**
   * Performance timing metrics
   */
  async getPerformanceMetrics() {
    return await this.page.evaluate(() => {
      const perfData = performance.getEntriesByType('navigation')[0];
      return {
        domContentLoaded: perfData.domContentLoadedEventEnd - perfData.domContentLoadedEventStart,
        loadComplete: perfData.loadEventEnd - perfData.loadEventStart,
        firstPaint: performance.getEntriesByName('first-paint')[0]?.startTime || 0,
        firstContentfulPaint: performance.getEntriesByName('first-contentful-paint')[0]?.startTime || 0,
        totalTime: perfData.loadEventEnd - perfData.navigationStart
      };
    });
  }

  /**
   * Accessibility check with basic audit
   */
  async basicAccessibilityCheck() {
    const issues = [];

    // Check for alt text on images
    const images = await this.page.locator('img').all();
    for (const img of images) {
      const alt = await img.getAttribute('alt');
      const src = await img.getAttribute('src');
      if (!alt && src && !src.includes('data:')) {
        issues.push(`Image missing alt text: ${src}`);
      }
    }

    // Check for form labels
    const inputs = await this.page.locator('input[type="text"], input[type="email"], input[type="password"], textarea').all();
    for (const input of inputs) {
      const id = await input.getAttribute('id');
      const ariaLabel = await input.getAttribute('aria-label');
      const ariaLabelledBy = await input.getAttribute('aria-labelledby');

      if (id) {
        const label = await this.page.locator(`label[for="${id}"]`).count();
        if (label === 0 && !ariaLabel && !ariaLabelledBy) {
          issues.push(`Input missing label: ${id}`);
        }
      }
    }

    // Check heading hierarchy
    const headings = await this.page.locator('h1, h2, h3, h4, h5, h6').all();
    let lastLevel = 0;
    for (const heading of headings) {
      const tagName = await heading.evaluate(el => el.tagName);
      const level = parseInt(tagName.charAt(1));

      if (level > lastLevel + 1) {
        issues.push(`Heading hierarchy skip: jumped from h${lastLevel} to h${level}`);
      }
      lastLevel = level;
    }

    return issues;
  }
}

/**
 * Mobile-specific test utilities
 */
export class MobileTestHelpers extends TestHelpers {
  /**
   * Test touch gesture system
   */
  async testTouchGestures() {
    // Test swipe gestures on post cards
    const postCards = await this.page.locator('[data-controller~="swipe-actions"]').all();

    if (postCards.length > 0) {
      const firstCard = postCards[0];

      // Test left swipe (clear action)
      await this.simulateSwipe(firstCard, 'left', 150);
      await this.page.waitForTimeout(500);

      // Test right swipe (mark as read)
      await this.simulateSwipe(firstCard, 'right', 150);
      await this.page.waitForTimeout(500);
    }

    return postCards.length > 0;
  }

  /**
   * Test pull-to-refresh functionality
   */
  async testPullToRefresh() {
    await this.page.goto('/');

    // Scroll to top
    await this.page.evaluate(() => window.scrollTo(0, 0));

    // Simulate pull gesture
    await this.page.mouse.move(200, 100);
    await this.page.mouse.down();
    await this.page.mouse.move(200, 200);
    await this.page.waitForTimeout(500);
    await this.page.mouse.up();

    // Check if refresh indicator appeared
    const refreshIndicator = this.page.locator('.pull-refresh-indicator');
    return await refreshIndicator.isVisible();
  }

  /**
   * Test long press menus
   */
  async testLongPress() {
    const longPressElements = await this.page.locator('[data-controller~="long-press"]').all();

    if (longPressElements.length > 0) {
      const element = longPressElements[0];
      const box = await element.boundingBox();

      // Simulate long press
      await this.page.mouse.move(box.x + box.width/2, box.y + box.height/2);
      await this.page.mouse.down();
      await this.page.waitForTimeout(600); // Long press threshold
      await this.page.mouse.up();

      // Check if context menu appeared
      const contextMenu = this.page.locator('.long-press-menu');
      return await contextMenu.isVisible();
    }

    return false;
  }
}
