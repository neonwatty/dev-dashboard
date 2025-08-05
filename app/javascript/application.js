// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
console.log("🚀 application.js loaded!")

// Test direct Stimulus import
try {
  const { Application } = await import("@hotwired/stimulus")
  console.log("✅ Stimulus imported successfully:", Application)
  window.Stimulus = Application.start()
  console.log("✅ Stimulus application started:", window.Stimulus)
} catch (error) {
  console.error("❌ Failed to import Stimulus:", error)
}

import "@hotwired/turbo-rails"
console.log("📺 Turbo loaded!")
import "controllers"
console.log("🎮 Controllers import completed!")
