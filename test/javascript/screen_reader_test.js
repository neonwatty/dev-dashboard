/**
 * Screen Reader Controller Tests
 * 
 * Test suite for screen reader accessibility features.
 * These tests verify that ARIA live regions work correctly and
 * that announcements are made for dynamic content changes.
 */

import { Application } from "@hotwired/stimulus"
import ScreenReaderController from "../../app/javascript/controllers/screen_reader_controller"

// Mock DOM setup for testing
function setupMockDOM() {
  document.body.innerHTML = `
    <div data-controller="screen-reader">
      <div data-screen-reader-target="politeRegion" class="sr-only" aria-live="polite" aria-atomic="true"></div>
      <div data-screen-reader-target="assertiveRegion" class="sr-only" aria-live="assertive" aria-atomic="true"></div>
      <div data-screen-reader-target="statusRegion" class="sr-only" aria-live="polite" aria-atomic="false"></div>
    </div>
    
    <form id="test-form">
      <input type="text" name="test_field" id="test_field" value="test value">
      <select name="test_select" id="test_select">
        <option value="option1">Option 1</option>
        <option value="option2" selected>Option 2</option>
      </select>
      <button type="submit">Submit</button>
    </form>
    
    <button id="dark-mode-toggle" data-screen-reader-target="darkModeButton">Toggle Dark Mode</button>
  `
}

// Test Screen Reader Announcements
function testBasicAnnouncements() {
  console.log("🧪 Testing basic screen reader announcements...")
  
  const politeRegion = document.querySelector('[data-screen-reader-target="politeRegion"]')
  const assertiveRegion = document.querySelector('[data-screen-reader-target="assertiveRegion"]')
  const statusRegion = document.querySelector('[data-screen-reader-target="statusRegion"]')
  
  // Test polite announcement
  ScreenReaderController.announce("This is a polite announcement")
  
  setTimeout(() => {
    if (politeRegion.textContent.includes("polite announcement")) {
      console.log("✅ Polite announcement working")
    } else {
      console.log("❌ Polite announcement failed")
    }
  }, 200)
  
  // Test urgent announcement
  ScreenReaderController.announceUrgent("This is urgent!")
  
  setTimeout(() => {
    if (assertiveRegion.textContent.includes("urgent")) {
      console.log("✅ Urgent announcement working")
    } else {
      console.log("❌ Urgent announcement failed")
    }
  }, 200)
  
  // Test status announcement
  ScreenReaderController.announceStatus("Status update")
  
  setTimeout(() => {
    if (statusRegion.textContent.includes("Status update")) {
      console.log("✅ Status announcement working")
    } else {
      console.log("❌ Status announcement failed")
    }
  }, 200)
}

// Test Form Interactions
function testFormInteractions() {
  console.log("🧪 Testing form interaction announcements...")
  
  const statusRegion = document.querySelector('[data-screen-reader-target="statusRegion"]')
  const textField = document.getElementById('test_field')
  const selectField = document.getElementById('test_select')
  
  // Simulate form field change
  textField.value = "new value"
  textField.dispatchEvent(new Event('change', { bubbles: true }))
  
  // Check if change was announced
  setTimeout(() => {
    if (statusRegion.textContent.includes("test field changed")) {
      console.log("✅ Form field change announcement working")
    } else {
      console.log("❌ Form field change announcement failed")
    }
  }, 200)
  
  // Simulate select change
  selectField.value = "option1"
  selectField.dispatchEvent(new Event('change', { bubbles: true }))
  
  setTimeout(() => {
    if (statusRegion.textContent.includes("test select changed")) {
      console.log("✅ Select field change announcement working")
    } else {
      console.log("❌ Select field change announcement failed")
    }
  }, 300)
}

// Test Turbo Event Handling
function testTurboEventHandling() {
  console.log("🧪 Testing Turbo event handling...")
  
  const statusRegion = document.querySelector('[data-screen-reader-target="statusRegion"]')
  
  // Simulate turbo:submit-start
  document.dispatchEvent(new CustomEvent('turbo:submit-start', {
    detail: { formSubmission: { submitter: { form: document.getElementById('test-form') } } }
  }))
  
  setTimeout(() => {
    if (statusRegion.textContent.includes("Submitting")) {
      console.log("✅ Turbo submit start announcement working")
    } else {
      console.log("❌ Turbo submit start announcement failed")
    }
  }, 200)
  
  // Simulate turbo:submit-end
  document.dispatchEvent(new CustomEvent('turbo:submit-end', {
    detail: { success: true }
  }))
  
  setTimeout(() => {
    if (statusRegion.textContent.includes("successfully")) {
      console.log("✅ Turbo submit end announcement working")
    } else {
      console.log("❌ Turbo submit end announcement failed")
    }
  }, 300)
}

