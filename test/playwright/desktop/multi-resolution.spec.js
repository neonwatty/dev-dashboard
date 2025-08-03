import { test, expect } from '@playwright/test';
import { TestHelpers } from '../helpers/test-helpers.js';

test.describe('Desktop Multi-Resolution UX Testing', () => {
  let helpers;

  test.beforeEach(async ({ page }) => {
    helpers = new TestHelpers(page);
    await helpers.authenticateUser();
  });

  const resolutions = [
    { name: 'FHD', width: 1920, height: 1080 },
    { name: 'HD', width: 1440, height: 900 },
    { name: '4K', width: 2560, height: 1440 },
    { name: 'Wide', width: 3440, height: 1440 }
  ];

  resolutions.forEach(({ name, width, height }) => {
    test(`Desktop layout works correctly at ${name} resolution (${width}x${height})`, async ({ page }) => {
      await page.setViewportSize({ width, height });
      await page.goto('/');
      await helpers.waitForPageLoad();

      // Verify no horizontal scrolling
      const hasHorizontalScroll = await helpers.hasHorizontalScroll();
      expect(hasHorizontalScroll).toBeFalsy();

      // Verify desktop navigation is visible
      await expect(page.locator('nav.desktop-nav, .desktop-navigation')).toBeVisible();

      // Verify mobile menu is hidden on desktop
      const mobileMenu = page.locator('[data-controller="mobile-menu"]');
      if (await mobileMenu.count() > 0) {
        await expect(mobileMenu).not.toBeVisible();
      }

      // Verify content adapts to screen width
      const contentWidth = await page.evaluate(() => {
        const content = document.querySelector('main, .main-content, .container');
        return content ? content.offsetWidth : 0;
      });

      expect(contentWidth).toBeGreaterThan(0);
      expect(contentWidth).toBeLessThanOrEqual(width);

      // Verify sidebar/navigation panel is visible on larger screens
      if (width >= 1024) {
        const sidebar = page.locator('.sidebar, .navigation-panel, [data-testid="sidebar"]');
        if (await sidebar.count() > 0) {
          await expect(sidebar).toBeVisible();
        }
      }

      // Test form layouts at different resolutions
      const forms = await page.locator('form').all();
      for (const form of forms) {
        if (await form.isVisible()) {
          const formWidth = await form.evaluate(el => el.offsetWidth);
          expect(formWidth).toBeGreaterThan(0);

          // Forms should not be too narrow on large screens
          if (width >= 1920) {
            expect(formWidth).toBeGreaterThan(400);
          }
        }
      }
    });
  });

  test('Desktop post card layout adapts correctly across resolutions', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    for (const { name, width, height } of resolutions) {
      await page.setViewportSize({ width, height });
      await page.waitForTimeout(300);

      const postCards = await page.locator('.post-card, [data-testid="post-card"]').all();

      if (postCards.length > 0) {
        const firstCard = postCards[0];
        const cardBox = await firstCard.boundingBox();

        expect(cardBox.width).toBeGreaterThan(0);

        // On large screens, cards should use horizontal layout
        if (width >= 768) {
          const isHorizontalLayout = await firstCard.evaluate(el => {
            const style = window.getComputedStyle(el);
            return style.display === 'flex' &&
                   (style.flexDirection === 'row' || style.flexDirection === '');
          });

          if (isHorizontalLayout) {
            expect(cardBox.width).toBeGreaterThan(cardBox.height);
          }
        }
      }
    }
  });

  test('Typography scales appropriately across resolutions', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    const textElements = [
      'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
      '.title', '.subtitle', '.body-text',
      'p', '.description'
    ];

    for (const { name, width, height } of resolutions) {
      await page.setViewportSize({ width, height });
      await page.waitForTimeout(300);

      for (const selector of textElements) {
        const elements = await page.locator(selector).all();

        for (const element of elements) {
          if (await element.isVisible()) {
            const fontSize = await element.evaluate(el => {
              return parseInt(window.getComputedStyle(el).fontSize);
            });

            // Font size should be reasonable (not too small or too large)
            expect(fontSize).toBeGreaterThan(10);
            expect(fontSize).toBeLessThan(72);

            // On 4K screens, text should be larger
            if (width >= 2560) {
              expect(fontSize).toBeGreaterThan(12);
            }
          }
        }
      }
    }
  });

  test('Interactive elements maintain proper spacing at all resolutions', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    for (const { name, width, height } of resolutions) {
      await page.setViewportSize({ width, height });
      await page.waitForTimeout(300);

      // Test button spacing
      const buttons = await page.locator('button, .btn').all();

      for (let i = 0; i < Math.min(buttons.length - 1, 5); i++) {
        const button1 = buttons[i];
        const button2 = buttons[i + 1];

        if (await button1.isVisible() && await button2.isVisible()) {
          const box1 = await button1.boundingBox();
          const box2 = await button2.boundingBox();

          // Check for adequate spacing between buttons
          const horizontalDistance = Math.abs(box2.x - (box1.x + box1.width));
          const verticalDistance = Math.abs(box2.y - (box1.y + box1.height));

          // Buttons should have at least 8px spacing
          if (horizontalDistance < 100 && verticalDistance < 100) {
            const actualSpacing = Math.min(horizontalDistance, verticalDistance);
            expect(actualSpacing).toBeGreaterThanOrEqual(8);
          }
        }
      }

      // Verify touch targets on desktop still meet minimum requirements
      await helpers.verifyAllTouchTargets();
    }
  });

  test('Navigation flow works consistently across resolutions', async ({ page }) => {
    const navigationTests = [
      { path: '/', name: 'Home' },
      { path: '/sources', name: 'Sources' },
      { path: '/settings/edit', name: 'Settings' }
    ];

    for (const { name, width, height } of resolutions) {
      await page.setViewportSize({ width, height });

      for (const nav of navigationTests) {
        await page.goto(nav.path);
        await helpers.waitForPageLoad();

        // Verify page loaded correctly
        expect(page.url()).toContain(nav.path);

        // Verify no layout breaking
        const hasHorizontalScroll = await helpers.hasHorizontalScroll();
        expect(hasHorizontalScroll).toBeFalsy();

        // Verify main content is visible
        const mainContent = page.locator('main, .main-content, .container');
        await expect(mainContent.first()).toBeVisible();
      }
    }
  });

  test('Data tables adapt correctly to screen width', async ({ page }) => {
    // Test sources page which likely has tables
    await page.goto('/sources');
    await helpers.waitForPageLoad();

    for (const { name, width, height } of resolutions) {
      await page.setViewportSize({ width, height });
      await page.waitForTimeout(300);

      const tables = await page.locator('table, .table, [role="table"]').all();

      for (const table of tables) {
        if (await table.isVisible()) {
          const tableBox = await table.boundingBox();

          // Table should not overflow viewport
          expect(tableBox.width).toBeLessThanOrEqual(width + 20); // Allow small margin for scrollbar

          // On larger screens, tables should use available width effectively
          if (width >= 1440) {
            expect(tableBox.width).toBeGreaterThan(800);
          }

          // Verify table headers are visible
          const headers = await table.locator('th, [role="columnheader"]').all();
          for (const header of headers) {
            if (await header.isVisible()) {
              const headerBox = await header.boundingBox();
              expect(headerBox.width).toBeGreaterThan(0);
            }
          }
        }
      }
    }
  });

  test('Image and media elements scale appropriately', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    for (const { name, width, height } of resolutions) {
      await page.setViewportSize({ width, height });
      await page.waitForTimeout(300);

      const images = await page.locator('img').all();

      for (const img of images) {
        if (await img.isVisible()) {
          const imgBox = await img.boundingBox();

          // Images should not overflow viewport
          expect(imgBox.width).toBeLessThanOrEqual(width);

          // Images should maintain reasonable aspect ratios
          const aspectRatio = imgBox.width / imgBox.height;
          expect(aspectRatio).toBeGreaterThan(0.1);
          expect(aspectRatio).toBeLessThan(10);

          // On high-DPI screens, images should be crisp
          if (width >= 2560) {
            const naturalWidth = await img.evaluate(el => el.naturalWidth);
            const displayWidth = imgBox.width;

            // For vector graphics or high-res images, this might be different
            // but we should ensure they're not heavily pixelated
            if (naturalWidth > 0) {
              const pixelRatio = naturalWidth / displayWidth;
              expect(pixelRatio).toBeGreaterThan(0.5);
            }
          }
        }
      }
    }
  });

  test('Performance remains acceptable across all resolutions', async ({ page }) => {
    for (const { name, width, height } of resolutions) {
      await page.setViewportSize({ width, height });

      const startTime = Date.now();
      await page.goto('/', { waitUntil: 'networkidle' });
      const loadTime = Date.now() - startTime;

      // Page load should complete within reasonable time
      expect(loadTime).toBeLessThan(5000);

      const metrics = await helpers.getPerformanceMetrics();

      // Core performance metrics should be reasonable
      expect(metrics.domContentLoaded).toBeLessThan(2000);
      expect(metrics.firstContentfulPaint).toBeLessThan(2000);

      // Layout shifts should be minimal
      const cls = await page.evaluate(() => {
        return new Promise((resolve) => {
          let clsValue = 0;
          new PerformanceObserver((list) => {
            for (const entry of list.getEntries()) {
              if (!entry.hadRecentInput) {
                clsValue += entry.value;
              }
            }
            resolve(clsValue);
          }).observe({ type: 'layout-shift', buffered: true });

          setTimeout(() => resolve(clsValue), 2000);
        });
      });

      expect(cls).toBeLessThan(0.1); // Good CLS score
    }
  });
});
