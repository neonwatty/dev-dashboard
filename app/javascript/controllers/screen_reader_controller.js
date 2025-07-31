import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="screen-reader"
export default class extends Controller {
  static targets = ["politeRegion", "assertiveRegion", "statusRegion"]
  
  connect() {
    // Listen for custom screen reader events
    document.addEventListener("screenreader:announce", this.handleAnnouncement.bind(this))
    document.addEventListener("screenreader:status", this.handleStatusUpdate.bind(this))
    document.addEventListener("screenreader:urgent", this.handleUrgentAnnouncement.bind(this))
    
    // Listen for Turbo events for automatic announcements
    document.addEventListener("turbo:frame-load", this.handleFrameLoad.bind(this))
    document.addEventListener("turbo:stream-render", this.handleStreamRender.bind(this))
    document.addEventListener("turbo:before-fetch-request", this.handleLoadingStart.bind(this))
    document.addEventListener("turbo:frame-render", this.handleLoadingComplete.bind(this))
    
    // Track form submissions for loading announcements
    document.addEventListener("turbo:submit-start", this.handleFormSubmitStart.bind(this))
    document.addEventListener("turbo:submit-end", this.handleFormSubmitEnd.bind(this))
    
    console.log("Screen reader controller connected")
  }
  
  disconnect() {
    document.removeEventListener("screenreader:announce", this.handleAnnouncement.bind(this))
    document.removeEventListener("screenreader:status", this.handleStatusUpdate.bind(this))
    document.removeEventListener("screenreader:urgent", this.handleUrgentAnnouncement.bind(this))
    document.removeEventListener("turbo:frame-load", this.handleFrameLoad.bind(this))
    document.removeEventListener("turbo:stream-render", this.handleStreamRender.bind(this))
    document.removeEventListener("turbo:before-fetch-request", this.handleLoadingStart.bind(this))
    document.removeEventListener("turbo:frame-render", this.handleLoadingComplete.bind(this))
    document.removeEventListener("turbo:submit-start", this.handleFormSubmitStart.bind(this))
    document.removeEventListener("turbo:submit-end", this.handleFormSubmitEnd.bind(this))
  }
  
  // Main announcement method for polite announcements
  announce(message, options = {}) {
    if (!message || typeof message !== 'string') return
    
    const {
      priority = 'polite',
      delay = 100,
      clear = true
    } = options
    
    const region = this.getRegionForPriority(priority)
    if (!region) return
    
    // Clear previous announcements if requested
    if (clear) {
      region.textContent = ''
    }
    
    // Small delay to ensure screen readers pick up the change
    setTimeout(() => {
      if (clear) {
        region.textContent = message
      } else {
        region.textContent = region.textContent + '. ' + message
      }
    }, delay)
    
    // Auto-clear after reasonable time to prevent accumulation
    if (clear) {
      setTimeout(() => {
        region.textContent = ''
      }, 10000) // Clear after 10 seconds
    }
  }
  
  // Status updates that don't interrupt current announcements
  announceStatus(message) {
    if (!this.hasStatusRegionTarget) return
    
    this.statusRegionTarget.textContent = message
    
    // Clear status after 5 seconds
    setTimeout(() => {
      this.statusRegionTarget.textContent = ''
    }, 5000)
  }
  
  // Urgent announcements that interrupt current speech
  announceUrgent(message) {
    this.announce(message, { priority: 'assertive', delay: 50 })
  }
  
  // Handle custom events
  handleAnnouncement(event) {
    const { message, options } = event.detail
    this.announce(message, options)
  }
  
  handleStatusUpdate(event) {
    const { message } = event.detail
    this.announceStatus(message)
  }
  
  handleUrgentAnnouncement(event) {
    const { message } = event.detail
    this.announceUrgent(message)
  }
  
  // Handle Turbo events for automatic announcements
  handleFrameLoad(event) {
    const frame = event.target
    const frameId = frame.id || 'content'
    
    // Don't announce every small frame load, focus on main content
    if (frameId.includes('main') || frameId.includes('content')) {
      this.announceStatus(`${this.getReadableFrameName(frameId)} loaded`)
    }
  }
  
