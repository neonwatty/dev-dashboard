#!/usr/bin/env node

/**
 * Comprehensive UX Test Runner
 * Orchestrates Playwright UX tests with Rails integration
 */

import { spawn } from 'child_process';
import fs from 'fs';
import path from 'path';

const TEST_RESULTS_DIR = 'test/playwright-report';
const TEST_CONFIG = {
  desktop: {
    projects: ['chromium-desktop-fhd', 'chromium-desktop-hd', 'chromium-desktop-4k', 'firefox-desktop', 'webkit-desktop'],
    testDir: 'test/playwright/desktop'
  },
  mobile: {
    projects: ['mobile-chrome-iphone-se', 'mobile-chrome-iphone-12', 'mobile-chrome-pixel-5', 'mobile-safari-iphone'],
    testDir: 'test/playwright/mobile'
  },
  performance: {
    projects: ['chromium-desktop-fhd', 'mobile-chrome-iphone-12'],
    testDir: 'test/playwright/performance'
  },
  accessibility: {
    projects: ['chromium-desktop-fhd', 'mobile-chrome-iphone-12', 'firefox-desktop'],
    testDir: 'test/playwright/accessibility'
  },
  integration: {
    projects: ['chromium-desktop-fhd', 'mobile-chrome-iphone-12'],
    testDir: 'test/playwright/integration'
  }
};

class UXTestRunner {
  constructor() {
    this.results = {
      desktop: { passed: 0, failed: 0, skipped: 0 },
      mobile: { passed: 0, failed: 0, skipped: 0 },
      performance: { passed: 0, failed: 0, skipped: 0 },
      accessibility: { passed: 0, failed: 0, skipped: 0 },
      integration: { passed: 0, failed: 0, skipped: 0 }
    };
    this.startTime = Date.now();
    this.errors = [];
  }

  async runTestSuite(suiteName, config) {
    console.log(`\\n🧪 Running ${suiteName} UX tests...`);
    console.log(`📁 Test directory: ${config.testDir}`);
    console.log(`🌐 Browser projects: ${config.projects.join(', ')}`);

    try {
      const results = await this.executePlaywrightTests(config);
      this.results[suiteName] = results;

      if (results.failed > 0) {
        console.log(`❌ ${suiteName} tests: ${results.failed} failed, ${results.passed} passed`);
      } else {
        console.log(`✅ ${suiteName} tests: ${results.passed} passed`);
      }

      return results.failed === 0;
    } catch (error) {
      console.error(`💥 Error running ${suiteName} tests:`, error.message);
      this.errors.push({ suite: suiteName, error: error.message });
      return false;
    }
  }

  async executePlaywrightTests(config) {
    return new Promise((resolve, reject) => {
      const args = [
        'test',
        '--config=playwright.config.js',
        `--project=${config.projects.join(',')}`,
        config.testDir,
        '--reporter=json'
      ];

      if (process.env.CI) {
        args.push('--workers=1');
      }

      const playwrightProcess = spawn('npx', ['playwright', ...args], {
        stdio: ['inherit', 'pipe', 'pipe'],
        env: { ...process.env, FORCE_COLOR: '1' }
      });

      let stdout = '';
      let stderr = '';

      playwrightProcess.stdout.on('data', (data) => {
        stdout += data.toString();
        process.stdout.write(data);
      });

      playwrightProcess.stderr.on('data', (data) => {
        stderr += data.toString();
        process.stderr.write(data);
      });

      playwrightProcess.on('close', (_code) => {
        try {
          // Parse test results from JSON output
          const results = this.parseTestResults(stdout);
          resolve(results);
        } catch (error) {
          reject(new Error(`Failed to parse test results: ${error.message}`));
        }
      });

      playwrightProcess.on('error', (error) => {
        reject(error);
      });
    });
  }

  parseTestResults(output) {
    // Default results structure
    const results = { passed: 0, failed: 0, skipped: 0 };

    try {
      // Try to parse JSON output
      const lines = output.split('\\n');
      for (const line of lines) {
        if (line.trim().startsWith('{') && line.includes('stats')) {
          const jsonResult = JSON.parse(line);
          if (jsonResult.stats) {
            results.passed = jsonResult.stats.passed || 0;
            results.failed = jsonResult.stats.failed || 0;
            results.skipped = jsonResult.stats.skipped || 0;
            break;
          }
        }
      }
    } catch {
      // Fallback: parse from text output
      const passedMatch = output.match(/(\\d+) passed/);
      const failedMatch = output.match(/(\\d+) failed/);
      const skippedMatch = output.match(/(\\d+) skipped/);

      if (passedMatch) {results.passed = parseInt(passedMatch[1]);}
      if (failedMatch) {results.failed = parseInt(failedMatch[1]);}
      if (skippedMatch) {results.skipped = parseInt(skippedMatch[1]);}
    }

    return results;
  }

