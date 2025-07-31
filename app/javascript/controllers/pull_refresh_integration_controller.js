import { Controller } from "@hotwired/stimulus"

// Integration controller to coordinate pull-to-refresh with virtual scrolling
// This controller manages the interaction between the two systems
export default class extends Controller {
  static targets = []
  
  connect() {
    // Listen for pull-to-refresh events
    this.element.addEventListener('pull-to-refresh:refresh-started', this.handleRefreshStarted.bind(this))
    this.element.addEventListener('pull-to-refresh:refresh-completed', this.handleRefreshCompleted.bind(this))
    
    console.log('Pull-to-refresh integration controller connected')
  }
  
  disconnect() {
    this.element.removeEventListener('pull-to-refresh:refresh-started', this.handleRefreshStarted.bind(this))
    this.element.removeEventListener('pull-to-refresh:refresh-completed', this.handleRefreshCompleted.bind(this))
  }
  
  handleRefreshStarted(event) {
    console.log('Pull-to-refresh started, notifying virtual scroll controller')
    
    // Disable virtual scrolling during refresh to prevent conflicts
    const virtualScrollController = this.getVirtualScrollController()
    if (virtualScrollController) {
      virtualScrollController.loading = true
    }
  }
  
  handleRefreshCompleted(event) {
    const { success, error } = event.detail
    console.log('Pull-to-refresh completed:', { success, error })
    
    const virtualScrollController = this.getVirtualScrollController()
    if (virtualScrollController) {
      virtualScrollController.loading = false
      
      if (success) {
        // Re-initialize virtual scrolling with new content
        this.reinitializeVirtualScroll(virtualScrollController)
      }
    }
  }
  
  getVirtualScrollController() {
    // Find the virtual scroll controller on the same element
    const application = this.application
    if (application && application.getControllerForElementAndIdentifier) {
      return application.getControllerForElementAndIdentifier(this.element, 'virtual-scroll')
    }
    return null
  }
  
  reinitializeVirtualScroll(controller) {
    // Give time for DOM updates to complete
    setTimeout(() => {
      // Reinitialize items from the updated DOM
      controller.initializeItems()
      
      // Scroll to top to show new content
      const container = controller.containerTarget || controller.element
      container.scrollTo({ top: 0, behavior: 'smooth' })
      
      console.log('Virtual scroll reinitialized after refresh')
    }, 100)
  }
}