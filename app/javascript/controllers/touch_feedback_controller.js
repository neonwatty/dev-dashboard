import { Controller } from "@hotwired/stimulus"
import { addRippleEffect } from "../utils/ripple"
import HapticFeedback from "../utils/haptics"

export default class extends Controller {
  static values = { 
    haptic: { type: String, default: "light" },
    ripple: { type: Boolean, default: true }
  }

  connect() {
    // Add ripple effect if enabled
    if (this.rippleValue) {
      this.removeRipple = addRippleEffect(this.element)
    }
    
    // Add touch event listeners
    this.element.addEventListener("touchstart", this.handleTouchStart.bind(this))
    this.element.addEventListener("click", this.handleClick.bind(this))
  }

  disconnect() {
    // Clean up ripple effect
    if (this.removeRipple) {
      this.removeRipple()
    }
    
    // Remove event listeners
    this.element.removeEventListener("touchstart", this.handleTouchStart.bind(this))
    this.element.removeEventListener("click", this.handleClick.bind(this))
  }

  handleTouchStart(e) {
    // Add visual feedback class
    this.element.classList.add("touching")
    
    // Haptic feedback based on configuration
    switch (this.hapticValue) {
      case "heavy":
        HapticFeedback.heavy()
        break
      case "medium":
        HapticFeedback.medium()
        break
      case "light":
      default:
        HapticFeedback.light()
        break
    }
    
    // Remove visual feedback on touch end
    const handleTouchEnd = () => {
      this.element.classList.remove("touching")
      this.element.removeEventListener("touchend", handleTouchEnd)
      this.element.removeEventListener("touchcancel", handleTouchEnd)
    }
    
    this.element.addEventListener("touchend", handleTouchEnd)
    this.element.addEventListener("touchcancel", handleTouchEnd)
  }

  handleClick(e) {
    // Only provide haptic feedback on actual touch devices
    if ("ontouchstart" in window && e.isTrusted) {
      HapticFeedback.selection()
    }
  }
}