// Test Loading States
function testLoadingStates() {
  console.log("🧪 Testing loading state announcements...")
  
  const statusRegion = document.querySelector('[data-screen-reader-target="statusRegion"]')
  
  // Simulate loading start
  document.dispatchEvent(new CustomEvent('turbo:before-fetch-request', {
    detail: { url: '/test', requestMethod: 'GET' }
  }))
  
  setTimeout(() => {
    if (statusRegion.textContent.includes("Loading")) {
      console.log("✅ Loading start announcement working")
    } else {
      console.log("❌ Loading start announcement failed")
    }
  }, 200)
  
  // Simulate loading complete
  document.dispatchEvent(new CustomEvent('turbo:frame-render', {}))
  
  setTimeout(() => {
    if (statusRegion.textContent.includes("complete")) {
      console.log("✅ Loading complete announcement working")
    } else {
      console.log("❌ Loading complete announcement failed")
    }
  }, 300)
}

// Test Dark Mode Toggle
function testDarkModeToggle() {
  console.log("🧪 Testing dark mode toggle announcement...")
  
  const statusRegion = document.querySelector('[data-screen-reader-target="statusRegion"]')
  const darkModeButton = document.getElementById('dark-mode-toggle')
  
  // Simulate dark mode toggle
  document.documentElement.classList.add('dark')
  darkModeButton.dispatchEvent(new Event('click', { bubbles: true }))
  
  setTimeout(() => {
    if (statusRegion.textContent.includes("light mode")) {
      console.log("✅ Dark mode toggle announcement working")
    } else {
      console.log("❌ Dark mode toggle announcement failed")
    }
  }, 200)
}

// Test Auto-clearing of Announcements
function testAnnouncementClearing() {
  console.log("🧪 Testing announcement auto-clearing...")
  
  const politeRegion = document.querySelector('[data-screen-reader-target="politeRegion"]')
  
  // Make an announcement
  ScreenReaderController.announce("This should be cleared", { delay: 100 })
  
  // Check it's there initially
  setTimeout(() => {
    if (politeRegion.textContent.includes("cleared")) {
      console.log("✅ Announcement initially present")
      
      // Check it gets cleared
      setTimeout(() => {
        if (politeRegion.textContent === "") {
          console.log("✅ Announcement auto-clearing working")
        } else {
          console.log("❌ Announcement auto-clearing failed")
        }
      }, 10500) // Wait for 10 second auto-clear
    } else {
      console.log("❌ Announcement not initially present")
    }
  }, 200)
}

// Run all tests
function runScreenReaderTests() {
  console.log("🧪 Starting Screen Reader Tests...")
  
  // Setup mock DOM
  setupMockDOM()
  
  // Initialize Stimulus application
  const application = Application.start()
  application.register("screen-reader", ScreenReaderController)
  
  // Wait for controller to connect
  setTimeout(() => {
    testBasicAnnouncements()
    
    setTimeout(() => {
      testFormInteractions()
    }, 1000)
    
    setTimeout(() => {
      testTurboEventHandling()
    }, 2000)
    
    setTimeout(() => {
      testLoadingStates()
    }, 3000)
    
    setTimeout(() => {
      testDarkModeToggle()
    }, 4000)
    
    setTimeout(() => {
      testAnnouncementClearing()
    }, 5000)
    
    setTimeout(() => {
      console.log("🧪 Screen Reader Tests Complete!")
    }, 16000)
  }, 500)
}

// Export for use in test suites
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    runScreenReaderTests,
    testBasicAnnouncements,
    testFormInteractions,
    testTurboEventHandling,
    testLoadingStates,
    testDarkModeToggle,
    testAnnouncementClearing
  }
} else {
  // Run tests if loaded directly in browser
  if (typeof window !== 'undefined') {
    window.screenReaderTests = {
      runAll: runScreenReaderTests,
      basic: testBasicAnnouncements,
      forms: testFormInteractions,
      turbo: testTurboEventHandling,
      loading: testLoadingStates,
      darkMode: testDarkModeToggle,
      clearing: testAnnouncementClearing
    }
    
    console.log("Screen Reader Tests loaded. Run with:")
    console.log("- screenReaderTests.runAll() - Run all tests")
    console.log("- screenReaderTests.basic() - Test basic announcements")
    console.log("- screenReaderTests.forms() - Test form interactions")
    console.log("- screenReaderTests.turbo() - Test Turbo events")
    console.log("- screenReaderTests.loading() - Test loading states")
    console.log("- screenReaderTests.darkMode() - Test dark mode toggle")
    console.log("- screenReaderTests.clearing() - Test auto-clearing")
  }
}