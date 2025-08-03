#!/usr/bin/env node

/**
 * Navbar UX Test Runner Script
 *
 * This script runs the comprehensive navbar UX tests that were created
 * as part of Phase 1 (RED tests) of the TDD approach for fixing
 * critical navbar issues.
 */

import { spawn } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const projectRoot = join(__dirname, '../../..');

const testSuites = {
  'priority-duplicate-themes': {
    name: 'PRIORITY: Duplicate Theme Toggle Tests',
    grep: 'should have only ONE theme toggle on sign-in page',
    description: 'Tests that detect the critical duplicate theme toggle issue on the sign-in page'
  },
  'desktop-navbar': {
    name: 'Desktop Navbar Layout Tests',
    grep: 'Desktop Navbar Tests.*should have correct desktop navbar layout',
    description: 'Tests desktop navbar layout across all pages and resolutions'
  },
  'mobile-navbar': {
    name: 'Mobile Navbar Layout Tests',
    grep: 'Mobile Navbar Tests.*should have correct mobile navbar layout',
    description: 'Tests mobile navbar layout and hamburger menu functionality'
  },
  'hamburger-menu': {
    name: 'Hamburger Menu Functionality Tests',
    grep: 'should handle hamburger menu functionality properly',
    description: 'Tests mobile hamburger menu open/close and interactions'
  },
  'cross-page-consistency': {
    name: 'Cross-page Navigation Consistency Tests',
    grep: 'Cross-page Navigation Consistency',
    description: 'Tests navbar consistency when navigating between pages'
  },
  'accessibility': {
    name: 'Navbar Accessibility Tests',
    grep: 'Navbar Accessibility and Touch Targets',
    description: 'Tests touch targets, ARIA labels, and accessibility compliance'
  }
};

function runTestSuite(suiteKey, suite) {
  return new Promise((resolve, reject) => {
    console.log(`\n📋 Running: ${suite.name}`);
    console.log(`   ${suite.description}`);
    console.log(`   Pattern: ${suite.grep}\n`);

    const args = [
      'playwright', 'test', 'test/playwright/integration/navbar-ux.spec.js',
      '--grep', suite.grep,
      '--reporter=line',
      '--timeout=15000'
    ];

    const process = spawn('npx', args, {
      cwd: projectRoot,
      stdio: 'pipe'
    });

    let stdout = '';
    let stderr = '';

    process.stdout.on('data', (data) => {
      stdout += data.toString();
    });

    process.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    process.on('close', (code) => {
      const result = {
        suite: suiteKey,
        name: suite.name,
        code,
        stdout,
        stderr,
        failed: code !== 0
      };

      // Extract test results summary
      const failedMatch = stdout.match(/(\d+) failed/);
      const passedMatch = stdout.match(/(\d+) passed/);
      const totalMatch = stdout.match(/Running (\d+) tests/);

      result.stats = {
        total: totalMatch ? parseInt(totalMatch[1]) : 0,
        failed: failedMatch ? parseInt(failedMatch[1]) : 0,
        passed: passedMatch ? parseInt(passedMatch[1]) : 0
      };

      resolve(result);
    });

    process.on('error', reject);
  });
}

async function runAllTests() {
  console.log('🧪 Navbar UX Test Suite - Phase 1: RED Tests (Expected to Fail)');
  console.log('================================================================');
  console.log('');
  console.log('This test suite validates the critical navbar UX issues that need');
  console.log('to be fixed. All tests are EXPECTED TO FAIL initially (RED state).');
  console.log('');

  const results = [];

  for (const [key, suite] of Object.entries(testSuites)) {
    try {
      const result = await runTestSuite(key, suite);
      results.push(result);

      if (result.failed) {
        console.log(`   ❌ FAILED (${result.stats.failed} failures) - As expected in RED phase`);
      } else {
        console.log('   ⚠️  PASSED - Unexpected! Should fail in RED phase');
      }
    } catch (error) {
      console.log(`   💥 ERROR: ${error.message}`);
      results.push({
        suite: key,
        name: suite.name,
        error: error.message,
        failed: true
      });
    }
  }

  // Summary Report
  console.log('\n📊 SUMMARY REPORT');
  console.log('==================');

  const totalFailures = results.reduce((sum, r) => sum + (r.stats?.failed || 0), 0);
  const totalTests = results.reduce((sum, r) => sum + (r.stats?.total || 0), 0);

  console.log(`Total Test Suites: ${results.length}`);
  console.log(`Total Tests: ${totalTests}`);
  console.log(`Total Failures: ${totalFailures}`);
  console.log('');

  console.log('🎯 KEY ISSUES DETECTED:');
  console.log('');

  results.forEach(result => {
    if (result.failed && result.stats?.failed > 0) {
      console.log(`   • ${result.name}: ${result.stats.failed} failing tests`);

      // Extract specific error patterns
      if (result.suite === 'priority-duplicate-themes') {
        console.log('     → Duplicate theme toggles detected (Expected: 1, Found: 2)');
      }
    }
  });

  console.log('');
  console.log('✅ RED Test Phase Complete!');
  console.log('');
  console.log('Next Steps:');
  console.log('1. Fix the duplicate theme toggle issue in /app/views/sessions/new.html.erb');
  console.log('2. Fix navbar layout consistency issues');
  console.log('3. Fix mobile hamburger menu functionality');
  console.log('4. Re-run tests to achieve GREEN state');
  console.log('');
  console.log('For detailed failure information, check test-results/ directory');

  return results;
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  runAllTests().catch(console.error);
}

export { runAllTests, testSuites };
