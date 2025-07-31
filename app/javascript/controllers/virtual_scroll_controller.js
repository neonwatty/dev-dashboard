import { Controller } from "@hotwired/stimulus"

// Virtual scrolling controller for optimized post list rendering
// Renders only visible posts plus buffer to improve performance with large datasets
export default class extends Controller {
  static targets = ["container", "viewport", "spacer", "loadingIndicator"]
  static values = { 
    itemHeight: { type: Number, default: 250 }, // Estimated post card height
    bufferSize: { type: Number, default: 5 },   // Number of items to render above/below viewport
    threshold: { type: Number, default: 50 },   // Threshold for enabling virtual scrolling
    totalItems: { type: Number, default: 0 },
    page: { type: Number, default: 1 },
    hasMore: { type: Boolean, default: true }
  }
  
  connect() {
    this.items = []
    this.renderedItems = new Map() // Track rendered items for efficient updates
    this.isScrolling = false
    this.scrollTimeout = null
    this.lastScrollTop = 0
    this.resizeObserver = null
    
    // Bind methods for event listeners
    this.handleScroll = this.handleScroll.bind(this)
    this.handleResize = this.handleResize.bind(this)
    this.handleKeyDown = this.handleKeyDown.bind(this)
    this.handleTurboStreamUpdate = this.handleTurboStreamUpdate.bind(this)
    this.handleTurboStreamRemove = this.handleTurboStreamRemove.bind(this)
    
    // Set up event listeners
    this.containerTarget.addEventListener('scroll', this.handleScroll, { passive: true })
    window.addEventListener('resize', this.handleResize)
    document.addEventListener('keydown', this.handleKeyDown)
    
    // Listen for Turbo Stream events
    document.addEventListener('virtual-scroll:update-item', this.handleTurboStreamUpdate)
    document.addEventListener('virtual-scroll:remove-item', this.handleTurboStreamRemove)
    
    // Set up ResizeObserver for dynamic height adjustments
    if (window.ResizeObserver) {
      this.resizeObserver = new ResizeObserver(this.handleItemResize.bind(this))
    }
    
    // Initialize if we have items
    this.initializeItems()
    
    console.log('Virtual scroll controller connected', {
      threshold: this.thresholdValue,
      itemHeight: this.itemHeightValue,
      bufferSize: this.bufferSizeValue
    })
  }
  
  disconnect() {
    this.containerTarget.removeEventListener('scroll', this.handleScroll)
    window.removeEventListener('resize', this.handleResize)
    document.removeEventListener('keydown', this.handleKeyDown)
    
    // Remove Turbo Stream event listeners
    document.removeEventListener('virtual-scroll:update-item', this.handleTurboStreamUpdate)
    document.removeEventListener('virtual-scroll:remove-item', this.handleTurboStreamRemove)
    
    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
    }
    
