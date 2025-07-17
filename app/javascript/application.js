// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
console.log("🚀 application.js loaded!")

import "@hotwired/turbo-rails"
console.log("📺 Turbo loaded!")

// Import controllers which will handle Stimulus setup
import "controllers"
console.log("🎮 Controllers import completed!")
