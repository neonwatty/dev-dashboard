import { test as setup, expect } from '@playwright/test';

const authFile = 'test/playwright/.auth/user.json';

setup('authenticate', async ({ page }) => {
  // Perform authentication steps
  await page.goto('/sessions/new');
  await page.fill('input[name="email_address"]', 'user@example.com');
  await page.fill('input[name="password"]', 'password');
  await page.click('button[type="submit"]');

  // Wait until the page receives the cookies
  await page.waitForURL('/');

  // Ensure user is properly authenticated
  await expect(page.locator('body')).not.toContainText('Sign in');

  // End of authentication steps
  await page.context().storageState({ path: authFile });
});
