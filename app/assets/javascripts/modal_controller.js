// Modal Controller for mobile-optimized modals
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["backdrop", "content"]
  static values = { backdropClose: Boolean }
  
  connect() {
    // Prevent body scroll when modal is open
    this.originalOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    
    // Focus trap setup
    this.setupFocusTrap()
    
    // ESC key listener
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.boundHandleKeydown)
  }
  
  disconnect() {
    // Restore body scroll
    document.body.style.overflow = this.originalOverflow
    
    // Remove event listeners
    document.removeEventListener('keydown', this.boundHandleKeydown)
  }
  
  close(event) {
    // Prevent closing if backdrop clicks are disabled and this is a backdrop click
    if (event && event.target === this.backdropTarget && !this.backdropCloseValue) {
      return
    }
    
    // Add closing animation
    this.contentTarget.style.animation = 'slideDown 0.3s ease-in'
    this.backdropTarget.style.opacity = '0'
    
    // Hide modal after animation
    setTimeout(() => {
      this.element.classList.add('hidden')
      
      // Dispatch close event
      this.dispatch('closed')
    }, 300)
  }
  
  show() {
    this.element.classList.remove('hidden')
    
    // Focus first focusable element
    setTimeout(() => {
      this.focusFirstElement()
    }, 100)
    
    // Dispatch show event
    this.dispatch('shown')
  }
  
  handleKeydown(event) {
    if (event.key === 'Escape') {
      this.close()
    }
    
    // Handle focus trap
    if (event.key === 'Tab') {
      this.handleTabKey(event)
    }
  }
  
  setupFocusTrap() {
    this.focusableElements = this.contentTarget.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    )
  }
  
  focusFirstElement() {
    if (this.focusableElements.length > 0) {
      this.focusableElements[0].focus()
    }
  }
  
  handleTabKey(event) {
    if (this.focusableElements.length === 0) return
    
    const firstElement = this.focusableElements[0]
    const lastElement = this.focusableElements[this.focusableElements.length - 1]
    
    if (event.shiftKey) {
      // Shift + Tab
      if (document.activeElement === firstElement) {
        lastElement.focus()
        event.preventDefault()
      }
    } else {
      // Tab
      if (document.activeElement === lastElement) {
        firstElement.focus()
        event.preventDefault()
      }
    }
  }
}

// Add slide down animation for mobile
const style = document.createElement('style')
style.textContent = `
  @keyframes slideDown {
    from {
      transform: translateY(0);
    }
    to {
      transform: translateY(100%);
    }
  }
`
document.head.appendChild(style)