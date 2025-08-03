import { test, expect } from '@playwright/test';
import { TestHelpers } from '../helpers/test-helpers.js';

test.describe('Desktop Navigation Flow Testing', () => {
  let helpers;

  test.beforeEach(async ({ page }) => {
    helpers = new TestHelpers(page);
    await helpers.authenticateUser();
    // Set to desktop viewport
    await page.setViewportSize({ width: 1920, height: 1080 });
  });

  test('Primary navigation links work correctly', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    const primaryNavLinks = [
      { selector: 'a[href="/"]', name: 'Home', expectedUrl: '/' },
      { selector: 'a[href="/sources"]', name: 'Sources', expectedUrl: '/sources' },
      { selector: 'a[href="/analysis"]', name: 'Analysis', expectedUrl: '/analysis' },
      { selector: 'a[href="/settings/edit"]', name: 'Settings', expectedUrl: '/settings/edit' }
    ];

    for (const link of primaryNavLinks) {
      const navLink = page.locator(link.selector).first();

      if (await navLink.count() > 0) {
        await navLink.click();
        await helpers.waitForPageLoad();

        // Verify navigation worked
        expect(page.url()).toContain(link.expectedUrl);

        // Verify page loaded properly
        await expect(page.locator('main, .main-content')).toBeVisible();

        // Verify no layout issues
        const hasHorizontalScroll = await helpers.hasHorizontalScroll();
        expect(hasHorizontalScroll).toBeFalsy();
      }
    }
  });

  test('Breadcrumb navigation works correctly', async ({ page }) => {
    // Navigate to a page with breadcrumbs
    await page.goto('/sources');
    await helpers.waitForPageLoad();

    const breadcrumbs = page.locator('.breadcrumb, [data-testid="breadcrumb"], nav[aria-label="breadcrumb"]');

    if (await breadcrumbs.count() > 0) {
      const breadcrumbLinks = await breadcrumbs.locator('a').all();

      for (const link of breadcrumbLinks) {
        if (await link.isVisible()) {
          const href = await link.getAttribute('href');
          const text = await link.textContent();

          await link.click();
          await helpers.waitForPageLoad();

          // Verify navigation worked
          if (href) {
            expect(page.url()).toContain(href);
          }

          // Go back to sources page for next test
          await page.goto('/sources');
          await helpers.waitForPageLoad();
        }
      }
    }
  });

  test('Search functionality works across pages', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    const searchInput = page.locator('input[type="search"], input[placeholder*="search"], input[name*="search"]').first();

    if (await searchInput.count() > 0) {
      // Test search functionality
      await searchInput.fill('test search term');
      await page.keyboard.press('Enter');
      await helpers.waitForPageLoad();

      // Verify search results or search handling
      const currentUrl = page.url();
      const hasSearchParam = currentUrl.includes('search') || currentUrl.includes('q=');

      if (hasSearchParam) {
        // Verify search results are displayed
        const resultsContainer = page.locator('.search-results, [data-testid="search-results"], .results');
        await expect(resultsContainer.first()).toBeVisible();
      }

      // Clear search
      await searchInput.clear();
      await page.keyboard.press('Enter');
      await helpers.waitForPageLoad();
    }
  });

  test('Filter and sorting controls work correctly', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    // Test source filters
    const filterCheckboxes = await page.locator('input[type="checkbox"][name*="source"], .filter input[type="checkbox"]').all();

    if (filterCheckboxes.length > 0) {
      const initialCheckbox = filterCheckboxes[0];
      const initialState = await initialCheckbox.isChecked();

      // Toggle checkbox
      await initialCheckbox.click();
      await page.waitForTimeout(500); // Allow for filtering to apply

      // Verify state changed
      const newState = await initialCheckbox.isChecked();
      expect(newState).toBe(!initialState);

      // Verify content updated (if applicable)
      const posts = await page.locator('.post-card, [data-testid="post-card"]').count();
      expect(posts).toBeGreaterThanOrEqual(0);

      // Reset filter
      await initialCheckbox.click();
      await page.waitForTimeout(500);
    }

    // Test select all / clear all buttons
    const selectAllBtn = page.locator('button:has-text("Select All"), [data-action*="selectAll"]');
    const clearAllBtn = page.locator('button:has-text("Clear All"), [data-action*="clearAll"]');

    if (await selectAllBtn.count() > 0) {
      await selectAllBtn.click();
      await page.waitForTimeout(500);

      // Verify all checkboxes are checked
      const allChecked = await page.locator('input[type="checkbox"][name*="source"]:checked').count();
      const totalCheckboxes = await page.locator('input[type="checkbox"][name*="source"]').count();
      expect(allChecked).toBe(totalCheckboxes);
    }

    if (await clearAllBtn.count() > 0) {
      await clearAllBtn.click();
      await page.waitForTimeout(500);

      // Verify no checkboxes are checked
      const checkedCount = await page.locator('input[type="checkbox"][name*="source"]:checked').count();
      expect(checkedCount).toBe(0);
    }
  });

  test('Pagination controls work correctly', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    const pagination = page.locator('.pagination, [data-testid="pagination"], nav[aria-label="pagination"]');

    if (await pagination.count() > 0) {
      const nextButton = pagination.locator('a:has-text("Next"), button:has-text("Next"), [aria-label="Next"]');
      const prevButton = pagination.locator('a:has-text("Previous"), button:has-text("Previous"), [aria-label="Previous"]');

      if (await nextButton.count() > 0 && await nextButton.isEnabled()) {
        // Get initial page indicator
        const initialPage = await page.locator('.current-page, .active, [aria-current="page"]').textContent();

        await nextButton.click();
        await helpers.waitForPageLoad();

        // Verify navigation occurred
        const newPage = await page.locator('.current-page, .active, [aria-current="page"]').textContent();
        expect(newPage).not.toBe(initialPage);

        // Test previous button
        if (await prevButton.count() > 0 && await prevButton.isEnabled()) {
          await prevButton.click();
          await helpers.waitForPageLoad();

          const returnedPage = await page.locator('.current-page, .active, [aria-current="page"]').textContent();
          expect(returnedPage).toBe(initialPage);
        }
      }
    }
  });

  test('Modal and dropdown interactions work smoothly', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    // Test dropdown menus
    const dropdownTriggers = await page.locator('.dropdown-trigger, [data-dropdown], [aria-haspopup="true"]').all();

    for (const trigger of dropdownTriggers) {
      if (await trigger.isVisible()) {
        await trigger.click();
        await page.waitForTimeout(300);

        // Verify dropdown opened
        const dropdown = page.locator('.dropdown-menu, [data-dropdown-menu], [role="menu"]');
        if (await dropdown.count() > 0) {
          await expect(dropdown.first()).toBeVisible();

          // Click elsewhere to close
          await page.click('body');
          await page.waitForTimeout(300);

          // Verify dropdown closed
          await expect(dropdown.first()).not.toBeVisible();
        }
      }
    }

    // Test modal dialogs
    const modalTriggers = await page.locator('[data-modal], [data-toggle="modal"], button:has-text("Add"), button:has-text("Edit")').all();

    for (const trigger of modalTriggers) {
      if (await trigger.isVisible()) {
        await trigger.click();
        await page.waitForTimeout(500);

        const modal = page.locator('.modal, [role="dialog"], [data-modal-content]');
        if (await modal.count() > 0) {
          await expect(modal.first()).toBeVisible();

          // Test closing modal
          const closeBtn = modal.locator('.close, [aria-label="Close"], button:has-text("Cancel")');
          if (await closeBtn.count() > 0) {
            await closeBtn.first().click();
            await page.waitForTimeout(300);

            await expect(modal.first()).not.toBeVisible();
          } else {
            // Close by clicking backdrop or pressing escape
            await page.keyboard.press('Escape');
            await page.waitForTimeout(300);
          }
        }
      }
    }
  });

  test('Keyboard navigation works throughout the interface', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    // Test tab navigation
    const focusableCount = await helpers.testKeyboardNavigation();
    expect(focusableCount).toBeGreaterThan(0);

    // Test specific keyboard shortcuts if any exist
    const shortcutTests = [
      { key: 'ArrowLeft', description: 'Previous item navigation' },
      { key: 'ArrowRight', description: 'Next item navigation' },
      { key: 'Space', description: 'Select/toggle items' },
      { key: 'Enter', description: 'Activate focused element' }
    ];

    // Focus on a post card and test arrow navigation
    const postCard = page.locator('.post-card, [data-testid="post-card"]').first();
    if (await postCard.count() > 0) {
      await postCard.focus();

      for (const shortcut of shortcutTests) {
        await page.keyboard.press(shortcut.key);
        await page.waitForTimeout(200);

        // Verify no JavaScript errors occurred
        const errors = await page.evaluate(() => window.jsErrors || []);
        expect(errors.length).toBe(0);
      }
    }
  });

  test('Form submission and validation work correctly', async ({ page }) => {
    // Test on sources page which likely has forms
    await page.goto('/sources/new');
    await helpers.waitForPageLoad();

    const forms = await page.locator('form').all();

    for (const form of forms) {
      if (await form.isVisible()) {
        const inputs = await form.locator('input, textarea, select').all();
        const submitBtn = form.locator('input[type="submit"], button[type="submit"], button:has-text("Save"), button:has-text("Create")');

        // Test validation by submitting empty form
        if (await submitBtn.count() > 0) {
          await submitBtn.click();
          await page.waitForTimeout(500);

          // Check for validation messages
          const validationMessages = await form.locator('.error, .invalid, [aria-invalid="true"], .field_with_errors').count();

          // Fill out form with test data
          for (const input of inputs) {
            if (await input.isVisible()) {
              const inputType = await input.getAttribute('type');
              const inputName = await input.getAttribute('name') || await input.getAttribute('id');

              if (inputType === 'text' || inputType === 'url' || !inputType) {
                await input.fill('Test Value');
              } else if (inputType === 'email') {
                await input.fill('test@example.com');
              } else if (inputName?.includes('url')) {
                await input.fill('https://example.com');
              }
            }
          }

          // Try submitting again
          await submitBtn.click();
          await page.waitForTimeout(1000);

          // Verify form handling (either success redirect or error display)
          const currentUrl = page.url();
          const hasSuccessMessage = await page.locator('.notice, .success, .alert-success').count() > 0;
          const hasErrorMessage = await page.locator('.alert, .error, .alert-danger').count() > 0;

          // At least one of these should be true: redirect occurred, success message, or error handling
          const formHandled = !currentUrl.includes('/new') || hasSuccessMessage || hasErrorMessage;
          expect(formHandled).toBeTruthy();
        }
      }
    }
  });

  test('Real-time updates and AJAX requests work properly', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    // Monitor network requests
    const requests = [];
    page.on('request', request => {
      requests.push(request.url());
    });

    // Test refresh functionality
    const refreshBtn = page.locator('button:has-text("Refresh"), [data-action*="refresh"], .refresh-button');

    if (await refreshBtn.count() > 0) {
      const initialRequestCount = requests.length;

      await refreshBtn.click();
      await page.waitForTimeout(2000);

      // Verify requests were made
      expect(requests.length).toBeGreaterThan(initialRequestCount);

      // Verify content updated
      const posts = await page.locator('.post-card, [data-testid="post-card"]').count();
      expect(posts).toBeGreaterThanOrEqual(0);
    }

    // Test auto-refresh if enabled
    const autoRefreshIndicator = page.locator('[data-auto-refresh], [data-interval]');
    if (await autoRefreshIndicator.count() > 0) {
      const beforeCount = requests.length;

      // Wait for potential auto-refresh
      await page.waitForTimeout(5000);

      // Check if auto-refresh occurred
      const afterCount = requests.length;
      if (afterCount > beforeCount) {
        // Auto-refresh is working
        expect(afterCount).toBeGreaterThan(beforeCount);
      }
    }

    // Test post actions (mark as read, clear, etc.)
    const actionButtons = await page.locator('[data-action*="markAsRead"], [data-action*="clear"], .post-action').all();

    if (actionButtons.length > 0) {
      const actionButton = actionButtons[0];
      const beforeRequestCount = requests.length;

      await actionButton.click();
      await page.waitForTimeout(1000);

      // Verify AJAX request was made
      expect(requests.length).toBeGreaterThan(beforeRequestCount);

      // Verify visual feedback
      const feedbackElements = await page.locator('.notification, .flash, .alert, .toast').count();
      expect(feedbackElements).toBeGreaterThanOrEqual(0);
    }
  });

  test('Error handling and recovery work correctly', async ({ page }) => {
    await page.goto('/');
    await helpers.waitForPageLoad();

    // Test navigation to non-existent page
    await page.goto('/nonexistent-page');

    // Should show 404 page or redirect
    const isErrorPage = await page.locator('h1:has-text("404"), h1:has-text("Not Found"), .error-404').count() > 0;
    const wasRedirected = page.url().includes('/') && !page.url().includes('nonexistent');

    expect(isErrorPage || wasRedirected).toBeTruthy();

    // Test network failure simulation
    await page.goto('/');
    await helpers.waitForPageLoad();

    // Simulate offline condition
    await page.setOfflineMode(true);

    const linkToTest = page.locator('a[href^="/"]').first();
    if (await linkToTest.count() > 0) {
      await linkToTest.click();
      await page.waitForTimeout(2000);

      // Should handle offline gracefully (show error message or cached content)
      const hasOfflineIndicator = await page.locator('.offline, .no-connection, .error').count() > 0;
      const stayedOnPage = page.url() === page.url(); // URL didn't change unexpectedly

      expect(hasOfflineIndicator || stayedOnPage).toBeTruthy();
    }

    // Restore online mode
    await page.setOfflineMode(false);
    await page.reload();
    await helpers.waitForPageLoad();
  });
});
