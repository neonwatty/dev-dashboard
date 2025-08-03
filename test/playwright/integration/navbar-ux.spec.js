import { test, expect } from '@playwright/test';
import { TestHelpers, MobileTestHelpers } from '../helpers/test-helpers.js';

/**
 * Comprehensive Navbar UX Tests - Phase 1: RED Tests (Should FAIL Initially)
 *
 * Critical Issues Being Tested:
 * 1. PRIORITY: Sign-in page (/sessions/new) has duplicate theme toggle buttons
 * 2. Hamburger menu functionality on mobile
 * 3. Navbar layout consistency across all pages
 */

// Test data configuration
const PAGES_TO_TEST = [
  { path: '/', name: 'Dashboard', requiresAuth: false },
  { path: '/session/new', name: 'Sign in', requiresAuth: false },
  { path: '/registrations/new', name: 'Sign up', requiresAuth: false },
  { path: '/settings/edit', name: 'Settings', requiresAuth: true },
  { path: '/sources', name: 'Sources listing', requiresAuth: false },
  { path: '/sources/new', name: 'New source', requiresAuth: true },
  { path: '/analysis', name: 'Analysis', requiresAuth: true }
];

const DESKTOP_BREAKPOINTS = [
  { name: 'desktop-hd', width: 1440, height: 900 },
  { name: 'desktop-fhd', width: 1920, height: 1080 },
  { name: 'desktop-4k', width: 2560, height: 1440 }
];

const MOBILE_BREAKPOINTS = [
  { name: 'mobile-iphone-se', width: 375, height: 667 },
  { name: 'mobile-iphone-12', width: 390, height: 844 },
  { name: 'mobile-pixel-5', width: 393, height: 851 }
];

const TABLET_BREAKPOINTS = [
  { name: 'tablet-ipad-portrait', width: 768, height: 1024 },
  { name: 'tablet-ipad-landscape', width: 1024, height: 768 }
];

// Helper functions
async function setupAuthenticatedUser(page) {
  const helpers = new TestHelpers(page);
  await helpers.authenticateUser();
}

async function verifyNavbarStructure(page, _breakpoint) {
  const navbar = page.locator('#main-navigation');
  await expect(navbar).toBeVisible();

  // Check for main navbar container with correct layout
  const navbarContainer = navbar.locator('.responsive-container > .flex.justify-between.items-center').first();
  await expect(navbarContainer).toBeVisible();

  return navbar;
}

async function countThemeToggleButtons(page) {
  // Count all theme toggle buttons on the page
  const themeButtons = page.locator('[aria-label*="Toggle dark mode"], [data-action*="dark-mode#toggle"]');
  return await themeButtons.count();
}

