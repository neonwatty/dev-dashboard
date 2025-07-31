/**
 * SwipeHandler Utility Class
 * 
 * Provides reusable swipe gesture detection with threshold logic.
 * Optimized for mobile touch interactions with 60fps performance.
 * 
 * Features:
 * - Touch and pointer event support
 * - Direction detection (horizontal/vertical)
 * - Threshold-based swipe completion
 * - Smooth visual feedback during swipe
 * - Performance optimized with requestAnimationFrame
 * - Conflict prevention with vertical scrolling
 * 
 * Usage:
 * const swipeHandler = new SwipeHandler(element, {
 *   onSwipeStart: (data) => console.log('Swipe started', data),
 *   onSwipeMove: (data) => console.log('Swipe progress', data),
 *   onSwipeEnd: (data) => console.log('Swipe ended', data),
 *   threshold: 0.5, // 50% of element width
 *   direction: 'horizontal'
 * });
 */

export default class SwipeHandler {
  constructor(element, options = {}) {
    this.element = element
    this.options = {
      threshold: 0.5, // Percentage of element width/height needed to trigger
      direction: 'horizontal', // 'horizontal', 'vertical', or 'both'
      minDistance: 30, // Minimum distance to consider a swipe
      maxTime: 500, // Maximum time for a swipe gesture (ms)
      preventDefault: true, // Prevent default touch behavior
      onSwipeStart: null,
      onSwipeMove: null,
      onSwipeEnd: null,
      onSwipeCancel: null,
      ...options
    }

    this.isActive = false
    this.startData = null
    this.currentData = null
    this.animationFrameId = null
    this.boundaryRect = null

    // Bind event handlers
    this.handleTouchStart = this.handleTouchStart.bind(this)
    this.handleTouchMove = this.handleTouchMove.bind(this)
    this.handleTouchEnd = this.handleTouchEnd.bind(this)
    this.handleTouchCancel = this.handleTouchCancel.bind(this)

    // Support both touch and pointer events
    this.handlePointerStart = this.handlePointerStart.bind(this)
    this.handlePointerMove = this.handlePointerMove.bind(this)
    this.handlePointerEnd = this.handlePointerEnd.bind(this)
    this.handlePointerCancel = this.handlePointerCancel.bind(this)

    this.init()
  }

  init() {
    if (!this.element) {
      console.warn('SwipeHandler: No element provided')
      return
    }

    // Check for touch support
    if ('ontouchstart' in window) {
      this.addTouchListeners()
    } else if ('onpointerdown' in window) {
      this.addPointerListeners()
    } else {
      console.warn('SwipeHandler: No touch or pointer support detected')
    }
  }

  addTouchListeners() {
    this.element.addEventListener('touchstart', this.handleTouchStart, { passive: false })
    this.element.addEventListener('touchmove', this.handleTouchMove, { passive: false })
    this.element.addEventListener('touchend', this.handleTouchEnd, { passive: false })
    this.element.addEventListener('touchcancel', this.handleTouchCancel, { passive: false })
  }

  addPointerListeners() {
    this.element.addEventListener('pointerdown', this.handlePointerStart, { passive: false })
    this.element.addEventListener('pointermove', this.handlePointerMove, { passive: false })
    this.element.addEventListener('pointerup', this.handlePointerEnd, { passive: false })
    this.element.addEventListener('pointercancel', this.handlePointerCancel, { passive: false })
  }

  removeTouchListeners() {
    this.element.removeEventListener('touchstart', this.handleTouchStart)
    this.element.removeEventListener('touchmove', this.handleTouchMove)
    this.element.removeEventListener('touchend', this.handleTouchEnd)
    this.element.removeEventListener('touchcancel', this.handleTouchCancel)
  }

  removePointerListeners() {
    this.element.removeEventListener('pointerdown', this.handlePointerStart)
    this.element.removeEventListener('pointermove', this.handlePointerMove)
    this.element.removeEventListener('pointerup', this.handlePointerEnd)
    this.element.removeEventListener('pointercancel', this.handlePointerCancel)
  }

  handleTouchStart(event) {
    if (event.touches.length !== 1) return // Only handle single touch
    const touch = event.touches[0]
    this.startSwipe(touch.clientX, touch.clientY, event)
  }

  handleTouchMove(event) {
    if (!this.isActive || event.touches.length !== 1) return
    const touch = event.touches[0]
    this.updateSwipe(touch.clientX, touch.clientY, event)
  }

  handleTouchEnd(event) {
    if (!this.isActive) return
    const touch = event.changedTouches[0]
    this.endSwipe(touch.clientX, touch.clientY, event)
  }

  handleTouchCancel(event) {
    this.cancelSwipe(event)
  }

  handlePointerStart(event) {
    // Only handle primary pointer (usually finger or stylus)
    if (!event.isPrimary) return
    this.startSwipe(event.clientX, event.clientY, event)
  }

  handlePointerMove(event) {
    if (!this.isActive || !event.isPrimary) return
    this.updateSwipe(event.clientX, event.clientY, event)
  }

  handlePointerEnd(event) {
    if (!this.isActive || !event.isPrimary) return
    this.endSwipe(event.clientX, event.clientY, event)
  }

