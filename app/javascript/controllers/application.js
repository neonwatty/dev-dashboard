import { Application } from "@hotwired/stimulus"

console.log("📌 Creating Stimulus application...")
const application = Application.start()

// Configure Stimulus development experience
application.debug = true
window.Stimulus = application  // window.Stimulus IS the application

console.log("📌 Stimulus application created and started")

export { application }