// Desktop Tests (>= 768px)
test.describe('Desktop Navbar Tests (>= 768px)', () => {

  DESKTOP_BREAKPOINTS.forEach(breakpoint => {
    test.describe(`${breakpoint.name} (${breakpoint.width}x${breakpoint.height})`, () => {

      test.beforeEach(async ({ page }) => {
        await page.setViewportSize({ width: breakpoint.width, height: breakpoint.height });
      });

      PAGES_TO_TEST.forEach(pageConfig => {
        test(`should have correct desktop navbar layout on ${pageConfig.name}`, async ({ page }) => {
          // Setup authentication if required
          if (pageConfig.requiresAuth) {
            await setupAuthenticatedUser(page);
          }

          await page.goto(pageConfig.path);
          await page.waitForLoadState('networkidle');

          const navbar = await verifyNavbarStructure(page, breakpoint);

          // Desktop navigation links should be visible
          const desktopNav = navbar.locator('.hidden.md\\:flex.md\\:items-center');
          await expect(desktopNav).toBeVisible();

          // Mobile hamburger should be hidden
          const hamburgerButton = navbar.locator('.md\\:hidden[data-action*="mobile-menu#toggle"]');
          await expect(hamburgerButton).toBeHidden();

          // Only ONE theme toggle button should be visible
          const themeButtonCount = await countThemeToggleButtons(page);
          expect(themeButtonCount).toBe(1);

          // Auth buttons/user info should display correctly
          const authSection = navbar.locator('.hidden.md\\:flex.items-center');
          if (pageConfig.requiresAuth) {
            await expect(authSection).toContainText(/Settings|Sign out/);
          } else {
            await expect(authSection).toContainText(/Sign in|Sign up/);
          }

          // Single row layout maintained
          const navHeight = await navbar.evaluate(el => el.offsetHeight);
          expect(navHeight).toBeLessThan(80); // Should be single row, approximately 64px + borders
        });
      });

      test('should maintain consistent layout across navigation', async ({ page }) => {
        const helpers = new TestHelpers(page);

        // Test navigation between pages maintains layout
        await page.goto('/');
        const initialNavbar = await verifyNavbarStructure(page, breakpoint);
        const initialHeight = await initialNavbar.evaluate(el => el.offsetHeight);

        // Navigate to different pages and verify consistency
        for (const pageConfig of PAGES_TO_TEST.slice(0, 3)) { // Test first 3 pages for performance
          await page.goto(pageConfig.path);
          await helpers.waitForPageLoad();

          const currentNavbar = await verifyNavbarStructure(page, breakpoint);
          const currentHeight = await currentNavbar.evaluate(el => el.offsetHeight);

          // Heights should be consistent (within 2px tolerance for border differences)
          expect(Math.abs(currentHeight - initialHeight)).toBeLessThan(3);

          // Theme toggle count should remain 1
          const themeButtonCount = await countThemeToggleButtons(page);
          expect(themeButtonCount).toBe(1);
        }
      });

      test('should handle theme toggle interaction properly', async ({ page }) => {
        await page.goto('/');
        await page.waitForLoadState('networkidle');

        // Find the theme toggle button
        const themeButton = page.locator('[data-action*="dark-mode#toggle"]').first();
        await expect(themeButton).toBeVisible();

        // Check initial state
        const initialPressed = await themeButton.getAttribute('aria-pressed');

        // Click theme toggle
        await themeButton.click();
        await page.waitForTimeout(300); // Allow transition

        // Verify state changed
        const newPressed = await themeButton.getAttribute('aria-pressed');
        expect(newPressed).not.toBe(initialPressed);

        // Verify only one theme button is still present
        const themeButtonCount = await countThemeToggleButtons(page);
        expect(themeButtonCount).toBe(1);
      });
    });
  });
});

