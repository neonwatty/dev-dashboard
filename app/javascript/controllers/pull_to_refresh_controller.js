import { Controller } from "@hotwired/stimulus"
import HapticFeedback from "../utils/haptics"

export default class extends Controller {
  static targets = ["container", "indicator"]
  static values = { 
    threshold: { type: Number, default: 80 },
    url: String 
  }

  connect() {
    this.startY = 0
    this.currentY = 0
    this.isRefreshing = false
    this.isPulling = false
    
    // Create and add the refresh indicator first
    this.createRefreshIndicator()
    
    // Use the container or element for touch events
    const touchElement = this.hasContainerTarget ? this.containerTarget : this.element
    
    touchElement.addEventListener("touchstart", this.handleTouchStart.bind(this), { passive: true })
    touchElement.addEventListener("touchmove", this.handleTouchMove.bind(this), { passive: false })
    touchElement.addEventListener("touchend", this.handleTouchEnd.bind(this), { passive: true })
  }

  disconnect() {
    const touchElement = this.hasContainerTarget ? this.containerTarget : this.element
    
    touchElement.removeEventListener("touchstart", this.handleTouchStart.bind(this))
    touchElement.removeEventListener("touchmove", this.handleTouchMove.bind(this))
    touchElement.removeEventListener("touchend", this.handleTouchEnd.bind(this))
    
    if (this.indicatorElement) {
      this.indicatorElement.remove()
    }
  }

  handleTouchStart(e) {
    if (this.isRefreshing || window.scrollY > 0) return
    
    this.startY = e.touches[0].clientY
    this.currentY = this.startY
  }

  handleTouchMove(e) {
    if (this.isRefreshing || window.scrollY > 0) return
    
    this.currentY = e.touches[0].clientY
    const deltaY = this.currentY - this.startY
    
    if (deltaY > 0) {
      e.preventDefault()
      this.isPulling = true
      this.updatePullIndicator(deltaY)
    }
  }

  handleTouchEnd(e) {
    if (!this.isPulling || this.isRefreshing) return
    
    const deltaY = this.currentY - this.startY
    
    if (deltaY >= this.thresholdValue) {
      this.triggerRefresh()
    } else {
      this.resetPull()
    }
    
    this.isPulling = false
  }

  updatePullIndicator(deltaY) {
    const progress = Math.min(deltaY / this.thresholdValue, 1.5)
    const rotation = progress * 180
    const scale = 0.5 + (progress * 0.5)
    
    // Update indicator position and rotation
    this.indicatorElement.style.transform = `translateY(${Math.min(deltaY * 0.5, 100)}px) rotate(${rotation}deg) scale(${scale})`
    this.indicatorElement.style.opacity = Math.min(progress, 1)
    
    // Change indicator state at threshold
    if (progress >= 1) {
      this.indicatorElement.classList.add("ready")
      // Haptic feedback when ready
      if (!this.indicatorElement.dataset.vibrated) {
        HapticFeedback.light()
        this.indicatorElement.dataset.vibrated = "true"
      }
    } else {
      this.indicatorElement.classList.remove("ready")
      delete this.indicatorElement.dataset.vibrated
    }
  }

  triggerRefresh() {
    this.isRefreshing = true
    this.indicatorElement.classList.add("refreshing")
    
    // Show loading state
    this.showRefreshSpinner()
    
    // Get the URL - use current URL with Turbo Stream headers if no URL specified
    const refreshUrl = this.hasUrlValue ? this.urlValue : window.location.href
    
    // Trigger refresh
    fetch(refreshUrl, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
    .then(response => {
      if (!response.ok) throw new Error('Network response was not ok')
      return response.text()
    })
    .then(html => {
      // Handle Turbo Stream response
      if (window.Turbo) {
        Turbo.renderStreamMessage(html)
      }
      this.completeRefresh(true)
    })
    .catch(error => {
      console.error("Refresh failed:", error)
      this.completeRefresh(false)
    })
  }

  completeRefresh(success) {
    // Show success/error feedback
    if (success) {
      this.indicatorElement.classList.add("success")
      HapticFeedback.success()
    } else {
      this.indicatorElement.classList.add("error")
      HapticFeedback.error()
    }
    
    setTimeout(() => {
      this.isRefreshing = false
      this.resetPull()
      this.hideRefreshSpinner()
      this.indicatorElement.classList.remove("success", "error")
    }, 500)
  }

  resetPull() {
    this.indicatorElement.style.transform = "translateY(-60px)"
    this.indicatorElement.style.opacity = "0"
    this.indicatorElement.classList.remove("ready", "refreshing")
    delete this.indicatorElement.dataset.vibrated
  }

  showRefreshSpinner() {
    const icon = this.indicatorElement.querySelector(".refresh-icon")
    if (icon) {
      icon.innerHTML = `
        <svg class="animate-spin h-6 w-6" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
      `
    }
  }

  hideRefreshSpinner() {
    const icon = this.indicatorElement.querySelector(".refresh-icon")
    if (icon) {
      icon.innerHTML = `
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
        </svg>
      `
    }
  }

  createRefreshIndicator() {
    this.indicatorElement = document.createElement("div")
    this.indicatorElement.className = "pull-refresh-indicator"
    this.indicatorElement.innerHTML = `
      <div class="refresh-icon">
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
        </svg>
      </div>
      <div class="refresh-text">Pull to refresh</div>
    `
    
    // Create a container for the indicator if needed
    const container = this.element
    if (!container.style.position || container.style.position === 'static') {
      container.style.position = 'relative'
    }
    
    // Insert at the beginning of the element
    container.insertBefore(this.indicatorElement, container.firstChild)
    
    // Set as indicator target for convenience
    this.indicatorTarget = this.indicatorElement
    
    // Initial hidden state
    this.indicatorElement.style.transform = "translateY(-80px) scale(0.8)"
    this.indicatorElement.style.opacity = "0"
  }
  
  // Handle scroll events to detect normal scrolling vs pull gesture
  handleScroll(event) {
    if (this.isPulling) return
    
    // Clear any existing timeout
    if (this.scrollTimeout) {
      clearTimeout(this.scrollTimeout)
    }
    
    // Set flag to indicate normal scrolling
    this.isScrolling = true
    
    // Reset scrolling flag after scroll ends
    this.scrollTimeout = setTimeout(() => {
      this.isScrolling = false
    }, 150)
  }
  
  // Enable/disable pull to refresh programmatically
  enable() {
    this.enabledValue = true
    this.indicatorElement.style.display = ''
  }
  
  disable() {
    this.enabledValue = false
    this.resetPull()
    this.indicatorElement.style.display = 'none'
  }
  
  // Method to refresh programmatically
  refresh() {
    if (this.isRefreshing) return
    this.triggerRefresh()
  }
}