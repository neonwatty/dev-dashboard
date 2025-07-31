// Test script for pull-to-refresh functionality
// This script helps verify the pull-to-refresh feature works correctly on mobile

console.log('🧪 Testing Pull-to-Refresh functionality...')

// Test 1: Check if controllers are loaded
const testControllerLoading = () => {
  console.log('\n📋 Test 1: Controller Loading')
  
  const containers = document.querySelectorAll('[data-controller*="pull-to-refresh"]')
  console.log(`Found ${containers.length} pull-to-refresh containers`)
  
  containers.forEach((container, index) => {
    const controllers = container.getAttribute('data-controller')
    console.log(`Container ${index + 1}: Controllers = ${controllers}`)
    
    // Check if indicators are created
    const indicator = container.querySelector('.pull-refresh-indicator')
    console.log(`Container ${index + 1}: Has indicator = ${!!indicator}`)
    
    if (indicator) {
      console.log(`Container ${index + 1}: Indicator position = ${indicator.style.transform}`)
      console.log(`Container ${index + 1}: Indicator opacity = ${indicator.style.opacity}`)
    }
  })
}

// Test 2: Check CSS styles are loaded
const testCSSStyles = () => {
  console.log('\n🎨 Test 2: CSS Styles')
  
  // Create a test indicator to check styles
  const testDiv = document.createElement('div')
  testDiv.className = 'pull-refresh-indicator'
  testDiv.style.position = 'absolute'
  testDiv.style.top = '-1000px'
  document.body.appendChild(testDiv)
  
  const styles = window.getComputedStyle(testDiv)
  console.log(`Base styles applied: ${styles.display !== 'block' ? '✅' : '❌'}`)
  console.log(`Backdrop filter: ${styles.backdropFilter || 'not supported'}`)
  console.log(`Border radius: ${styles.borderRadius}`)
  
  // Test state classes
  testDiv.classList.add('pulling')
  const pullingStyles = window.getComputedStyle(testDiv)
  console.log(`Pulling state opacity: ${pullingStyles.opacity}`)
  
  testDiv.classList.add('ready')
  const readyStyles = window.getComputedStyle(testDiv)
  console.log(`Ready state background: ${readyStyles.backgroundColor}`)
  
  document.body.removeChild(testDiv)
}

// Test 3: Simulate touch events
const testTouchSimulation = () => {
  console.log('\n👆 Test 3: Touch Event Simulation')
  
  const container = document.querySelector('[data-controller*="pull-to-refresh"]')
  if (!container) {
    console.log('❌ No pull-to-refresh container found')
    return
  }
  
  // Simulate touch start
  const touchStart = new TouchEvent('touchstart', {
    touches: [{
      clientX: window.innerWidth / 2,
      clientY: 100
    }],
    bubbles: true,
    cancelable: true
  })
  
  // Simulate touch move (pull down)
  const touchMove = new TouchEvent('touchmove', {
    touches: [{
      clientX: window.innerWidth / 2,
      clientY: 200 // 100px down
    }],
    bubbles: true,
    cancelable: true
  })
  
  // Simulate touch end
  const touchEnd = new TouchEvent('touchend', {
    bubbles: true,
    cancelable: true
  })
  
  console.log('Dispatching touch events...')
  container.dispatchEvent(touchStart)
  
  setTimeout(() => {
    container.dispatchEvent(touchMove)
    
    // Check if indicator is visible
    const indicator = container.querySelector('.pull-refresh-indicator')
    if (indicator) {
      const opacity = window.getComputedStyle(indicator).opacity
      console.log(`Indicator visibility after move: opacity = ${opacity}`)
    }
    
    setTimeout(() => {
      container.dispatchEvent(touchEnd)
      console.log('Touch simulation completed')
    }, 100)
  }, 50)
}

// Test 4: Check mobile viewport
const testMobileViewport = () => {
  console.log('\n📱 Test 4: Mobile Viewport')
  
  console.log(`Window width: ${window.innerWidth}px`)
  console.log(`Window height: ${window.innerHeight}px`)
  console.log(`Device pixel ratio: ${window.devicePixelRatio}`)
  console.log(`User agent: ${navigator.userAgent}`)
  
  // Check if we're in mobile viewport
  const isMobile = window.innerWidth <= 768
  console.log(`Mobile viewport detected: ${isMobile ? '✅' : '❌'}`)
  
  // Check touch support
  const hasTouch = 'ontouchstart' in window
  console.log(`Touch support: ${hasTouch ? '✅' : '❌'}`)
}

// Test 5: Check integration with virtual scrolling
const testVirtualScrollIntegration = () => {
  console.log('\n🔄 Test 5: Virtual Scroll Integration')
  
  const container = document.querySelector('[data-controller*="virtual-scroll"]')
  if (container) {
    console.log('✅ Virtual scroll controller found')
    
    const spacer = container.querySelector('[data-virtual-scroll-target="spacer"]')
    const viewport = container.querySelector('[data-virtual-scroll-target="viewport"]')
    
    console.log(`Spacer element: ${spacer ? '✅' : '❌'}`)
    console.log(`Viewport element: ${viewport ? '✅' : '❌'}`)
    
    if (viewport) {
      const posts = viewport.querySelectorAll('[data-post-id]')
      console.log(`Posts with data-post-id: ${posts.length}`)
    }
  } else {
    console.log('❌ Virtual scroll controller not found')
  }
}

// Test 6: Performance check
const testPerformance = () => {
  console.log('\n⚡ Test 6: Performance Check')
  
  const start = performance.now()
  
  // Simulate multiple touch events quickly
  const container = document.querySelector('[data-controller*="pull-to-refresh"]')
  if (container) {
    for (let i = 0; i < 10; i++) {
      const touchEvent = new TouchEvent('touchmove', {
        touches: [{
          clientX: window.innerWidth / 2,
          clientY: 100 + i * 10
        }],
        bubbles: true,
        cancelable: true
      })
      container.dispatchEvent(touchEvent)
    }
  }
  
  const end = performance.now()
  console.log(`Touch event processing time: ${(end - start).toFixed(2)}ms`)
}

// Run all tests
const runAllTests = () => {
  console.log('🚀 Starting Pull-to-Refresh Tests')
  console.log('=====================================')
  
  testControllerLoading()
  testCSSStyles()
  testMobileViewport()
  testVirtualScrollIntegration()
  
  // Wait a bit before running touch simulation and performance tests
  setTimeout(() => {
    testTouchSimulation()
    setTimeout(() => {
      testPerformance()
      console.log('\n✅ All tests completed!')
      console.log('=====================================')
    }, 500)
  }, 1000)
}

// Auto-run tests when script loads
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', runAllTests)
} else {
  runAllTests()
}

// Export functions for manual testing
window.pullToRefreshTests = {
  runAll: runAllTests,
  controllerLoading: testControllerLoading,
  cssStyles: testCSSStyles,
  touchSimulation: testTouchSimulation,
  mobileViewport: testMobileViewport,
  virtualScrollIntegration: testVirtualScrollIntegration,
  performance: testPerformance
}

console.log('\n💡 Tip: You can run individual tests using:')
console.log('window.pullToRefreshTests.controllerLoading()')
console.log('window.pullToRefreshTests.touchSimulation()')
console.log('etc.')