import { Controller } from "@hotwired/stimulus"
import HapticFeedback from "../utils/haptics"

export default class extends Controller {
  static targets = ["card"]
  static values = { 
    threshold: { type: Number, default: 100 },
    maxSwipe: { type: Number, default: 200 }
  }

  connect() {
    this.initialX = 0
    this.currentX = 0
    this.isDragging = false
    this.hasTriggered = false
    
    // Add touch event listeners
    this.cardTarget.addEventListener("touchstart", this.handleTouchStart.bind(this), { passive: true })
    this.cardTarget.addEventListener("touchmove", this.handleTouchMove.bind(this), { passive: false })
    this.cardTarget.addEventListener("touchend", this.handleTouchEnd.bind(this), { passive: true })
    
    // Add visual feedback elements
    this.setupSwipeIndicators()
  }

  disconnect() {
    // Clean up event listeners
    this.cardTarget.removeEventListener("touchstart", this.handleTouchStart.bind(this))
    this.cardTarget.removeEventListener("touchmove", this.handleTouchMove.bind(this))
    this.cardTarget.removeEventListener("touchend", this.handleTouchEnd.bind(this))
    
    // Clean up indicators
    if (this.leftIndicator) this.leftIndicator.remove()
    if (this.rightIndicator) this.rightIndicator.remove()
  }

  handleTouchStart(e) {
    if (e.touches.length !== 1) return
    
    this.initialX = e.touches[0].clientX
    this.currentX = this.initialX
    this.isDragging = true
    this.hasTriggered = false
    
    // Add dragging state
    this.cardTarget.classList.add("dragging")
    
    // Reset any previous transforms
    this.cardTarget.style.transition = "none"
  }

  handleTouchMove(e) {
    if (!this.isDragging || e.touches.length !== 1) return
    
    e.preventDefault()
    this.currentX = e.touches[0].clientX
    const deltaX = this.currentX - this.initialX
    
    // Constrain swipe distance
    const constrainedDelta = Math.sign(deltaX) * Math.min(Math.abs(deltaX), this.maxSwipeValue)
    
    // Update visual feedback
    this.updateSwipeVisuals(constrainedDelta)
    
    // Check for action triggers
    this.checkActionTriggers(constrainedDelta)
  }

  handleTouchEnd(e) {
    if (!this.isDragging) return
    
    const deltaX = this.currentX - this.initialX
    this.isDragging = false
    
    // Re-enable transitions
    this.cardTarget.style.transition = ""
    
    // Execute action if threshold met
    if (Math.abs(deltaX) >= this.thresholdValue && !this.hasTriggered) {
      this.executeSwipeAction(deltaX)
    } else {
      this.resetCard()
    }
    
    this.cardTarget.classList.remove("dragging")
  }

  updateSwipeVisuals(deltaX) {
    // Transform card
    this.cardTarget.style.transform = `translateX(${deltaX}px)`
    
    // Calculate progress
    const progress = Math.min(Math.abs(deltaX) / this.thresholdValue, 1)
    
    // Show/hide action indicators
    if (deltaX > 0) {
      // Swiping right - show "mark as read" 
      this.showLeftActions(progress)
      this.hideRightActions()
    } else if (deltaX < 0) {
      // Swiping left - show "clear/delete"
      this.showRightActions(progress)
      this.hideLeftActions()
    } else {
      this.hideLeftActions()
      this.hideRightActions()
    }
  }

  checkActionTriggers(deltaX) {
    const threshold = Math.abs(deltaX) >= this.thresholdValue
    
    if (threshold && !this.hasTriggered) {
      // Haptic feedback when threshold reached
      HapticFeedback.light()
      this.hasTriggered = true
    } else if (!threshold && this.hasTriggered) {
      this.hasTriggered = false
    }
  }

  showLeftActions(progress) {
    if (this.leftIndicator) {
      this.leftIndicator.style.opacity = progress
      this.leftIndicator.classList.toggle("active", progress >= 1)
    }
  }

  hideLeftActions() {
    if (this.leftIndicator) {
      this.leftIndicator.style.opacity = 0
      this.leftIndicator.classList.remove("active")
    }
  }

  showRightActions(progress) {
    if (this.rightIndicator) {
      this.rightIndicator.style.opacity = progress
      this.rightIndicator.classList.toggle("active", progress >= 1)
    }
  }

  hideRightActions() {
    if (this.rightIndicator) {
      this.rightIndicator.style.opacity = 0
      this.rightIndicator.classList.remove("active")
    }
  }

  executeSwipeAction(deltaX) {
    if (deltaX > 0) {
      this.markAsRead()
    } else {
      this.clearPost()
    }
  }

  markAsRead() {
    // Find the read button within the post actions controller
    const readButton = this.element.querySelector('[data-action*="post-actions#markAsRead"]')
    if (readButton) {
      this.animateSuccess("read")
      
      // Trigger click after animation starts
      setTimeout(() => {
        readButton.click()
      }, 150)
    }
  }

  clearPost() {
    // Find the clear button within the post actions controller
    const clearButton = this.element.querySelector('[data-action*="post-actions#clear"]')
    if (clearButton) {
      this.animateSuccess("cleared")
      
      // Trigger click after animation starts
      setTimeout(() => {
        clearButton.click()
      }, 150)
    }
  }

  animateSuccess(action) {
    // Add success animation
    this.cardTarget.classList.add(`swipe-${action}`)
    
    // Animate card out
    if (action === "read") {
      this.cardTarget.style.transform = `translateX(${this.maxSwipeValue}px)`
    } else {
      this.cardTarget.style.transform = `translateX(-${this.maxSwipeValue}px)`
    }
    
    // Fade out
    this.cardTarget.style.opacity = "0.3"
  }

  resetCard() {
    this.cardTarget.style.transform = ""
    this.hideLeftActions()
    this.hideRightActions()
    this.hasTriggered = false
  }

  setupSwipeIndicators() {
    // Create wrapper for swipe indicators if it doesn't exist
    const parent = this.cardTarget.parentNode
    
    // Check if we already have a wrapper
    let wrapper = parent.querySelector('.swipe-wrapper')
    if (!wrapper) {
      // Create wrapper
      wrapper = document.createElement('div')
      wrapper.className = 'swipe-wrapper'
      wrapper.style.position = 'relative'
      
      // Wrap the card
      parent.insertBefore(wrapper, this.cardTarget)
      wrapper.appendChild(this.cardTarget)
    }
    
    // Create left action indicator (mark as read)
    this.leftIndicator = document.createElement("div")
    this.leftIndicator.className = "swipe-indicator swipe-indicator-left"
    this.leftIndicator.innerHTML = `
      <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
      </svg>
      <span class="swipe-indicator-text">Mark as Read</span>
    `
    
    // Create right action indicator (clear)
    this.rightIndicator = document.createElement("div")
    this.rightIndicator.className = "swipe-indicator swipe-indicator-right"
    this.rightIndicator.innerHTML = `
      <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
      </svg>
      <span class="swipe-indicator-text">Clear</span>
    `
    
    // Insert indicators in the wrapper
    wrapper.insertBefore(this.leftIndicator, wrapper.firstChild)
    wrapper.appendChild(this.rightIndicator)
  }
}