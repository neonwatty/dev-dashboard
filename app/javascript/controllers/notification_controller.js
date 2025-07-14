import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="notification"
export default class extends Controller {
  static values = { delay: Number }
  
  connect() {
    // Default delay is 3 seconds
    const delay = this.hasDelayValue ? this.delayValue : 3000
    
    // Auto-dismiss after delay
    setTimeout(() => {
      this.dismiss()
    }, delay)
  }
  
  dismiss() {
    // Fade out animation
    this.element.style.transition = 'opacity 0.3s ease-out, transform 0.3s ease-out'
    this.element.style.opacity = '0'
    this.element.style.transform = 'translateX(20px)'
    
    // Remove element after animation
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}