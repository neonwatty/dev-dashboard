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

application.register("post-actions", PostActionsController)
application.register("notification", NotificationController)
application.register("source-filters", SourceFiltersController)

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
