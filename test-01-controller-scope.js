import { chromium } from 'playwright';

export async function testControllerScope() {
  console.log('🧪 TEST 1: Controller Scope and Connection');
  console.log('==========================================');
  
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  const results = {
    passed: false,
    details: {},
    errors: []
  };
  
  try {
    await page.goto('http://localhost:3002', { waitUntil: 'networkidle' });
    await page.setViewportSize({ width: 375, height: 667 });
    await page.waitForTimeout(2000);
    
    // Check controller attachment
    const controllerCheck = await page.evaluate(() => {
      const body = document.querySelector('body[data-controller="mobile-menu"]');
      const nav = document.querySelector('nav[data-controller="mobile-menu"]');
      
      return {
        bodyHasController: !!body,
        navHasController: !!nav,
        bodyElement: body ? body.tagName : null
      };
    });
    
    console.log('🎮 Controller attachment:');
    console.log(`   Body has controller: ${controllerCheck.bodyHasController}`);
    console.log(`   Nav has controller: ${controllerCheck.navHasController}`);
    
    // Check all targets exist and are accessible
    const targetsCheck = await page.evaluate(() => {
      const button = document.querySelector('[data-mobile-menu-target="button"]');
      const hamburger = document.querySelector('[data-mobile-menu-target="hamburger"]');
      const backdrop = document.querySelector('[data-mobile-menu-target="backdrop"]');
      const drawer = document.querySelector('[data-mobile-menu-target="drawer"]');
      
      return {
        button: !!button,
        hamburger: !!hamburger,  
        backdrop: !!backdrop,
        drawer: !!drawer,
        allTargetsExist: !!(button && hamburger && backdrop && drawer)
      };
    });
    
    console.log('🎯 Stimulus targets:');
    console.log(`   Button: ${targetsCheck.button}`);
    console.log(`   Hamburger: ${targetsCheck.hamburger}`);
    console.log(`   Backdrop: ${targetsCheck.backdrop}`);
    console.log(`   Drawer: ${targetsCheck.drawer}`);
    console.log(`   All targets exist: ${targetsCheck.allTargetsExist}`);
    
    // Check Stimulus connection
    const stimulusCheck = await page.evaluate(() => {
      return {
        stimulusLoaded: typeof window.Stimulus !== 'undefined',
        applicationExists: window.Stimulus && !!window.Stimulus.application
      };
    });
    
    console.log('⚡ Stimulus framework:');
    console.log(`   Stimulus loaded: ${stimulusCheck.stimulusLoaded}`);
    console.log(`   Application exists: ${stimulusCheck.applicationExists}`);
    
    // Determine if test passed
    const testPassed = controllerCheck.bodyHasController && 
                      !controllerCheck.navHasController && 
                      targetsCheck.allTargetsExist &&
                      stimulusCheck.stimulusLoaded;
    
    results.passed = testPassed;
    results.details = {
      controllerCheck,
      targetsCheck, 
      stimulusCheck
    };
    
    console.log(`\n${testPassed ? '✅' : '❌'} TEST 1 RESULT: ${testPassed ? 'PASSED' : 'FAILED'}`);
    
    if (!testPassed) {
      if (!controllerCheck.bodyHasController) {
        results.errors.push('Controller not attached to body element');
      }
      if (controllerCheck.navHasController) {
        results.errors.push('Controller still attached to nav element (should be removed)');
      }
      if (!targetsCheck.allTargetsExist) {
        results.errors.push('Not all Stimulus targets are present');
      }
      if (!stimulusCheck.stimulusLoaded) {
        results.errors.push('Stimulus framework not loaded');
      }
    }
    
  } catch (error) {
    results.errors.push(`Test execution error: ${error.message}`);
    console.error('❌ Test 1 Error:', error);
  }
  
  await browser.close();
  return results;
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  testControllerScope().then(results => {
    console.log('\n📊 Final Results:', results);
  });
}