  async generateReport() {
    const endTime = Date.now();
    const duration = Math.round((endTime - this.startTime) / 1000);

    const totalTests = Object.values(this.results).reduce((acc, result) => ({
      passed: acc.passed + result.passed,
      failed: acc.failed + result.failed,
      skipped: acc.skipped + result.skipped
    }), { passed: 0, failed: 0, skipped: 0 });

    const report = {
      summary: {
        timestamp: new Date().toISOString(),
        duration: `${duration}s`,
        total: totalTests.passed + totalTests.failed + totalTests.skipped,
        passed: totalTests.passed,
        failed: totalTests.failed,
        skipped: totalTests.skipped,
        success: totalTests.failed === 0 && this.errors.length === 0
      },
      suites: this.results,
      errors: this.errors,
      recommendations: this.generateRecommendations()
    };

    // Ensure results directory exists
    if (!fs.existsSync(TEST_RESULTS_DIR)) {
      fs.mkdirSync(TEST_RESULTS_DIR, { recursive: true });
    }

    // Write JSON report
    const reportPath = path.join(TEST_RESULTS_DIR, 'ux-test-results.json');
    fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));

    // Write HTML summary
    await this.generateHTMLReport(report);

    return report;
  }

  generateRecommendations() {
    const recommendations = [];

    // Analyze results and provide recommendations
    if (this.results.performance.failed > 0) {
      recommendations.push({
        category: 'Performance',
        priority: 'High',
        issue: 'Performance tests failing',
        recommendation: 'Review Core Web Vitals metrics and optimize loading times. Check bundle sizes and lazy loading implementation.'
      });
    }

    if (this.results.accessibility.failed > 0) {
      recommendations.push({
        category: 'Accessibility',
        priority: 'High',
        issue: 'Accessibility compliance issues',
        recommendation: 'Review aXe violations and ensure WCAG 2.1 AA compliance. Check color contrast, keyboard navigation, and ARIA implementation.'
      });
    }

    if (this.results.mobile.failed > 0) {
      recommendations.push({
        category: 'Mobile UX',
        priority: 'Medium',
        issue: 'Mobile user experience issues',
        recommendation: 'Review touch target sizes, mobile navigation, and responsive design. Test across different device sizes and orientations.'
      });
    }

    if (this.results.desktop.failed > 0) {
      recommendations.push({
        category: 'Desktop UX',
        priority: 'Medium',
        issue: 'Desktop user experience issues',
        recommendation: 'Review multi-resolution support, navigation flows, and interactive elements. Ensure consistent behavior across browser engines.'
      });
    }

    if (this.errors.length > 0) {
      recommendations.push({
        category: 'Test Infrastructure',
        priority: 'High',
        issue: 'Test execution errors',
        recommendation: 'Review test setup, browser configuration, and test environment. Check for missing dependencies or configuration issues.'
      });
    }

    // Add positive recommendations if all tests pass
    if (recommendations.length === 0) {
      recommendations.push({
        category: 'Maintenance',
        priority: 'Low',
        issue: 'All tests passing',
        recommendation: 'Consider expanding test coverage with additional edge cases, performance scenarios, or accessibility checks.'
      });
    }

    return recommendations;
  }

  async generateHTMLReport(report) {
    const html = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>UX Test Results - Dev Dashboard</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; }
        .status { display: inline-block; padding: 8px 16px; border-radius: 20px; font-weight: 600; }
        .status.success { background: #d4edda; color: #155724; }
        .status.failure { background: #f8d7da; color: #721c24; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .metric { background: #f8f9fa; padding: 20px; border-radius: 8px; text-align: center; }
        .metric-value { font-size: 2em; font-weight: bold; color: #007bff; }
        .metric-label { color: #6c757d; margin-top: 5px; }
        .suites { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .suite { border: 1px solid #dee2e6; border-radius: 8px; padding: 20px; }
        .suite-header { font-weight: 600; font-size: 1.1em; margin-bottom: 15px; }
        .test-result { display: flex; justify-content: space-between; margin: 5px 0; }
        .recommendations { margin-top: 30px; }
        .recommendation { border-left: 4px solid #007bff; padding: 15px; margin: 10px 0; background: #f8f9fa; }
        .recommendation.high { border-color: #dc3545; }
        .recommendation.medium { border-color: #ffc107; }
        .recommendation.low { border-color: #28a745; }
        .error { background: #f8d7da; border: 1px solid #f5c6cb; padding: 15px; border-radius: 8px; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🧪 UX Test Results</h1>
            <p>Dev Dashboard - Comprehensive Desktop and Mobile UX Testing</p>
            <div class="status ${report.summary.success ? 'success' : 'failure'}">
                ${report.summary.success ? '✅ All Tests Passed' : '❌ Some Tests Failed'}
            </div>
            <p><small>Generated: ${report.summary.timestamp} | Duration: ${report.summary.duration}</small></p>
        </div>

        <div class="summary">
            <div class="metric">
                <div class="metric-value">${report.summary.total}</div>
                <div class="metric-label">Total Tests</div>
            </div>
            <div class="metric">
                <div class="metric-value" style="color: #28a745;">${report.summary.passed}</div>
                <div class="metric-label">Passed</div>
            </div>
            <div class="metric">
                <div class="metric-value" style="color: #dc3545;">${report.summary.failed}</div>
                <div class="metric-label">Failed</div>
            </div>
            <div class="metric">
                <div class="metric-value" style="color: #ffc107;">${report.summary.skipped}</div>
                <div class="metric-label">Skipped</div>
            </div>
        </div>

        <div class="suites">
            ${Object.entries(report.suites).map(([name, results]) => `
                <div class="suite">
                    <div class="suite-header">📊 ${name.charAt(0).toUpperCase() + name.slice(1)} Tests</div>
                    <div class="test-result">
                        <span>✅ Passed:</span>
                        <span>${results.passed}</span>
                    </div>
                    <div class="test-result">
                        <span>❌ Failed:</span>
                        <span>${results.failed}</span>
                    </div>
                    <div class="test-result">
                        <span>⏭️ Skipped:</span>
                        <span>${results.skipped}</span>
                    </div>
                </div>
            `).join('')}
        </div>

        ${report.errors.length > 0 ? `
            <div class="errors">
                <h3>🚨 Execution Errors</h3>
                ${report.errors.map(error => `
                    <div class="error">
                        <strong>${error.suite}:</strong> ${error.error}
                    </div>
                `).join('')}
            </div>
        ` : ''}

        <div class="recommendations">
            <h3>💡 Recommendations</h3>
            ${report.recommendations.map(rec => `
                <div class="recommendation ${rec.priority.toLowerCase()}">
                    <strong>${rec.category} (${rec.priority} Priority):</strong> ${rec.issue}<br>
                    <em>Recommendation:</em> ${rec.recommendation}
                </div>
            `).join('')}
        </div>

        <div style="margin-top: 30px; text-align: center; color: #6c757d; font-size: 0.9em;">
            <p>This report was generated by the Comprehensive UX Testing Pipeline</p>
            <p>Test configuration includes cross-browser compatibility, mobile device simulation, performance monitoring, and accessibility compliance</p>
        </div>
    </div>
</body>
</html>`;

    const htmlPath = path.join(TEST_RESULTS_DIR, 'ux-test-results.html');
    fs.writeFileSync(htmlPath, html);

    console.log(`\\n📊 HTML report generated: ${htmlPath}`);
  }

  async run() {
    console.log('🚀 Starting Comprehensive UX Test Suite');
    console.log('=' .repeat(60));

    const testOrder = ['desktop', 'mobile', 'performance', 'accessibility', 'integration'];
    let allPassed = true;

    for (const suiteName of testOrder) {
      const config = TEST_CONFIG[suiteName];
      const passed = await this.runTestSuite(suiteName, config);
      allPassed = allPassed && passed;
    }

    console.log('\\n' + '='.repeat(60));
    console.log('📋 Generating comprehensive test report...');

    const report = await this.generateReport();

    console.log('\\n🎯 UX Test Suite Complete!');
    console.log(`📊 Results: ${report.summary.passed} passed, ${report.summary.failed} failed, ${report.summary.skipped} skipped`);
    console.log(`⏱️ Duration: ${report.summary.duration}`);
    console.log(`📄 Report: ${TEST_RESULTS_DIR}/ux-test-results.html`);

    if (report.summary.success) {
      console.log('\\n✅ All UX tests passed! Your application provides excellent user experience across devices and browsers.');
    } else {
      console.log('\\n❌ Some UX tests failed. Please review the recommendations and address the issues.');
      process.exit(1);
    }
  }
}

// CLI execution
if (import.meta.url === `file://${process.argv[1]}`) {
  const runner = new UXTestRunner();
  runner.run().catch((error) => {
    console.error('💥 Test runner failed:', error);
    process.exit(1);
  });
}

export default UXTestRunner;
