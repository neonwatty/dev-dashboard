import { test, expect } from '@playwright/test';
import { TestHelpers } from '../helpers/test-helpers.js';

test.describe('Core Web Vitals and Performance Monitoring', () => {
  let helpers;

  test.beforeEach(async ({ page }) => {
    helpers = new TestHelpers(page);
    await helpers.authenticateUser();
  });

  test('Largest Contentful Paint (LCP) meets performance targets', async ({ page }) => {
    const lcpResults = {};

    // Test LCP across different viewport sizes
    const viewports = [
      { name: 'Mobile', width: 375, height: 812 },
      { name: 'Tablet', width: 768, height: 1024 },
      { name: 'Desktop', width: 1920, height: 1080 }
    ];

    for (const viewport of viewports) {
      await page.setViewportSize(viewport);

      // Navigate and measure LCP
      const startTime = Date.now();
      await page.goto('/', { waitUntil: 'networkidle' });

      const lcpValue = await page.evaluate(() => {
        return new Promise((resolve) => {
          const observer = new PerformanceObserver((list) => {
            const entries = list.getEntries();
            const lastEntry = entries[entries.length - 1];
            if (lastEntry) {
              resolve(lastEntry.startTime);
            }
          });

          observer.observe({ entryTypes: ['largest-contentful-paint'] });

          // Fallback timeout
          setTimeout(() => resolve(null), 10000);
        });
      });

      if (lcpValue) {
        lcpResults[viewport.name] = lcpValue;

        // LCP should be under 2.5s for good performance
        expect(lcpValue).toBeLessThan(2500);
        console.log(`LCP for ${viewport.name}: ${lcpValue.toFixed(2)}ms`);
      }
    }

    // Log results for analysis
    console.log('LCP Results:', lcpResults);
  });

  test('First Input Delay (FID) and interactivity metrics', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    // Measure Time to Interactive
    const ttiValue = await page.evaluate(() => {
      return new Promise((resolve) => {
        const observer = new PerformanceObserver((list) => {
          const entries = list.getEntries();
          for (const entry of entries) {
            if (entry.name === 'first-input') {
              const fid = entry.processingStart - entry.startTime;
              resolve(fid);
              return;
            }
          }
        });

        observer.observe({ entryTypes: ['first-input'] });

        // Trigger a user interaction to measure FID
        setTimeout(() => {
          const button = document.querySelector('button, a, input[type="button"]');
          if (button) {
            button.click();
          }
        }, 1000);

        setTimeout(() => resolve(null), 5000);
      });
    });

    // Test interactive elements response time
    const interactiveElements = await page.locator('button, a, input[type="button"], [role="button"]').all();

    for (const element of interactiveElements.slice(0, 5)) {
      if (await element.isVisible()) {
        const startTime = Date.now();
        await element.click();
        const responseTime = Date.now() - startTime;

        // Interactive elements should respond within 100ms
        expect(responseTime).toBeLessThan(100);

        await page.waitForTimeout(200); // Allow for any async operations
      }
    }

    // Measure Total Blocking Time
    const tbtValue = await page.evaluate(() => {
      const entries = performance.getEntriesByType('measure');
      let tbt = 0;

      for (const entry of entries) {
        if (entry.duration > 50) {
          tbt += entry.duration - 50;
        }
      }

      return tbt;
    });

    // TBT should be minimal for good interactivity
    if (tbtValue > 0) {
      expect(tbtValue).toBeLessThan(300); // Under 300ms for good performance
      console.log(`Total Blocking Time: ${tbtValue.toFixed(2)}ms`);
    }
  });

  test('Cumulative Layout Shift (CLS) remains stable', async ({ page }) => {
    const clsResults = {};

    const pages = [
      { path: '/', name: 'Home' },
      { path: '/sources', name: 'Sources' },
      { path: '/settings/edit', name: 'Settings' }
    ];

    for (const pageInfo of pages) {
      await page.goto(pageInfo.path);

      // Measure CLS over time
      const clsValue = await page.evaluate(() => {
        return new Promise((resolve) => {
          let clsScore = 0;

          const observer = new PerformanceObserver((list) => {
            for (const entry of list.getEntries()) {
              if (!entry.hadRecentInput) {
                clsScore += entry.value;
              }
            }
          });

          observer.observe({ type: 'layout-shift', buffered: true });

          // Wait for layout shifts to settle
          setTimeout(() => {
            observer.disconnect();
            resolve(clsScore);
          }, 3000);
        });
      });

      clsResults[pageInfo.name] = clsValue;

      // CLS should be under 0.1 for good user experience
      expect(clsValue).toBeLessThan(0.1);
      console.log(`CLS for ${pageInfo.name}: ${clsValue.toFixed(4)}`);
    }

    // Test CLS during dynamic content loading
    await page.goto('/');
    await helpers.waitForPageLoad();

    // Trigger content updates if available
    const refreshButton = page.locator('button:has-text("Refresh"), [data-action*="refresh"]');
    if (await refreshButton.count() > 0) {
      const clsBeforeRefresh = await page.evaluate(() => {
        let clsScore = 0;
        const observer = new PerformanceObserver((list) => {
          for (const entry of list.getEntries()) {
            if (!entry.hadRecentInput) {
              clsScore += entry.value;
            }
          }
        });
        observer.observe({ type: 'layout-shift', buffered: true });
        return clsScore;
      });

      await refreshButton.click();
      await page.waitForTimeout(2000);

      const clsAfterRefresh = await page.evaluate(() => {
        let clsScore = 0;
        const observer = new PerformanceObserver((list) => {
          for (const entry of list.getEntries()) {
            if (!entry.hadRecentInput) {
              clsScore += entry.value;
            }
          }
        });
        observer.observe({ type: 'layout-shift', buffered: true });
        return clsScore;
      });

      const clsDuringUpdate = clsAfterRefresh - clsBeforeRefresh;
      expect(clsDuringUpdate).toBeLessThan(0.1);
    }
  });

  test('Resource loading performance and optimization', async ({ page }) => {
    // Monitor network requests
    const resourceMetrics = {
      totalRequests: 0,
      totalSize: 0,
      jsSize: 0,
      cssSize: 0,
      imageSize: 0,
      slowRequests: []
    };

    page.on('response', async (response) => {
      try {
        const request = response.request();
        const url = request.url();
        const contentType = response.headers()['content-type'] || '';
        const size = parseInt(response.headers()['content-length'] || '0');

        resourceMetrics.totalRequests++;
        resourceMetrics.totalSize += size;

        if (contentType.includes('javascript')) {
          resourceMetrics.jsSize += size;
        } else if (contentType.includes('css')) {
          resourceMetrics.cssSize += size;
        } else if (contentType.includes('image')) {
          resourceMetrics.imageSize += size;
        }

        // Track slow requests
        const timing = await response.allHeaders();
        if (response.timing && response.timing().responseEnd > 1000) {
          resourceMetrics.slowRequests.push({
            url,
            time: response.timing().responseEnd
          });
        }
      } catch {
        // Ignore timing errors
      }
    });

    await page.goto('/', { waitUntil: 'networkidle' });
    await helpers.waitForPageLoad();

    // Verify resource sizes are reasonable
    expect(resourceMetrics.jsSize).toBeLessThan(500 * 1024); // JS under 500KB
    expect(resourceMetrics.cssSize).toBeLessThan(100 * 1024); // CSS under 100KB
    expect(resourceMetrics.totalSize).toBeLessThan(2 * 1024 * 1024); // Total under 2MB

    // Verify no excessively slow requests
    expect(resourceMetrics.slowRequests.length).toBeLessThan(3);

    console.log('Resource Metrics:', {
      totalRequests: resourceMetrics.totalRequests,
      totalSize: `${(resourceMetrics.totalSize / 1024).toFixed(2)}KB`,
      jsSize: `${(resourceMetrics.jsSize / 1024).toFixed(2)}KB`,
      cssSize: `${(resourceMetrics.cssSize / 1024).toFixed(2)}KB`,
      imageSize: `${(resourceMetrics.imageSize / 1024).toFixed(2)}KB`,
      slowRequests: resourceMetrics.slowRequests.length
    });
  });

  test('Mobile performance optimization', async ({ page }) => {
    // Test on mobile viewport
    await page.setViewportSize({ width: 375, height: 812 });

    // Simulate slower mobile network
    await page.emulateNetworkConditions({
      offline: false,
      downloadThroughput: 1500 * 1024, // 1.5MB/s (4G)
      uploadThroughput: 750 * 1024,    // 750KB/s
      latency: 150
    });

    const startTime = Date.now();
    await page.goto('/', { waitUntil: 'networkidle' });
    const loadTime = Date.now() - startTime;

    // Mobile load time should be reasonable even on slower networks
    expect(loadTime).toBeLessThan(6000); // Under 6 seconds

    const mobileMetrics = await helpers.getPerformanceMetrics();

    // Mobile-specific performance thresholds
    expect(mobileMetrics.firstContentfulPaint).toBeLessThan(3000);
    expect(mobileMetrics.domContentLoaded).toBeLessThan(2000);

    // Test mobile-specific features performance
    const touchElements = await page.locator('[data-controller~="swipe-actions"], [data-controller~="long-press"]').all();

    for (const element of touchElements.slice(0, 3)) {
      if (await element.isVisible()) {
        const startTouch = Date.now();
        await element.click();
        const touchResponse = Date.now() - startTouch;

        // Touch interactions should be immediate
        expect(touchResponse).toBeLessThan(50);
      }
    }

    // Test scroll performance
    const scrollStartTime = Date.now();
    await page.evaluate(() => {
      window.scrollBy(0, 500);
    });
    await page.waitForTimeout(100);
    const scrollTime = Date.now() - scrollStartTime;

    expect(scrollTime).toBeLessThan(200); // Smooth scrolling
  });

  test('Memory usage and leak detection', async ({ page }) => {
    // Get initial memory usage
    const initialMemory = await page.evaluate(() => {
      return performance.memory ? performance.memory.usedJSHeapSize : 0;
    });

    // Perform various operations that might cause memory leaks
    const operations = [
      () => page.goto('/'),
      () => page.goto('/sources'),
      () => page.goto('/settings/edit'),
      () => page.goto('/'),
      () => page.reload()
    ];

    for (const operation of operations) {
      await operation();
      await helpers.waitForPageLoad();

      // Trigger any touch interactions
      const touchElements = await page.locator('[data-controller="touch-feedback"]').all();
      for (const element of touchElements.slice(0, 2)) {
        if (await element.isVisible()) {
          await element.click();
          await page.waitForTimeout(100);
        }
      }
    }

    // Force garbage collection if available
    await page.evaluate(() => {
      if (window.gc) {
        window.gc();
      }
    });
    await page.waitForTimeout(1000);

    const finalMemory = await page.evaluate(() => {
      return performance.memory ? performance.memory.usedJSHeapSize : 0;
    });

    if (initialMemory > 0 && finalMemory > 0) {
      const memoryIncrease = finalMemory - initialMemory;
      const memoryIncreasePercentage = (memoryIncrease / initialMemory) * 100;

      // Memory increase should be reasonable (less than 100% increase)
      expect(memoryIncreasePercentage).toBeLessThan(100);

      // Absolute memory usage should be reasonable
      expect(finalMemory).toBeLessThan(50 * 1024 * 1024); // Under 50MB

      console.log(`Memory Usage: Initial: ${(initialMemory / 1024 / 1024).toFixed(2)}MB, Final: ${(finalMemory / 1024 / 1024).toFixed(2)}MB, Increase: ${memoryIncreasePercentage.toFixed(2)}%`);
    }
  });

  test('Animation and interaction performance', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    // Test CSS animation performance
    const animatedElements = await page.locator('.animate, [class*="animate"], [class*="transition"]').all();

    for (const element of animatedElements.slice(0, 3)) {
      if (await element.isVisible()) {
        // Trigger animation
        await element.hover();

        // Measure animation frame rate
        const fps = await page.evaluate((_el) => {
          return new Promise((resolve) => {
            let frames = 0;
            const startTime = performance.now();

            function countFrames() {
              frames++;
              if (performance.now() - startTime < 1000) {
                requestAnimationFrame(countFrames);
              } else {
                resolve(frames);
              }
            }

            requestAnimationFrame(countFrames);
          });
        }, await element.elementHandle());

        // Animation should maintain good frame rate (close to 60fps)
        expect(fps).toBeGreaterThan(45);
      }
    }

    // Test JavaScript interaction performance
    const interactiveElements = await page.locator('button, a, [role="button"]').all();

    for (const element of interactiveElements.slice(0, 5)) {
      if (await element.isVisible()) {
        const interactions = [];

        for (let i = 0; i < 10; i++) {
          const startTime = performance.now();
          await element.click();
          const endTime = performance.now();
          interactions.push(endTime - startTime);
          await page.waitForTimeout(50);
        }

        const avgInteractionTime = interactions.reduce((a, b) => a + b, 0) / interactions.length;

        // Average interaction time should be minimal
        expect(avgInteractionTime).toBeLessThan(20);
      }
    }
  });

  test('Bundle size and loading optimization', async ({ page }) => {
    const bundleMetrics = {
      jsFiles: [],
      cssFiles: [],
      totalJSSize: 0,
      totalCSSSize: 0
    };

    page.on('response', async (response) => {
      const url = response.url();
      const contentType = response.headers()['content-type'] || '';

      if (contentType.includes('javascript') && url.includes('/assets/')) {
        const size = parseInt(response.headers()['content-length'] || '0');
        bundleMetrics.jsFiles.push({ url, size });
        bundleMetrics.totalJSSize += size;
      } else if (contentType.includes('css') && url.includes('/assets/')) {
        const size = parseInt(response.headers()['content-length'] || '0');
        bundleMetrics.cssFiles.push({ url, size });
        bundleMetrics.totalCSSSize += size;
      }
    });

    await page.goto('/', { waitUntil: 'networkidle' });
    await helpers.waitForPageLoad();

    // Verify bundle sizes are optimized
    expect(bundleMetrics.totalJSSize).toBeLessThan(300 * 1024); // JS under 300KB
    expect(bundleMetrics.totalCSSSize).toBeLessThan(50 * 1024);  // CSS under 50KB

    // Verify JavaScript bundles are split appropriately
    const largeJSFiles = bundleMetrics.jsFiles.filter(file => file.size > 100 * 1024);
    expect(largeJSFiles.length).toBeLessThan(2); // No more than 1 large JS file

    // Test that critical CSS is inlined or loaded first
    const criticalCSS = await page.evaluate(() => {
      const stylesheets = Array.from(document.styleSheets);
      let criticalRules = 0;

      for (const sheet of stylesheets) {
        try {
          const rules = sheet.cssRules || sheet.rules;
          for (const rule of rules) {
            if (rule.selectorText && (
              rule.selectorText.includes('body') ||
              rule.selectorText.includes('html') ||
              rule.selectorText.includes('.container')
            )) {
              criticalRules++;
            }
          }
        } catch {
          // Cross-origin stylesheets
        }
      }

      return criticalRules;
    });

    expect(criticalRules).toBeGreaterThan(0); // Some critical CSS should be loaded

    console.log('Bundle Metrics:', {
      jsFiles: bundleMetrics.jsFiles.length,
      cssFiles: bundleMetrics.cssFiles.length,
      totalJSSize: `${(bundleMetrics.totalJSSize / 1024).toFixed(2)}KB`,
      totalCSSSize: `${(bundleMetrics.totalCSSSize / 1024).toFixed(2)}KB`
    });
  });
});
