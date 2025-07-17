import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("🌙 DarkModeController connected to element:", this.element)
    
    // Check for saved theme preference or default to 'light'
    const theme = localStorage.getItem('theme') || 'light'
    console.log("🎨 Current theme from localStorage:", theme)
    
    this.applyTheme(theme)
  }

  toggle() {
    console.log("🔄 Dark mode toggle clicked!")
    
    const currentTheme = localStorage.getItem('theme') || 'light'
    const newTheme = currentTheme === 'light' ? 'dark' : 'light'
    
    console.log("🎨 Switching theme from", currentTheme, "to", newTheme)
    
    this.applyTheme(newTheme)
    localStorage.setItem('theme', newTheme)
    
    console.log("✅ Theme saved to localStorage:", newTheme)
  }

  applyTheme(theme) {
    console.log("🎨 Applying theme:", theme)
    
    if (theme === 'dark') {
      document.documentElement.classList.add('dark')
      document.body.classList.add('dark')
      console.log("🌙 Dark mode classes added")
    } else {
      document.documentElement.classList.remove('dark')
      document.body.classList.remove('dark')
      console.log("☀️ Light mode classes removed")
    }
    
    console.log("📱 Current HTML classes:", document.documentElement.classList.toString())
  }
}