// Mobile Tests (< 768px)
test.describe('Mobile Navbar Tests (< 768px)', () => {

  MOBILE_BREAKPOINTS.forEach(breakpoint => {
    test.describe(`${breakpoint.name} (${breakpoint.width}x${breakpoint.height})`, () => {

      test.beforeEach(async ({ page }) => {
        await page.setViewportSize({ width: breakpoint.width, height: breakpoint.height });
      });

      PAGES_TO_TEST.forEach(pageConfig => {
        test(`should have correct mobile navbar layout on ${pageConfig.name}`, async ({ page }) => {
          // Setup authentication if required
          if (pageConfig.requiresAuth) {
            await setupAuthenticatedUser(page);
          }

          await page.goto(pageConfig.path);
          await page.waitForLoadState('networkidle');

          const navbar = await verifyNavbarStructure(page, breakpoint);

          // Mobile layout should show: Logo + hamburger + theme toggle only
          const logo = navbar.locator('a[href="/"]');
          await expect(logo).toBeVisible();

          // Hamburger menu button should be visible
          const hamburgerButton = navbar.locator('.md\\:hidden[data-action*="mobile-menu#toggle"]');
          await expect(hamburgerButton).toBeVisible();

          // Desktop navigation links should be hidden
          const desktopNav = navbar.locator('.hidden.md\\:flex.md\\:items-center');
          await expect(desktopNav).toBeHidden();

          // Only ONE theme toggle button should be visible
          const themeButtonCount = await countThemeToggleButtons(page);
          expect(themeButtonCount).toBe(1);

          // Single row layout maintained
          const navHeight = await navbar.evaluate(el => el.offsetHeight);
          expect(navHeight).toBeLessThan(70); // Should be single row, approximately 56px + borders
        });
      });

      test('should handle hamburger menu functionality properly', async ({ page }) => {
        const _helpers = new MobileTestHelpers(page);

        await page.goto('/');
        await page.waitForLoadState('networkidle');

        // Find hamburger button
        const hamburgerButton = page.locator('[data-action*="mobile-menu#toggle"]');
        await expect(hamburgerButton).toBeVisible();

        // Mobile drawer should be initially closed
        const mobileDrawer = page.locator('[data-mobile-menu-target="drawer"]');
        await expect(mobileDrawer).toHaveClass(/closed/);

        // Click hamburger to open menu
        await hamburgerButton.click();
        await page.waitForTimeout(300); // Allow animation

        // Menu should be open
        await expect(mobileDrawer).not.toHaveClass(/closed/);
        await expect(mobileDrawer).toBeVisible();

        // Backdrop should be visible
        const backdrop = page.locator('[data-mobile-menu-target="backdrop"]');
        await expect(backdrop).toBeVisible();

        // Menu should contain navigation links
        const mobileNavLinks = mobileDrawer.locator('.mobile-nav-link');
        await expect(mobileNavLinks.first()).toBeVisible();

        // Close menu by clicking backdrop
        await backdrop.click();
        await page.waitForTimeout(300); // Allow animation

        // Menu should be closed
        await expect(mobileDrawer).toHaveClass(/closed/);
        await expect(backdrop).toBeHidden();
      });

      test('should handle swipe-to-close functionality', async ({ page }) => {
        const helpers = new MobileTestHelpers(page);

        await page.goto('/');
        await page.waitForLoadState('networkidle');

        // Open mobile menu
        const hamburgerButton = page.locator('[data-action*="mobile-menu#toggle"]');
        await hamburgerButton.click();
        await page.waitForTimeout(300);

        const mobileDrawer = page.locator('[data-mobile-menu-target="drawer"]');
        await expect(mobileDrawer).toBeVisible();

        // Simulate swipe left to close
        await helpers.simulateSwipe(mobileDrawer, 'left', 150);
        await page.waitForTimeout(500);

        // Menu should be closed
        await expect(mobileDrawer).toHaveClass(/closed/);
      });

      test('should maintain focus trapping in mobile menu', async ({ page }) => {
        await page.goto('/');
        await page.waitForLoadState('networkidle');

        // Open mobile menu
        const hamburgerButton = page.locator('[data-action*="mobile-menu#toggle"]');
        await hamburgerButton.click();
        await page.waitForTimeout(300);

        const mobileDrawer = page.locator('[data-mobile-menu-target="drawer"]');
        await expect(mobileDrawer).toBeVisible();

        // Focus should be trapped within the drawer
        await page.keyboard.press('Tab');
        const focusedElement = page.locator(':focus');

        // Focused element should be within the drawer
        const isWithinDrawer = await focusedElement.evaluate((el, drawer) => {
          return drawer.contains(el);
        }, await mobileDrawer.elementHandle());

        expect(isWithinDrawer).toBe(true);
      });
    });
  });
});