    if (this.scrollTimeout) {
      clearTimeout(this.scrollTimeout)
    }
  }
  
  // Initialize items from existing DOM elements
  initializeItems() {
    const existingItems = this.viewportTarget.querySelectorAll('[data-post-id]')
    this.items = Array.from(existingItems).map((element, index) => ({
      id: element.dataset.postId,
      element: element,
      height: this.itemHeightValue, // Will be measured later
      top: index * this.itemHeightValue,
      visible: true,
      index: index
    }))
    
    this.totalItemsValue = this.items.length
    
    // Only enable virtual scrolling if we have enough items
    if (this.shouldUseVirtualScrolling()) {
      this.enableVirtualScrolling()
    } else {
      this.disableVirtualScrolling()
    }
  }
  
  shouldUseVirtualScrolling() {
    return this.totalItemsValue >= this.thresholdValue
  }
  
  enableVirtualScrolling() {
    console.log('Enabling virtual scrolling for', this.totalItemsValue, 'items')
    
    // Measure actual item heights
    this.measureItemHeights()
    
    // Set up virtual scrolling structure
    this.setupVirtualScrolling()
    
    // Initial render
    this.updateVisibleItems()
    
    // Update accessibility attributes
    this.updateAccessibilityAttributes()
  }
  
  disableVirtualScrolling() {
    console.log('Virtual scrolling disabled - not enough items')
    // Ensure all items are visible for small lists
    this.items.forEach(item => {
      if (item.element && !item.element.parentNode) {
        this.viewportTarget.appendChild(item.element)
      }
    })
  }
  
  measureItemHeights() {
    this.items.forEach((item, index) => {
      if (item.element) {
        const rect = item.element.getBoundingClientRect()
        item.height = rect.height || this.itemHeightValue
        item.top = index === 0 ? 0 : this.items[index - 1].top + this.items[index - 1].height
        
        // Observe height changes
        if (this.resizeObserver) {
          this.resizeObserver.observe(item.element)
        }
      }
    })
    
    // Calculate total height
    this.totalHeight = this.items.length > 0 ? 
      this.items[this.items.length - 1].top + this.items[this.items.length - 1].height : 0
  }
  
  setupVirtualScrolling() {
    // Set container height to enable scrolling
    this.spacerTarget.style.height = `${this.totalHeight}px`
    
    // Position viewport absolutely for precise control
    this.viewportTarget.style.position = 'relative'
    this.viewportTarget.style.transform = 'translateY(0px)'
    
    // Clear current items from viewport
    this.viewportTarget.innerHTML = ''
    this.renderedItems.clear()
  }
  
  handleScroll(event) {
    if (!this.shouldUseVirtualScrolling()) return
    
    // Throttle scroll events for performance
    if (!this.isScrolling) {
      requestAnimationFrame(() => {
        this.updateVisibleItems()
        this.isScrolling = false
      })
    }
    this.isScrolling = true
    
    // Clear scroll timeout
    if (this.scrollTimeout) {
      clearTimeout(this.scrollTimeout)
    }
    
    // Set scroll end timeout for final updates
    this.scrollTimeout = setTimeout(() => {
      this.updateVisibleItems()
      this.announceScrollPosition() // For accessibility
    }, 150)
    
    // Check if we need to load more items
    this.checkLoadMore()
  }
  
  updateVisibleItems() {
    if (!this.shouldUseVirtualScrolling()) return
    
    const scrollTop = this.containerTarget.scrollTop
    const containerHeight = this.containerTarget.clientHeight
    
    // Calculate visible range with buffer
    const startIndex = this.findStartIndex(scrollTop)
    const endIndex = this.findEndIndex(scrollTop + containerHeight)
    
    const bufferStart = Math.max(0, startIndex - this.bufferSizeValue)
    const bufferEnd = Math.min(this.items.length - 1, endIndex + this.bufferSizeValue)
    
    // Remove items outside buffer range
    this.renderedItems.forEach((element, itemId) => {
      const item = this.items.find(i => i.id === itemId)
      if (!item || item.index < bufferStart || item.index > bufferEnd) {
        if (element.parentNode) {
          element.parentNode.removeChild(element)
        }
        this.renderedItems.delete(itemId)
      }
    })
    
    // Add items within buffer range
    for (let i = bufferStart; i <= bufferEnd; i++) {
      const item = this.items[i]
      if (item && !this.renderedItems.has(item.id)) {
        this.renderItem(item)
      }
    }
    
    // Update viewport transform
    const offsetY = bufferStart > 0 ? this.items[bufferStart].top : 0
    this.viewportTarget.style.transform = `translateY(${offsetY}px)`
    
    // Update spacer height if needed
    if (this.totalHeight !== parseFloat(this.spacerTarget.style.height)) {
      this.spacerTarget.style.height = `${this.totalHeight}px`
    }
  }
  
  findStartIndex(scrollTop) {
    // Binary search for performance
    let left = 0
    let right = this.items.length - 1
    
    while (left < right) {
      const mid = Math.floor((left + right) / 2)
      if (this.items[mid].top < scrollTop) {
        left = mid + 1
      } else {
        right = mid
      }
    }
    
    return Math.max(0, left - 1)
  }
  
  findEndIndex(scrollBottom) {
    // Binary search for performance
    let left = 0
    let right = this.items.length - 1
    
    while (left < right) {
      const mid = Math.floor((left + right + 1) / 2)
      if (this.items[mid].top <= scrollBottom) {
        left = mid
      } else {
        right = mid - 1
      }
    }
    
    return Math.min(this.items.length - 1, left + 1)
  }
  
  renderItem(item) {
    if (!item.element) return
    
    // Clone element if it's already rendered elsewhere
    const element = item.element.cloneNode(true)
    
    // Ensure all controllers are reconnected
    if (window.Stimulus) {
      // Re-initialize Stimulus controllers on cloned element
      window.Stimulus.application.start(element)
    }
    
    this.viewportTarget.appendChild(element)
    this.renderedItems.set(item.id, element)
  }
  
  handleResize() {
    if (!this.shouldUseVirtualScrolling()) return
    
    // Debounce resize events
    clearTimeout(this.resizeTimeout)
    this.resizeTimeout = setTimeout(() => {
      this.measureItemHeights()
      this.updateVisibleItems()
    }, 250)
  }
  
  handleItemResize(entries) {
    let needsUpdate = false
    
    entries.forEach(entry => {
      const element = entry.target
      const postId = element.dataset.postId
      const item = this.items.find(i => i.id === postId)
      
      if (item) {
        const newHeight = entry.contentRect.height
        if (Math.abs(item.height - newHeight) > 1) { // Only update if significant change
          item.height = newHeight
          needsUpdate = true
        }
      }
    })
    
    if (needsUpdate) {
      this.recalculatePositions()
      this.updateVisibleItems()
    }
  }
  
  recalculatePositions() {
    let currentTop = 0
    this.items.forEach(item => {
      item.top = currentTop
      currentTop += item.height
    })
    this.totalHeight = currentTop
  }
  
  // Handle keyboard navigation
  handleKeyDown(event) {
    if (!this.shouldUseVirtualScrolling()) return
    
    const container = this.containerTarget
    if (document.activeElement === container || container.contains(document.activeElement)) {
      switch (event.key) {
        case 'ArrowDown':
          event.preventDefault()
          this.scrollToNextItem()
          break
        case 'ArrowUp':
          event.preventDefault()
          this.scrollToPreviousItem()
          break
        case 'PageDown':
          event.preventDefault()
          this.scrollByPage(1)
          break
        case 'PageUp':
          event.preventDefault()
          this.scrollByPage(-1)
          break
        case 'Home':
          event.preventDefault()
          this.scrollToTop()
          break
        case 'End':
          event.preventDefault()
          this.scrollToBottom()
          break
      }
    }
  }
  
  scrollToNextItem() {
    const currentScroll = this.containerTarget.scrollTop
    const nextItem = this.items.find(item => item.top > currentScroll)
    if (nextItem) {
      this.containerTarget.scrollTo({ top: nextItem.top, behavior: 'smooth' })
    }
  }
  
  scrollToPreviousItem() {
    const currentScroll = this.containerTarget.scrollTop
    const prevItem = [...this.items].reverse().find(item => item.top < currentScroll - 10)
    if (prevItem) {
      this.containerTarget.scrollTo({ top: prevItem.top, behavior: 'smooth' })
    }
  }
  
  scrollByPage(direction) {
    const containerHeight = this.containerTarget.clientHeight
    const currentScroll = this.containerTarget.scrollTop
    const newScroll = currentScroll + (direction * containerHeight * 0.8) // 80% of viewport
    
    this.containerTarget.scrollTo({ top: newScroll, behavior: 'smooth' })
  }
  
  scrollToTop() {
    this.containerTarget.scrollTo({ top: 0, behavior: 'smooth' })
  }
  
  scrollToBottom() {
    this.containerTarget.scrollTo({ top: this.totalHeight, behavior: 'smooth' })
  }
  
  // Accessibility support
  updateAccessibilityAttributes() {
    const container = this.containerTarget
    container.setAttribute('role', 'list')
    container.setAttribute('aria-label', `Posts list with ${this.totalItemsValue} items`)
    container.setAttribute('tabindex', '0')
    
    // Add aria-live region for scroll announcements
    if (!this.ariaLiveRegion) {
      this.ariaLiveRegion = document.createElement('div')
      this.ariaLiveRegion.setAttribute('aria-live', 'polite')
      this.ariaLiveRegion.setAttribute('aria-atomic', 'true')
      this.ariaLiveRegion.className = 'sr-only'
      document.body.appendChild(this.ariaLiveRegion)
    }
  }
  
  announceScrollPosition() {
    if (!this.ariaLiveRegion) return
    
    const scrollTop = this.containerTarget.scrollTop
    const currentIndex = this.findStartIndex(scrollTop) + 1
    const message = `Showing posts ${currentIndex} to ${Math.min(currentIndex + 10, this.totalItemsValue)} of ${this.totalItemsValue}`
    
    // Debounce announcements
    clearTimeout(this.announceTimeout)
    this.announceTimeout = setTimeout(() => {
      this.ariaLiveRegion.textContent = message
    }, 1000)
  }
  
  // Handle dynamic updates from Turbo Streams
  addItem(element) {
    const postId = element.dataset.postId
    if (!postId) return
    
    const newItem = {
      id: postId,
      element: element,
      height: this.itemHeightValue,
      top: 0, // Will be recalculated
      visible: true,
      index: this.items.length
    }
    
    this.items.unshift(newItem) // Add to beginning for newest posts
    this.totalItemsValue = this.items.length
    
    // Recalculate positions
    this.recalculatePositions()
    
    // Re-enable virtual scrolling if threshold is met
    if (this.shouldUseVirtualScrolling() && this.items.length === this.thresholdValue) {
      this.enableVirtualScrolling()
    } else if (this.shouldUseVirtualScrolling()) {
      this.updateVisibleItems()
    }
    
    // Update accessibility
    this.updateAccessibilityAttributes()
  }
  
  removeItem(postId) {
    const itemIndex = this.items.findIndex(item => item.id === postId)
    if (itemIndex === -1) return
    
    // Remove from rendered items
    if (this.renderedItems.has(postId)) {
      const element = this.renderedItems.get(postId)
      if (element.parentNode) {
        element.parentNode.removeChild(element)
      }
      this.renderedItems.delete(postId)
    }
    
    // Remove from items array
    this.items.splice(itemIndex, 1)
    this.totalItemsValue = this.items.length
    
    // Update indices
    this.items.forEach((item, index) => {
      item.index = index
    })
    
    // Recalculate positions
    this.recalculatePositions()
    
    // Update virtual scrolling state
    if (!this.shouldUseVirtualScrolling()) {
      this.disableVirtualScrolling()
    } else {
      this.updateVisibleItems()
    }
    
    // Update accessibility
    this.updateAccessibilityAttributes()
  }
  
  updateItem(element) {
    const postId = element.dataset.postId
    if (!postId) return
    
    const item = this.items.find(item => item.id === postId)
    if (item) {
      item.element = element
      
      // Update rendered element if currently visible
      if (this.renderedItems.has(postId)) {
        const renderedElement = this.renderedItems.get(postId)
        renderedElement.replaceWith(element.cloneNode(true))
        this.renderedItems.set(postId, element)
      }
      
      // Remeasure height if needed
      if (this.shouldUseVirtualScrolling()) {
        this.measureItemHeights()
        this.updateVisibleItems()
      }
    }
  }
  
  // Check if we need to load more items (infinite scroll)
  checkLoadMore() {
    if (!this.hasMoreValue) return
    
    const scrollTop = this.containerTarget.scrollTop
    const scrollHeight = this.containerTarget.scrollHeight
    const clientHeight = this.containerTarget.clientHeight
    
    // Trigger load more when 80% scrolled
    if (scrollTop + clientHeight >= scrollHeight * 0.8) {
      this.loadMore()
    }
  }
  
  async loadMore() {
    if (!this.hasMoreValue || this.loading) return
    
    this.loading = true
    
    if (this.loadingIndicatorTarget) {
      this.loadingIndicatorTarget.style.display = 'block'
    }
    
    try {
      const nextPage = this.pageValue + 1
      const currentUrl = new URL(window.location)
      currentUrl.searchParams.set('page', nextPage)
      currentUrl.searchParams.set('format', 'json')
      
      const response = await fetch(currentUrl.toString(), {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      const data = await response.json()
      
      // Process new posts
      if (data.posts && data.posts.length > 0) {
        data.posts.forEach(postData => {
          // Create DOM element from HTML string
          const tempContainer = document.createElement('div')
          tempContainer.innerHTML = postData.html
          const postElement = tempContainer.firstElementChild
          
          if (postElement) {
            postElement.dataset.postId = postData.id
            this.addItemFromHTML(postElement)
          }
        })
        
        this.pageValue = data.current_page
        this.hasMoreValue = data.has_more
        this.totalItemsValue = data.total_count
        
        console.log('Loaded', data.posts.length, 'more posts. Total:', this.totalItemsValue)
      } else {
        this.hasMoreValue = false
      }
      
    } catch (error) {
      console.error('Error loading more posts:', error)
      // Show error state
      this.showLoadError()
    } finally {
      this.loading = false
      if (this.loadingIndicatorTarget) {
        this.loadingIndicatorTarget.style.display = 'none'
      }
    }
  }
  
  // Add item from HTML string (for infinite loading)
  addItemFromHTML(element) {
    const postId = element.dataset.postId
    if (!postId) return
    
    const newItem = {
      id: postId,
      element: element,
      height: this.itemHeightValue,
      top: 0, // Will be recalculated
      visible: true,
      index: this.items.length
    }
    
    this.items.push(newItem) // Add to end for infinite scroll
    
    // Recalculate positions
    this.recalculatePositions()
    
    // Re-enable virtual scrolling if threshold is met
    if (this.shouldUseVirtualScrolling() && this.items.length === this.thresholdValue) {
      this.enableVirtualScrolling()
    } else if (this.shouldUseVirtualScrolling()) {
      this.updateVisibleItems()
    }
    
    // Update accessibility
    this.updateAccessibilityAttributes()
  }
  
  // Show load error state
  showLoadError() {
    if (this.loadingIndicatorTarget) {
      this.loadingIndicatorTarget.innerHTML = `
        <div class="flex items-center justify-center space-x-2 text-red-500">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          <span class="text-sm">Failed to load more posts</span>
          <button class="text-sm underline ml-2" onclick="this.closest('[data-controller*=virtual-scroll]').virtualScrollController.loadMore()">
            Retry
          </button>
        </div>
      `
      
      // Reset after 5 seconds
      setTimeout(() => {
        if (this.loadingIndicatorTarget) {
          this.loadingIndicatorTarget.innerHTML = `
            <div class="flex items-center justify-center space-x-2">
              <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-gray-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              <span class="text-sm text-gray-500">Loading more posts...</span>
            </div>
          `
        }
      }, 5000)
    }
  }
  
  // Method to be called when new items are loaded (legacy support)
  onItemsLoaded(newItems, hasMore) {
    newItems.forEach(element => this.addItem(element))
    this.hasMoreValue = hasMore
    this.pageValue += 1
    
    if (this.loadingIndicatorTarget) {
      this.loadingIndicatorTarget.style.display = 'none'
    }
  }
  
  // Handle Turbo Stream update events
  handleTurboStreamUpdate(event) {
    const { postId, action, status } = event.detail
    console.log('Virtual scroll received update:', { postId, action, status })
    
    // Find the updated element in the DOM
    const updatedElement = document.querySelector(`[data-post-id="${postId}"]`)
    if (updatedElement) {
      this.updateItem(updatedElement)
    }
  }
  
  // Handle Turbo Stream remove events
  handleTurboStreamRemove(event) {
    const { postId, action, status } = event.detail
    console.log('Virtual scroll received remove:', { postId, action, status })
    
    this.removeItem(postId)
  }
  
  // Development helper methods
  logStats() {
    console.log('Virtual Scroll Stats:', {
      totalItems: this.totalItemsValue,
      renderedItems: this.renderedItems.size,
      totalHeight: this.totalHeight,
      averageHeight: this.totalHeight / this.totalItemsValue,
      scrollPosition: this.containerTarget.scrollTop,
      enabled: this.shouldUseVirtualScrolling()
    })
  }
}