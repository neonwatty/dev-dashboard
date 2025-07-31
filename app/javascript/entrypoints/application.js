// Import and start Turbo Rails (includes Turbo Streams)
import "@hotwired/turbo-rails"

// Import and configure Stimulus
import { Application } from "@hotwired/stimulus"

const application = Application.start()
application.debug = process.env.NODE_ENV === 'development'
window.Stimulus = application

// Import critical controllers immediately (needed for initial page load)
import NotificationController from "../controllers/notification_controller"
import DarkModeController from "../controllers/dark_mode_controller"
import ScreenReaderController from "../controllers/screen_reader_controller"

// Register critical controllers
application.register("notification", NotificationController)
application.register("dark-mode", DarkModeController)
application.register("screen-reader", ScreenReaderController)

// Lazy load controller groups based on feature detection and usage
const lazyLoadControllers = {
  // Mobile controllers - load when touch is detected or mobile viewport
  mobile: () => import("../controllers/mobile_controllers.js"),
  // Post management controllers - load when post elements are present
  posts: () => import("../controllers/post_controllers.js"),
  // UI enhancement controllers - load after initial render
  ui: () => import("../controllers/ui_controllers.js")
}

// Function to register controllers from lazy-loaded modules
async function registerControllers(controllerModule, controllers) {
  for (const [name, controller] of Object.entries(controllers)) {
    application.register(name, controller.default || controller)
  }
}

// Load mobile controllers if needed
function loadMobileControllers() {
  if (window.innerWidth <= 768 || 'ontouchstart' in window) {
    lazyLoadControllers.mobile().then(module => {
      registerControllers(module, {
        'mobile-menu': module.MobileMenuController,
        'swipe-actions': module.SwipeActionsController,
        'pull-to-refresh': module.PullToRefreshController,
        'long-press': module.LongPressController,
        'touch-feedback': module.TouchFeedbackController
      })
    })
  }
}

// Load post controllers if post elements exist
function loadPostControllers() {
  if (document.querySelector('[data-controller*="post"]') || 
      document.querySelector('.post-item, .post-card')) {
    lazyLoadControllers.posts().then(module => {
      registerControllers(module, {
        'post-actions': module.PostActionsController,
        'virtual-scroll': module.VirtualScrollController
      })
    })
  }
}

// Load UI enhancement controllers after initial render
function loadUIControllers() {
  requestIdleCallback(() => {
    lazyLoadControllers.ui().then(module => {
      registerControllers(module, {
        'source-filters': module.SourceFiltersController
      })
    })
  }, { timeout: 2000 })
}

// Load controllers based on conditions
document.addEventListener('DOMContentLoaded', () => {
  loadMobileControllers()
  loadPostControllers()
  loadUIControllers()
})

// Also check on Turbo navigation
document.addEventListener('turbo:load', () => {
  loadPostControllers()
})

console.log('✅ Dev Dashboard loaded with Turbo and Stimulus')

// Debug Turbo Stream events
document.addEventListener('turbo:before-stream-render', (event) => {
  const stream = event.detail.newStream
  console.log('Turbo Stream received:', {
    action: stream.action,
    target: stream.target,
    content: stream.querySelector('template')?.innerHTML?.substring(0, 100) + '...'
  })
})
