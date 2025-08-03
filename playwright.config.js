import { defineConfig, devices } from '@playwright/test';

/**
 * @see https://playwright.dev/docs/test-configuration
 */
export default defineConfig({
  testDir: './test/playwright',
  /* Run tests in files in parallel */
  fullyParallel: true,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,
  /* Retry on CI only */
  retries: process.env.CI ? 2 : 0,
  /* Opt out of parallel tests on CI. */
  workers: process.env.CI ? 1 : undefined,
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: [
    ['html', { outputFolder: 'test/playwright-report' }],
    ['json', { outputFile: 'test/playwright-report/results.json' }],
    ['line']
  ],
  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('/')`. */
    baseURL: process.env.PLAYWRIGHT_BASE_URL || 'http://127.0.0.1:3000',
    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    trace: 'on-first-retry',
    /* Take screenshot on failure */
    screenshot: 'only-on-failure',
    /* Record video on failure */
    video: 'retain-on-failure',
  },

  /* Configure projects for major browsers and devices */
  projects: [
    // Desktop browsers with various resolutions
    {
      name: 'chromium-desktop-fhd',
      use: { 
        ...devices['Desktop Chrome'],
        viewport: { width: 1920, height: 1080 },
      },
    },
    {
      name: 'chromium-desktop-hd',
      use: { 
        ...devices['Desktop Chrome'],
        viewport: { width: 1440, height: 900 },
      },
    },
    {
      name: 'chromium-desktop-4k',
      use: { 
        ...devices['Desktop Chrome'],
        viewport: { width: 2560, height: 1440 },
      },
    },
    {
      name: 'firefox-desktop',
      use: { 
        ...devices['Desktop Firefox'],
        viewport: { width: 1920, height: 1080 },
      },
    },
    {
      name: 'webkit-desktop',
      use: { 
        ...devices['Desktop Safari'],
        viewport: { width: 1920, height: 1080 },
      },
    },

    // Mobile devices
    {
      name: 'mobile-chrome-iphone-se',
      use: { ...devices['iPhone SE'] },
    },
    {
      name: 'mobile-chrome-iphone-12',
      use: { ...devices['iPhone 12'] },
    },
    {
      name: 'mobile-chrome-pixel-5',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'mobile-safari-iphone',
      use: { ...devices['iPhone 12'] },
    },

    // Tablets
    {
      name: 'tablet-ipad',
      use: { ...devices['iPad Pro'] },
    },
    {
      name: 'tablet-android',
      use: { 
        ...devices['Galaxy Tab S4'],
      },
    },
  ],

  /* Run your local dev server before starting the tests */
  webServer: {
    command: process.env.CI ? 'bin/rails server -e test -p 3000' : 'bin/dev',
    url: 'http://127.0.0.1:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120 * 1000,
    env: {
      RAILS_ENV: 'test',
      NODE_ENV: 'test',
    },
  },

  /* Global test timeout */
  timeout: 30 * 1000,
  expect: {
    /* Maximum time expect() should wait for the condition to be met. */
    timeout: 5000
  },

  /* Test directory organization */
  testMatch: [
    'test/playwright/**/*.spec.js',
    'test/playwright/**/*.test.js'
  ],
});