  handlePointerCancel(event) {
    this.cancelSwipe(event)
  }

  startSwipe(x, y, event) {
    // Get element boundaries for calculations
    this.boundaryRect = this.element.getBoundingClientRect()
    
    this.isActive = true
    this.startData = {
      x,
      y,
      time: Date.now(),
      elementX: this.boundaryRect.left,
      elementY: this.boundaryRect.top,
      elementWidth: this.boundaryRect.width,
      elementHeight: this.boundaryRect.height
    }

    this.currentData = { ...this.startData }

    // Call start callback
    if (this.options.onSwipeStart) {
      this.options.onSwipeStart({
        startX: x,
        startY: y,
        element: this.element,
        event
      })
    }

    console.log('🤏 Swipe started at:', { x, y })
  }

  updateSwipe(x, y, event) {
    if (!this.isActive || !this.startData) return

    // Calculate deltas
    const deltaX = x - this.startData.x
    const deltaY = y - this.startData.y
    const absDeltaX = Math.abs(deltaX)
    const absDeltaY = Math.abs(deltaY)

    // Determine if this is a horizontal or vertical gesture
    const isHorizontal = absDeltaX > absDeltaY
    const isVertical = absDeltaY > absDeltaX

    // Only proceed if gesture matches configured direction
    if (this.options.direction === 'horizontal' && !isHorizontal) {
      // Allow vertical scrolling by not preventing default
      return
    }
    if (this.options.direction === 'vertical' && !isVertical) {
      return
    }

    // Prevent default behavior to stop scrolling
    if (this.options.preventDefault) {
      event.preventDefault()
    }

    // Calculate progress as percentage of element width/height
    const elementSize = this.options.direction === 'vertical' 
      ? this.startData.elementHeight 
      : this.startData.elementWidth
    
    const progress = Math.abs(deltaX) / elementSize
    const direction = deltaX > 0 ? 'right' : 'left'

    this.currentData = {
      ...this.startData,
      currentX: x,
      currentY: y,
      deltaX,
      deltaY,
      progress: Math.min(progress, 1), // Cap at 100%
      direction,
      isHorizontalGesture: isHorizontal,
      isVerticalGesture: isVertical
    }

    // Use requestAnimationFrame for smooth visual updates
    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId)
    }

    this.animationFrameId = requestAnimationFrame(() => {
      if (this.options.onSwipeMove) {
        this.options.onSwipeMove(this.currentData)
      }
    })

    console.log('🤏 Swipe progress:', { 
      progress: `${(progress * 100).toFixed(1)}%`, 
      direction,
      deltaX: deltaX.toFixed(1)
    })
  }

  endSwipe(x, y, event) {
    if (!this.isActive || !this.startData || !this.currentData) return

    const duration = Date.now() - this.startData.time
    const deltaX = x - this.startData.x
    const deltaY = y - this.startData.y
    const distance = Math.sqrt(deltaX * deltaX + deltaY * deltaY)

    // Determine if swipe meets threshold requirements
    const meetsThreshold = this.currentData.progress >= this.options.threshold
    const meetsDistance = distance >= this.options.minDistance
    const meetsTime = duration <= this.options.maxTime
    const isValidSwipe = meetsThreshold && meetsDistance && meetsTime

    const swipeData = {
      ...this.currentData,
      endX: x,
      endY: y,
      duration,
      distance,
      velocity: distance / duration, // pixels per ms
      isComplete: isValidSwipe,
      meetsThreshold,
      meetsDistance,
      meetsTime
    }

    // Call end callback
    if (this.options.onSwipeEnd) {
      this.options.onSwipeEnd(swipeData)
    }

    console.log('🤏 Swipe ended:', {
      isComplete: isValidSwipe,
      progress: `${(this.currentData.progress * 100).toFixed(1)}%`,
      threshold: `${(this.options.threshold * 100)}%`,
      duration: `${duration}ms`,
      distance: `${distance.toFixed(1)}px`
    })

    this.reset()
  }

  cancelSwipe(event) {
    if (!this.isActive) return

    console.log('🤏 Swipe cancelled')

    // Call cancel callback
    if (this.options.onSwipeCancel) {
      this.options.onSwipeCancel({
        element: this.element,
        event
      })
    }

    this.reset()
  }

  reset() {
    this.isActive = false
    this.startData = null
    this.currentData = null
    this.boundaryRect = null

    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId)
      this.animationFrameId = null
    }
  }

  // Public methods
  enable() {
    if ('ontouchstart' in window) {
      this.addTouchListeners()
    } else if ('onpointerdown' in window) {
      this.addPointerListeners()
    }
  }

  disable() {
    this.reset()
    this.removeTouchListeners()
    this.removePointerListeners()
  }

  destroy() {
    this.disable()
    this.element = null
    this.options = null
  }

  // Update options
  updateOptions(newOptions) {
    this.options = { ...this.options, ...newOptions }
  }

  // Get current swipe state (useful for debugging)
  getState() {
    return {
      isActive: this.isActive,
      startData: this.startData,
      currentData: this.currentData,
      options: this.options
    }
  }
}