// Tablet Tests
test.describe('Tablet Navbar Tests', () => {

  TABLET_BREAKPOINTS.forEach(breakpoint => {
    test.describe(`${breakpoint.name} (${breakpoint.width}x${breakpoint.height})`, () => {

      test.beforeEach(async ({ page }) => {
        await page.setViewportSize({ width: breakpoint.width, height: breakpoint.height });
      });

      test('should use appropriate layout for tablet size', async ({ page }) => {
        await page.goto('/');
        await page.waitForLoadState('networkidle');

        const navbar = await verifyNavbarStructure(page, breakpoint);

        if (breakpoint.width >= 768) {
          // Should use desktop layout
          const desktopNav = navbar.locator('.hidden.md\\:flex.md\\:items-center');
          await expect(desktopNav).toBeVisible();

          const hamburgerButton = navbar.locator('.md\\:hidden[data-action*="mobile-menu#toggle"]');
          await expect(hamburgerButton).toBeHidden();
        } else {
          // Should use mobile layout
          const desktopNav = navbar.locator('.hidden.md\\:flex.md\\:items-center');
          await expect(desktopNav).toBeHidden();

          const hamburgerButton = navbar.locator('.md\\:hidden[data-action*="mobile-menu#toggle"]');
          await expect(hamburgerButton).toBeVisible();
        }

        // Only ONE theme toggle button should be visible
        const themeButtonCount = await countThemeToggleButtons(page);
        expect(themeButtonCount).toBe(1);
      });
    });
  });
});

// PRIORITY TEST: Sign-in Page Duplicate Theme Toggles
test.describe('PRIORITY: Sign-in Page Duplicate Theme Toggle Issue', () => {

  // Test across all device sizes for this critical issue
  const ALL_BREAKPOINTS = [...DESKTOP_BREAKPOINTS, ...MOBILE_BREAKPOINTS, ...TABLET_BREAKPOINTS];

  ALL_BREAKPOINTS.forEach(breakpoint => {
    test(`should have only ONE theme toggle on sign-in page - ${breakpoint.name}`, async ({ page }) => {
      await page.setViewportSize({ width: breakpoint.width, height: breakpoint.height });

      // Navigate to sign-in page
      await page.goto('/session/new');
      await page.waitForLoadState('networkidle');

      // Count all theme toggle buttons on the page
      const themeButtonCount = await countThemeToggleButtons(page);

      // CRITICAL: Should be exactly 1, but currently will be 2 (navbar + page-specific)
      expect(themeButtonCount).toBe(1);

      // Verify the main navbar theme toggle is present
      const navbarThemeButton = page.locator('#main-navigation [data-action*="dark-mode#toggle"]');
      await expect(navbarThemeButton).toBeVisible();

      // Verify no duplicate theme toggle exists on the page
      const pageThemeButton = page.locator('.absolute.top-4.right-4 [data-action*="dark-mode#toggle"]');
      await expect(pageThemeButton).toBeHidden(); // This should fail initially

      // Test theme toggle functionality
      await navbarThemeButton.click();
      await page.waitForTimeout(300);

      // Verify only one button changed state
      const themeButtonsAfterClick = page.locator('[data-action*="dark-mode#toggle"]');
      const buttonCount = await themeButtonsAfterClick.count();
      expect(buttonCount).toBe(1); // Still should be only 1
    });
  });

  test('should maintain consistent theme state across page elements', async ({ page }) => {
    await page.goto('/sessions/new');
    await page.waitForLoadState('networkidle');

    // Get initial theme state
    const html = page.locator('html');
    const initialDarkMode = await html.evaluate(el => el.classList.contains('dark'));

    // Click theme toggle (should be only one)
    const themeButton = page.locator('[data-action*="dark-mode#toggle"]').first();
    await themeButton.click();
    await page.waitForTimeout(300);

    // Verify theme changed consistently across all elements
    const newDarkMode = await html.evaluate(el => el.classList.contains('dark'));
    expect(newDarkMode).not.toBe(initialDarkMode);

    // Verify all themed elements reflect the change
    const body = page.locator('body');
    const pageContainer = page.locator('.min-h-screen').first();

    if (newDarkMode) {
      await expect(body).toHaveClass(/dark:bg-gray-900/);
      await expect(pageContainer).toHaveClass(/dark:bg-gray-900/);
    } else {
      await expect(body).toHaveClass(/bg-gray-50/);
      await expect(pageContainer).toHaveClass(/bg-gray-50/);
    }
  });
});

