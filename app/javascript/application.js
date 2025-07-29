// Entry point for the build script in your package.json
console.log("🚀 application.js loaded!")

import "@hotwired/turbo-rails"
console.log("📺 Turbo loaded!")

// Import and start Stimulus controllers
import "./controllers/index"
console.log("🎮 Controllers import completed!")
