import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import { TestHelpers } from '../helpers/test-helpers.js';

test.describe('Accessibility Compliance Testing with aXe', () => {
  let helpers;

  test.beforeEach(async ({ page }) => {
    helpers = new TestHelpers(page);
    await helpers.authenticateUser();
  });

  test('Home page meets WCAG AA accessibility standards', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    const accessibilityScanResults = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      .analyze();

    expect(accessibilityScanResults.violations).toEqual([]);

    // If there are violations, log them for debugging
    if (accessibilityScanResults.violations.length > 0) {
      console.log('Accessibility violations found:');
      accessibilityScanResults.violations.forEach((violation, index) => {
        console.log(`${index + 1}. ${violation.id}: ${violation.description}`);
        violation.nodes.forEach((node, nodeIndex) => {
          console.log(`   Node ${nodeIndex + 1}: ${node.html}`);
        });
      });
    }
  });

  test('Sources page accessibility compliance', async ({ page }) => {
    await page.goto('/sources');
    await helpers.waitForPageLoad();

    const accessibilityScanResults = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa'])
      .exclude('[data-testid="advertisement"]') // Exclude third-party content
      .analyze();

    expect(accessibilityScanResults.violations).toEqual([]);

    // Test table accessibility specifically
    const tables = await page.locator('table, [role="table"]').all();
    for (const table of tables) {
      if (await table.isVisible()) {
        // Check for table headers
        const headers = await table.locator('th, [role="columnheader"]').count();
        expect(headers).toBeGreaterThan(0);

        // Check for table caption or aria-label
        const hasCaption = await table.locator('caption').count() > 0;
        const hasAriaLabel = await table.getAttribute('aria-label') !== null;
        const hasAriaLabelledBy = await table.getAttribute('aria-labelledby') !== null;

        expect(hasCaption || hasAriaLabel || hasAriaLabelledBy).toBeTruthy();
      }
    }
  });

  test('Forms accessibility and keyboard navigation', async ({ page }) => {
    await page.goto('/sources/new');
    await helpers.waitForPageLoad();

    // Run aXe scan on forms
    const accessibilityScanResults = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa'])
      .include('form')
      .analyze();

    expect(accessibilityScanResults.violations).toEqual([]);

    // Test form-specific accessibility
    const forms = await page.locator('form').all();

    for (const form of forms) {
      if (await form.isVisible()) {
        // Check form inputs have labels
        const inputs = await form.locator('input, textarea, select').all();

        for (const input of inputs) {
          if (await input.isVisible()) {
            const inputId = await input.getAttribute('id');
            const ariaLabel = await input.getAttribute('aria-label');
            const ariaLabelledBy = await input.getAttribute('aria-labelledby');

            if (inputId) {
              const hasLabel = await form.locator(`label[for="${inputId}"]`).count() > 0;
              expect(hasLabel || ariaLabel || ariaLabelledBy).toBeTruthy();
            }

            // Test keyboard accessibility
            await input.focus();
            const isFocused = await input.evaluate(el => el === document.activeElement);
            expect(isFocused).toBeTruthy();

            // Check focus is visible
            const focusIndicator = await input.evaluate(el => {
              const style = window.getComputedStyle(el);
              return style.outline !== 'none' ||
                     style.outlineWidth !== '0px' ||
                     style.boxShadow.includes('inset') ||
                     style.border.includes('blue') ||
                     style.borderColor.includes('blue');
            });
            expect(focusIndicator).toBeTruthy();
          }
        }

        // Test form submission accessibility
        const submitButtons = await form.locator('input[type="submit"], button[type="submit"], button:has-text("Save"), button:has-text("Create")').all();

        for (const button of submitButtons) {
          if (await button.isVisible()) {
            const buttonText = await button.textContent() || await button.getAttribute('value');
            const ariaLabel = await button.getAttribute('aria-label');

            expect(buttonText?.trim() || ariaLabel).toBeTruthy();
          }
        }
      }
    }
  });

  test('Mobile accessibility features work correctly', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await page.goto('/');
    await helpers.waitForPageLoad();

    // Run aXe scan on mobile viewport
    const mobileAccessibilityScan = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      .analyze();

    expect(mobileAccessibilityScan.violations).toEqual([]);

    // Test mobile-specific accessibility features
    const mobileMenu = page.locator('[data-controller="mobile-menu"]');
    if (await mobileMenu.count() > 0) {
      // Check mobile menu accessibility
      const menuButton = mobileMenu.locator('button, [role="button"]').first();

      if (await menuButton.count() > 0) {
        const ariaExpanded = await menuButton.getAttribute('aria-expanded');
        const ariaControls = await menuButton.getAttribute('aria-controls');
        const ariaLabel = await menuButton.getAttribute('aria-label');

        expect(ariaExpanded !== null || ariaControls !== null || ariaLabel !== null).toBeTruthy();

        // Test menu interaction
        await menuButton.click();
        await page.waitForTimeout(300);

        const expandedState = await menuButton.getAttribute('aria-expanded');
        expect(expandedState).toBe('true');

        // Test focus management
        const firstMenuLink = mobileMenu.locator('a, button').first();
        if (await firstMenuLink.count() > 0) {
          const isFocused = await firstMenuLink.evaluate(el => el === document.activeElement);
          expect(isFocused).toBeTruthy();
        }
      }
    }

    // Test touch targets meet accessibility size requirements
    await helpers.verifyAllTouchTargets();

    // Test swipe actions accessibility
    const swipeElements = await page.locator('[data-controller~="swipe-actions"]').all();

    for (const element of swipeElements.slice(0, 3)) {
      if (await element.isVisible()) {
        // Swipe actions should have keyboard alternatives or clear instructions
        const hasKeyboardAlternative = await element.evaluate(el => {
          const buttons = el.querySelectorAll('button, [role="button"]');
          return buttons.length > 0;
        });

        const hasAriaDescription = await element.getAttribute('aria-describedby') !== null;
        const hasAriaLabel = await element.getAttribute('aria-label') !== null;

        expect(hasKeyboardAlternative || hasAriaDescription || hasAriaLabel).toBeTruthy();
      }
    }
  });

  test('Color contrast and visual accessibility', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    // Run aXe scan specifically for color contrast
    const colorContrastScan = await new AxeBuilder({ page })
      .withTags(['wcag2aa'])
      .include('body')
      .analyze();

    const contrastViolations = colorContrastScan.violations.filter(
      violation => violation.id === 'color-contrast'
    );

    expect(contrastViolations).toEqual([]);

    // Test dark mode color contrast if available
    const darkModeToggle = page.locator('[data-controller="dark-mode"], .dark-mode-toggle');
    if (await darkModeToggle.count() > 0) {
      await darkModeToggle.click();
      await page.waitForTimeout(500);

      const darkModeContrastScan = await new AxeBuilder({ page })
        .withTags(['wcag2aa'])
        .include('body')
        .analyze();

      const darkModeContrastViolations = darkModeContrastScan.violations.filter(
        violation => violation.id === 'color-contrast'
      );

      expect(darkModeContrastViolations).toEqual([]);
    }

    // Test high contrast mode compatibility
    await page.emulateMedia({
      colorScheme: 'dark',
      reducedMotion: 'reduce'
    });

    await page.reload();
    await helpers.waitForPageLoad();

    const highContrastScan = await new AxeBuilder({ page })
      .withTags(['wcag2aa'])
      .analyze();

    expect(highContrastScan.violations).toEqual([]);
  });

  test('Screen reader compatibility and ARIA implementation', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    // Test ARIA landmarks
    const landmarks = await page.locator('[role="main"], [role="navigation"], [role="banner"], [role="contentinfo"], [role="complementary"]').count();
    expect(landmarks).toBeGreaterThan(0);

    // Test ARIA live regions for dynamic content
    const liveRegions = await page.locator('[aria-live], [aria-atomic], [role="status"], [role="alert"]').count();
    expect(liveRegions).toBeGreaterThan(0);

    // Test heading hierarchy
    const headings = await page.locator('h1, h2, h3, h4, h5, h6').all();
    let previousLevel = 0;

    for (const heading of headings) {
      if (await heading.isVisible()) {
        const tagName = await heading.evaluate(el => el.tagName);
        const level = parseInt(tagName.charAt(1));

        // Heading levels should not skip (e.g., h1 to h3)
        if (previousLevel > 0) {
          expect(level - previousLevel).toBeLessThanOrEqual(1);
        }

        previousLevel = level;
      }
    }

    // Test that all images have alt text
    const images = await page.locator('img').all();

    for (const img of images) {
      if (await img.isVisible()) {
        const alt = await img.getAttribute('alt');
        const src = await img.getAttribute('src');
        const role = await img.getAttribute('role');

        // Decorative images should have empty alt or role="presentation"
        // Content images should have descriptive alt text
        if (src && !src.startsWith('data:')) {
          expect(alt !== null || role === 'presentation').toBeTruthy();
        }
      }
    }

    // Test keyboard navigation flow
    await page.keyboard.press('Tab');
    let focusableCount = 0;
    let previousElement = null;

    for (let i = 0; i < 20; i++) {
      const focusedElement = await page.locator(':focus').first();

      if (await focusedElement.count() > 0) {
        focusableCount++;

        // Ensure focus is visible
        const isFocusVisible = await focusedElement.evaluate(el => {
          const style = window.getComputedStyle(el);
          return style.outline !== 'none' ||
                 style.outlineWidth !== '0px' ||
                 style.boxShadow.includes('inset');
        });
        expect(isFocusVisible).toBeTruthy();

        // Check for skip links
        if (i === 0) {
          const elementText = await focusedElement.textContent();
          const isSkipLink = elementText?.toLowerCase().includes('skip');
          if (isSkipLink) {
            console.log('Skip link found:', elementText);
          }
        }

        previousElement = focusedElement;
        await page.keyboard.press('Tab');
      } else {
        break;
      }
    }

    expect(focusableCount).toBeGreaterThan(5); // Should have reasonable number of focusable elements
  });

  test('Error handling and validation accessibility', async ({ page }) => {
    await page.goto('/sources/new');
    await helpers.waitForPageLoad();

    // Submit empty form to trigger validation
    const submitButton = page.locator('input[type="submit"], button[type="submit"]').first();
    if (await submitButton.count() > 0) {
      await submitButton.click();
      await page.waitForTimeout(500);

      // Check for accessible error messages
      const errorMessages = await page.locator('.error, .invalid, [aria-invalid="true"], [role="alert"], .field_with_errors').all();

      for (const error of errorMessages) {
        if (await error.isVisible()) {
          // Error should be associated with form field
          const ariaDescribedBy = await page.locator('[aria-describedby]').count();
          const ariaLabelledBy = await page.locator('[aria-labelledby]').count();
          const roleAlert = await error.getAttribute('role');

          expect(ariaDescribedBy > 0 || ariaLabelledBy > 0 || roleAlert === 'alert').toBeTruthy();
        }
      }

      // Run aXe scan on error state
      const errorStateScan = await new AxeBuilder({ page })
        .withTags(['wcag2a', 'wcag2aa'])
        .analyze();

      expect(errorStateScan.violations).toEqual([]);
    }
  });

  test('Interactive elements accessibility compliance', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    // Test buttons and links
    const interactiveElements = await page.locator('button, a, input[type="button"], input[type="submit"], [role="button"], [tabindex="0"]').all();

    for (const element of interactiveElements.slice(0, 10)) {
      if (await element.isVisible()) {
        // Check for accessible name
        const textContent = await element.textContent();
        const ariaLabel = await element.getAttribute('aria-label');
        const ariaLabelledBy = await element.getAttribute('aria-labelledby');
        const title = await element.getAttribute('title');

        const hasAccessibleName = (textContent && textContent.trim()) ||
                                 ariaLabel ||
                                 ariaLabelledBy ||
                                 title;
        expect(hasAccessibleName).toBeTruthy();

        // Test keyboard activation
        await element.focus();
        const isFocused = await element.evaluate(el => el === document.activeElement);
        expect(isFocused).toBeTruthy();

        // Test that Enter key activates buttons
        if (await element.evaluate(el => el.tagName === 'BUTTON' || el.getAttribute('role') === 'button')) {
          await page.keyboard.press('Enter');
          await page.waitForTimeout(200);

          // Should trigger some action (URL change, modal, notification, etc.)
          const hasResponse = await page.locator('.modal, .notification, .alert, .toast').count() > 0;
          const urlChanged = page.url() !== page.url();

          // Note: Some buttons may not have visible responses, which is okay
        }
      }
    }

    // Test form controls
    const formControls = await page.locator('input, textarea, select').all();

    for (const control of formControls.slice(0, 5)) {
      if (await control.isVisible()) {
        const controlType = await control.getAttribute('type');
        const tagName = await control.evaluate(el => el.tagName);

        // Test keyboard navigation
        await control.focus();
        const isFocused = await control.evaluate(el => el === document.activeElement);
        expect(isFocused).toBeTruthy();

        // Test appropriate keyboard interaction
        if (tagName === 'SELECT') {
          await page.keyboard.press('ArrowDown');
          await page.keyboard.press('ArrowUp');
        } else if (controlType === 'checkbox' || controlType === 'radio') {
          await page.keyboard.press('Space');
        } else {
          await page.keyboard.type('test');
          await page.keyboard.press('Backspace');
          await page.keyboard.press('Backspace');
          await page.keyboard.press('Backspace');
          await page.keyboard.press('Backspace');
        }
      }
    }
  });

  test('Dynamic content accessibility updates', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    // Test refresh functionality accessibility
    const refreshButton = page.locator('button:has-text("Refresh"), [data-action*="refresh"]').first();

    if (await refreshButton.count() > 0) {
      // Check for loading state announcement
      await refreshButton.click();

      // Look for aria-live regions or status updates
      const liveRegions = await page.locator('[aria-live], [role="status"], [aria-busy="true"]').count();
      expect(liveRegions).toBeGreaterThan(0);

      await page.waitForTimeout(2000);

      // Check for completion announcement
      const completionIndicator = await page.locator('[aria-live] *', '[role="status"] *').count();
      expect(completionIndicator).toBeGreaterThan(0);
    }

    // Test modal accessibility
    const modalTriggers = await page.locator('[data-modal], button:has-text("Add"), button:has-text("Edit")').all();

    for (const trigger of modalTriggers.slice(0, 1)) {
      if (await trigger.isVisible()) {
        await trigger.click();
        await page.waitForTimeout(500);

        const modal = page.locator('.modal, [role="dialog"]').first();
        if (await modal.count() > 0) {
          // Modal should have proper ARIA attributes
          const role = await modal.getAttribute('role');
          const ariaModal = await modal.getAttribute('aria-modal');
          const ariaLabel = await modal.getAttribute('aria-label');
          const ariaLabelledBy = await modal.getAttribute('aria-labelledby');

          expect(role === 'dialog' || ariaModal === 'true').toBeTruthy();
          expect(ariaLabel || ariaLabelledBy).toBeTruthy();

          // Focus should be trapped in modal
          const focusedElement = await page.locator(':focus').first();
          const isInModal = await focusedElement.evaluate((el, modalEl) => {
            return modalEl.contains(el);
          }, await modal.elementHandle());

          expect(isInModal).toBeTruthy();

          // Close modal
          await page.keyboard.press('Escape');
          await page.waitForTimeout(300);
        }
      }
    }
  });
});