  handleStreamRender(event) {
    const action = event.target.getAttribute('action') || 'updated'
    const targetId = event.target.getAttribute('target')
    
    // Announce stream updates based on action type
    switch (action) {
      case 'replace':
      case 'update':
        this.announceStatus(`Content updated`)
        break
      case 'append':
      case 'prepend':
        this.announceStatus(`New content added`)
        break
      case 'remove':
        this.announceStatus(`Content removed`)
        break
      default:
        this.announceStatus(`Content changed`)
    }
  }
  
  handleLoadingStart(event) {
    const url = event.detail.url
    const isFormSubmission = event.detail.requestMethod !== 'GET'
    
    if (isFormSubmission) {
      this.announceStatus('Processing request')
    } else {
      this.announceStatus('Loading')
    }
  }
  
  handleLoadingComplete(event) {
    this.announceStatus('Loading complete')
  }
  
  handleFormSubmitStart(event) {
    const form = event.target
    const action = this.getFormActionDescription(form)
    this.announceStatus(`Submitting ${action}`)
  }
  
  handleFormSubmitEnd(event) {
    const form = event.target
    const success = !event.detail.success === false
    
    if (success) {
      this.announceStatus('Form submitted successfully')
    } else {
      this.announceUrgent('Form submission failed. Please check for errors.')
    }
  }
  
  // Utility methods
  getRegionForPriority(priority) {
    switch (priority) {
      case 'assertive':
      case 'urgent':
        return this.hasAssertiveRegionTarget ? this.assertiveRegionTarget : null
      case 'status':
        return this.hasStatusRegionTarget ? this.statusRegionTarget : null
      case 'polite':
      default:
        return this.hasPoliteRegionTarget ? this.politeRegionTarget : null
    }
  }
  
  getReadableFrameName(frameId) {
    const nameMap = {
      'main-content': 'main content',
      'posts-list': 'posts list',
      'sources-list': 'sources list',
      'navigation': 'navigation',
      'sidebar': 'sidebar'
    }
    
    return nameMap[frameId] || frameId.replace(/-/g, ' ')
  }
  
  getFormActionDescription(form) {
    const action = form.action || ''
    const method = form.method || 'get'
    
    // Try to determine what kind of form this is
    if (action.includes('session')) {
      return method === 'delete' ? 'sign out' : 'sign in'
    } else if (action.includes('registration')) {
      return 'registration'
    } else if (action.includes('post')) {
      return 'post update'
    } else if (action.includes('source')) {
      return 'source update'
    } else {
      return 'form'
    }
  }
  
  // Form interaction handlers
  announceFormFieldChange(event) {
    const field = event.target
    const fieldName = field.name || field.id
    const value = field.value
    const displayValue = field.selectedOptions ? field.selectedOptions[0]?.text : value

    if (fieldName && value) {
      this.announceStatus(`${fieldName.replace(/[_\[\]]/g, ' ')} changed to ${displayValue}`)
    }
  }

  announceFormSubmit(event) {
    const form = event.target
    const action = this.getFormActionDescription(form)
    this.announceStatus(`Submitting ${action}`)
  }

  announceValidationError(event) {
    const field = event.target
    const fieldName = field.name || field.id
    
    if (field.validationMessage) {
      this.announceUrgent(`${fieldName.replace(/[_\[\]]/g, ' ')} error: ${field.validationMessage}`)
    }
  }

  announceDarkModeToggle(event) {
    const isDarkMode = document.documentElement.classList.contains('dark')
    const newMode = isDarkMode ? 'light' : 'dark'
    const button = event.target.closest('button')
    
    // Update aria-pressed state
    if (button) {
      button.setAttribute('aria-pressed', (!isDarkMode).toString())
    }
    
    // Announce the change
    this.announceStatus(`Switched to ${newMode} mode`)
  }

  // Static methods for use throughout the application
  static announce(message, options = {}) {
    document.dispatchEvent(new CustomEvent('screenreader:announce', {
      detail: { message, options }
    }))
  }
  
  static announceStatus(message) {
    document.dispatchEvent(new CustomEvent('screenreader:status', {
      detail: { message }
    }))
  }
  
  static announceUrgent(message) {
    document.dispatchEvent(new CustomEvent('screenreader:urgent', {
      detail: { message }
    }))
  }
}