// Cross-page Navigation Consistency Tests
test.describe('Cross-page Navigation Consistency', () => {

  test('should maintain theme toggle count when navigating between pages', async ({ page }) => {
    await page.setViewportSize({ width: 1440, height: 900 }); // Desktop

    // Test navigation flow: Dashboard → Sign in → Sign up → Dashboard
    const navigationFlow = [
      { path: '/', expectedCount: 1 },
      { path: '/session/new', expectedCount: 1 }, // This will fail initially due to duplicate
      { path: '/registrations/new', expectedCount: 1 },
      { path: '/', expectedCount: 1 }
    ];

    for (const step of navigationFlow) {
      await page.goto(step.path);
      await page.waitForLoadState('networkidle');

      const themeButtonCount = await countThemeToggleButtons(page);
      expect(themeButtonCount).toBe(step.expectedCount);

      // Verify theme toggle is functional
      const themeButton = page.locator('[data-action*="dark-mode#toggle"]').first();
      await expect(themeButton).toBeVisible();
      await expect(themeButton).toBeEnabled();
    }
  });

  test('should handle theme persistence across page navigation', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Toggle to dark mode
    const themeButton = page.locator('[data-action*="dark-mode#toggle"]').first();
    await themeButton.click();
    await page.waitForTimeout(300);

    // Verify dark mode is active
    const html = page.locator('html');
    await expect(html).toHaveClass(/dark/);

    // Navigate to sign-in page
    await page.goto('/session/new');
    await page.waitForLoadState('networkidle');

    // Theme should persist
    await expect(html).toHaveClass(/dark/);

    // Only one theme toggle should be present
    const themeButtonCount = await countThemeToggleButtons(page);
    expect(themeButtonCount).toBe(1);
  });
});

// Accessibility and Touch Target Tests
test.describe('Navbar Accessibility and Touch Targets', () => {

  test('should meet minimum touch target sizes on mobile', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 }); // iPhone SE

    await page.goto('/');
    await page.waitForLoadState('networkidle');

    const helpers = new TestHelpers(page);

    // Check hamburger button touch target
    const hamburgerButton = page.locator('[data-action*="mobile-menu#toggle"]');
    await helpers.verifyTouchTargetSize('[data-action*="mobile-menu#toggle"]', 44);

    // Check theme toggle touch target
    await helpers.verifyTouchTargetSize('[data-action*="dark-mode#toggle"]', 44);

    // Open mobile menu and check nav link touch targets
    await hamburgerButton.click();
    await page.waitForTimeout(300);

    const mobileNavLinks = page.locator('.mobile-nav-link');
    const linkCount = await mobileNavLinks.count();

    for (let i = 0; i < linkCount; i++) {
      const link = mobileNavLinks.nth(i);
      const box = await link.boundingBox();
      if (box) {
        expect(box.height).toBeGreaterThanOrEqual(44);
      }
    }
  });

  test('should have proper ARIA labels and attributes', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Check navbar has proper navigation role
    const navbar = page.locator('#main-navigation');
    await expect(navbar).toHaveAttribute('id', 'main-navigation');

    // Check theme button has proper ARIA label
    const themeButton = page.locator('[data-action*="dark-mode#toggle"]');
    await expect(themeButton).toHaveAttribute('aria-label', 'Toggle dark mode');

    // Check hamburger button on mobile
    await page.setViewportSize({ width: 375, height: 667 });
    const hamburgerButton = page.locator('[data-action*="mobile-menu#toggle"]');
    await expect(hamburgerButton).toHaveAttribute('aria-label', 'Open navigation menu');
    await expect(hamburgerButton).toHaveAttribute('aria-expanded', 'false');

    // Open menu and check ARIA attributes
    await hamburgerButton.click();
    await page.waitForTimeout(300);

    await expect(hamburgerButton).toHaveAttribute('aria-expanded', 'true');

    const mobileDrawer = page.locator('[data-mobile-menu-target="drawer"]');
    await expect(mobileDrawer).toHaveAttribute('role', 'dialog');
    await expect(mobileDrawer).toHaveAttribute('aria-modal', 'true');
  });
});
