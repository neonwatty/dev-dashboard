// Import and start Turbo Rails (includes Turbo Streams)
import "@hotwired/turbo-rails"

// Import and configure Stimulus
import { Application } from "@hotwired/stimulus"

const application = Application.start()
application.debug = true
window.Stimulus = application

// Import all controllers
import PostActionsController from "../controllers/post_actions_controller"
import NotificationController from "../controllers/notification_controller"
import SourceFiltersController from "../controllers/source_filters_controller"
import DarkModeController from "../controllers/dark_mode_controller"
import MobileMenuController from "../controllers/mobile_menu_controller"
import SwipeActionsController from "../controllers/swipe_actions_controller"
import PullToRefreshController from "../controllers/pull_to_refresh_controller"
import LongPressController from "../controllers/long_press_controller"
import TouchFeedbackController from "../controllers/touch_feedback_controller"

application.register("post-actions", PostActionsController)
application.register("notification", NotificationController)
application.register("source-filters", SourceFiltersController)
application.register("dark-mode", DarkModeController)
application.register("mobile-menu", MobileMenuController)
application.register("swipe-actions", SwipeActionsController)
application.register("pull-to-refresh", PullToRefreshController)
application.register("long-press", LongPressController)
application.register("touch-feedback", TouchFeedbackController)

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
