import { Controller } from "@hotwired/stimulus"
import SwipeHandler from "../utils/swipe_handler.js"

/**
 * Mobile Menu Controller
 * 
 * Handles mobile navigation interactions with full accessibility support.
 * 
 * Features:
 * - Toggle hamburger menu open/close
 * - Backdrop click-to-close functionality
 * - Focus trapping when menu is open
 * - Keyboard navigation (ESC key to close, Tab cycling)
 * - Body scroll prevention when menu is open
 * - ARIA attributes for screen readers
 * - Smooth animations with existing CSS classes
 * - Responsive behavior (auto-close on desktop)
 * 
 * Required targets: button, hamburger, backdrop, drawer
 * Required CSS classes: .hamburger.open, .mobile-drawer.open/.closed, 
 *                      .mobile-backdrop.visible/.hidden, .mobile-menu-open
 */

// Connects to data-controller="mobile-menu"
export default class extends Controller {
  static targets = ["button", "hamburger", "backdrop", "drawer"]
  
  connect() {
    console.log("📱 MobileMenuController connected")
    
    // Bind keyboard handlers
    this.handleKeydown = this.handleKeydown.bind(this)
    this.handleEscape = this.handleEscape.bind(this)
    this.handleResize = this.handleResize.bind(this)
    
    // Store original body overflow
    this.originalBodyOverflow = document.body.style.overflow
    
    // Initialize ARIA attributes
    this.initializeAccessibility()
    
    // Ensure menu is closed on initialization
    this.isOpen = false
    this.isSwipeInProgress = false
    this.swipeHandler = null
    
    // Don't call closeMenu() here, just ensure correct initial classes
    if (this.hasDrawerTarget) {
      this.drawerTarget.classList.add("closed")
      this.drawerTarget.classList.remove("open")
    }
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.add("hidden")
      this.backdropTarget.classList.remove("visible")
    }
    if (this.hasHamburgerTarget) {
      this.hamburgerTarget.classList.remove("open")
    }
    
    // Initialize swipe gesture support
    this.initializeSwipeGestures()
    
    // Add resize listener for responsive behavior
    window.addEventListener("resize", this.handleResize)
  }
  
  disconnect() {
    console.log("📱 MobileMenuController disconnected")
    
    // Clean up event listeners
    document.removeEventListener("keydown", this.handleKeydown)
    window.removeEventListener("resize", this.handleResize)
    
    // Clean up swipe handler
    if (this.swipeHandler) {
      this.swipeHandler.destroy()
      this.swipeHandler = null
    }
    
    // Restore body scroll
    this.restoreBodyScroll()
  }
  
  // Initialize accessibility attributes
  initializeAccessibility() {
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "false")
      this.buttonTarget.setAttribute("aria-controls", "mobile-navigation-drawer")
    }
    
    if (this.hasDrawerTarget) {
      this.drawerTarget.setAttribute("id", "mobile-navigation-drawer")
      this.drawerTarget.setAttribute("aria-hidden", "true")
    }
  }
  
  // Toggle menu open/close
  toggle() {
    console.log("📱 Toggle mobile menu")
    
    if (this.isOpen) {
      this.closeMenu()
    } else {
      this.openMenu()
    }
  }
  
  // Open the mobile menu
  openMenu() {
    console.log("📱 Opening mobile menu")
    
    this.isOpen = true
    
    // Update visual states
    this.updateVisualState(true)
    
    // Update accessibility attributes
    this.updateAccessibilityState(true)
    
    // Prevent body scroll
    this.preventBodyScroll()
    
    // Add keyboard event listeners
    document.addEventListener("keydown", this.handleKeydown)
    
    // Focus trap
    this.setupFocusTrap()
    
    // Announce to screen readers
    this.announceToScreenReader("Navigation menu opened")
    
    // Enable swipe gestures when menu opens
    if (this.swipeHandler) {
      this.swipeHandler.enable()
    }
    
    // Focus the first focusable element
    requestAnimationFrame(() => {
      this.focusFirstElement()
    })
  }
  
  // Close the mobile menu
  closeMenu() {
    console.log("📱 Closing mobile menu")
    
    this.isOpen = false
    
    // Update visual states
    this.updateVisualState(false)
    
    // Update accessibility attributes
    this.updateAccessibilityState(false)
    
    // Restore body scroll
    this.restoreBodyScroll()
    
    // Remove keyboard event listeners
    document.removeEventListener("keydown", this.handleKeydown)
    
    // Remove focus trap
    this.removeFocusTrap()
    
    // Reset any swipe-related styles
    this.resetSwipeStyles()
    
    // Announce to screen readers
    this.announceToScreenReader("Navigation menu closed")
    
    // Return focus to the menu button
    if (this.hasButtonTarget) {
      this.buttonTarget.focus()
    }
  }
  
  // Close menu (alias for data-action)
  close() {
    this.closeMenu()
  }
  
  // Update visual state of menu components
  updateVisualState(isOpen) {
    // Toggle hamburger animation
    if (this.hasHamburgerTarget) {
      this.hamburgerTarget.classList.toggle("open", isOpen)
    }
    
    // Toggle drawer visibility
    if (this.hasDrawerTarget) {
      if (isOpen) {
        // Show drawer - don't use hidden class since CSS uses transform
        this.drawerTarget.classList.add("open")
        this.drawerTarget.classList.remove("closed")
      } else {
        // Hide drawer - don't use hidden class since CSS uses transform
        this.drawerTarget.classList.add("closed")
        this.drawerTarget.classList.remove("open")
      }
    }
    
    // Toggle backdrop visibility
    if (this.hasBackdropTarget) {
      if (isOpen) {
        // Show backdrop
        this.backdropTarget.classList.remove("hidden")
        this.backdropTarget.classList.add("visible")
      } else {
        // Hide backdrop
        this.backdropTarget.classList.add("hidden")
        this.backdropTarget.classList.remove("visible")
      }
    }
  }
  
  // Update accessibility state
  updateAccessibilityState(isOpen) {
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", isOpen.toString())
      this.buttonTarget.setAttribute("aria-label", isOpen ? "Close navigation menu" : "Open navigation menu")
    }
    
    if (this.hasDrawerTarget) {
      this.drawerTarget.setAttribute("aria-hidden", (!isOpen).toString())
    }
  }
  
  // Prevent body scroll when menu is open
  preventBodyScroll() {
    document.body.classList.add("mobile-menu-open")
    document.body.style.overflow = "hidden"
  }
  
  // Restore body scroll when menu is closed
  restoreBodyScroll() {
    document.body.classList.remove("mobile-menu-open")
    document.body.style.overflow = this.originalBodyOverflow || ""
  }
  
  // Handle keyboard interactions
  handleKeydown(event) {
    if (!this.isOpen) return
    
    switch (event.key) {
      case "Escape":
        this.handleEscape(event)
        break
      case "Tab":
        this.handleTab(event)
        break
    }
  }
  
  // Handle escape key
  handleEscape(event) {
    event.preventDefault()
    this.closeMenu()
  }
  
  // Handle tab key for focus trapping
  handleTab(event) {
    if (!this.focusableElements || this.focusableElements.length === 0) return
    
    const firstElement = this.focusableElements[0]
    const lastElement = this.focusableElements[this.focusableElements.length - 1]
    
    if (event.shiftKey) {
      // Shift + Tab (backwards)
      if (document.activeElement === firstElement) {
        event.preventDefault()
        lastElement.focus()
      }
    } else {
      // Tab (forwards)
      if (document.activeElement === lastElement) {
        event.preventDefault()
        firstElement.focus()
      }
    }
  }
  
  // Setup focus trap
  setupFocusTrap() {
    if (!this.hasDrawerTarget) return
    
    // Find all focusable elements within the drawer
    this.focusableElements = this.getFocusableElements(this.drawerTarget)
    
    // Add focus trap class for styling
    this.drawerTarget.classList.add("focus-trap")
  }
  
  // Remove focus trap
  removeFocusTrap() {
    if (this.hasDrawerTarget) {
      this.drawerTarget.classList.remove("focus-trap")
    }
    this.focusableElements = null
  }
  
  // Get all focusable elements within a container
  getFocusableElements(container) {
    const focusableSelectors = [
      'a[href]',
      'button:not([disabled])',
      'input:not([disabled]):not([type="hidden"])',
      'select:not([disabled])',
      'textarea:not([disabled])',
      '[tabindex]:not([tabindex="-1"])',
      '[contenteditable="true"]'
    ]
    
    const elements = container.querySelectorAll(focusableSelectors.join(', '))
    
    // Filter out elements that are not visible
    return Array.from(elements).filter(element => {
      return element.offsetWidth > 0 && 
             element.offsetHeight > 0 && 
             !element.hidden &&
             getComputedStyle(element).visibility !== 'hidden'
    })
  }
  
  // Focus the first focusable element
  focusFirstElement() {
    if (this.focusableElements && this.focusableElements.length > 0) {
      this.focusableElements[0].focus()
    } else if (this.hasDrawerTarget) {
      // Fallback: focus the drawer itself
      this.drawerTarget.focus()
    }
  }
  
  // Handle backdrop click to close menu
  backdropClicked(event) {
    // Close menu on any backdrop click - the backdrop shouldn't have child elements
    console.log("📱 Backdrop clicked, closing menu")
    this.closeMenu()
  }
  
  // Handle resize events (optional - for responsive behavior)
  handleResize() {
    // Close menu if screen becomes larger (desktop view)
    if (window.innerWidth >= 768 && this.isOpen) {
      this.closeMenu()
    }
  }
  
  // Get current menu state (useful for debugging)
  get menuState() {
    return {
      isOpen: this.isOpen,
      hasTargets: {
        button: this.hasButtonTarget,
        hamburger: this.hasHamburgerTarget,
        backdrop: this.hasBackdropTarget,
        drawer: this.hasDrawerTarget
      },
      focusableElementsCount: this.focusableElements ? this.focusableElements.length : 0
    }
  }
  
  // Announce changes to screen readers
  announceToScreenReader(message) {
    // Dispatch event for screen reader controller to handle
    document.dispatchEvent(new CustomEvent('screenreader:status', {
      detail: { message }
    }))
  }

  // Initialize swipe gesture support
  initializeSwipeGestures() {
    if (!this.hasDrawerTarget) {
      console.warn("📱 Cannot initialize swipe gestures: drawer target not found")
      return
    }

    // Create swipe handler for the drawer
    this.swipeHandler = new SwipeHandler(this.drawerTarget, {
      direction: 'horizontal',
      threshold: 0.5, // 50% of drawer width to trigger close
      onSwipeStart: this.handleSwipeStart.bind(this),
      onSwipeMove: this.handleSwipeMove.bind(this),
      onSwipeEnd: this.handleSwipeEnd.bind(this),
      onSwipeCancel: this.handleSwipeCancel.bind(this)
    })

    console.log("📱 Swipe gestures initialized")
  }

  // Handle swipe start
  handleSwipeStart(data) {
    // Only enable swipe-to-close when menu is open
    if (!this.isOpen) return

    console.log("📱 Swipe started on drawer")
    this.isSwipeInProgress = true

    // Add swiping classes for optimized CSS
    if (this.hasDrawerTarget) {
      this.drawerTarget.classList.add('swiping')
    }
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.add('swiping')
    }
  }

  // Handle swipe move - provide visual feedback
  handleSwipeMove(data) {
    if (!this.isOpen || !this.isSwipeInProgress) return

    // Only allow right swipe (closing direction)
    if (data.direction !== 'right') return

    // Calculate transform based on swipe progress
    // Drawer starts at translateX(0) when open, moves to translateX(100%) when closed
    const translateX = Math.min(data.progress * 100, 100)
    
    // Apply transform for visual feedback
    if (this.hasDrawerTarget) {
      this.drawerTarget.style.transform = `translateX(${translateX}%)`
    }

    // Reduce backdrop opacity based on swipe progress
    if (this.hasBackdropTarget) {
      const opacity = Math.max(1 - data.progress, 0)
      this.backdropTarget.style.opacity = opacity.toString()
    }

    console.log(`📱 Swipe progress: ${(data.progress * 100).toFixed(1)}%`)
  }

  // Handle swipe end - determine if menu should close
  handleSwipeEnd(data) {
    if (!this.isOpen || !this.isSwipeInProgress) return

    console.log(`📱 Swipe ended - Complete: ${data.isComplete}`)
    
    this.isSwipeInProgress = false

    // Remove swiping classes
    if (this.hasDrawerTarget) {
      this.drawerTarget.classList.remove('swiping')
    }
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove('swiping')
    }

    if (data.isComplete && data.direction === 'right') {
      // Swipe was successful - close the menu
      this.closeMenuFromSwipe()
    } else {
      // Swipe was cancelled or didn't meet threshold - snap back
      this.snapBackToOpen()
    }
  }

  // Handle swipe cancel
  handleSwipeCancel(data) {
    if (!this.isSwipeInProgress) return

    console.log("📱 Swipe cancelled")
    this.isSwipeInProgress = false

    // Remove swiping classes and snap back
    if (this.hasDrawerTarget) {
      this.drawerTarget.classList.remove('swiping')
    }
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove('swiping')
    }
    this.snapBackToOpen()
  }

  // Close menu from successful swipe gesture
  closeMenuFromSwipe() {
    console.log("📱 Closing menu from swipe gesture")

    // Use the existing closeMenu method but skip the transform animation
    // since we've already animated it during the swipe
    this.isOpen = false

    // Update visual states
    this.updateVisualState(false)

    // Update accessibility attributes
    this.updateAccessibilityState(false)

    // Restore body scroll
    this.restoreBodyScroll()

    // Remove keyboard event listeners
    document.removeEventListener("keydown", this.handleKeydown)

    // Remove focus trap
    this.removeFocusTrap()

    // Announce to screen readers
    this.announceToScreenReader("Navigation menu closed")

    // Return focus to the menu button
    if (this.hasButtonTarget) {
      this.buttonTarget.focus()
    }

    // Reset any inline styles applied during swipe
    this.resetSwipeStyles()
  }

  // Snap back to open position when swipe is cancelled
  snapBackToOpen() {
    console.log("📱 Snapping drawer back to open position")

    // Add snap-back classes for smooth animation
    if (this.hasDrawerTarget) {
      this.drawerTarget.classList.add('snapping-back')
      this.drawerTarget.style.transform = 'translateX(0)'
    }

    // Reset backdrop opacity with snap-back animation
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.add('snapping-back')
      this.backdropTarget.style.opacity = '1'
    }

    // Clean up classes and inline styles after animation
    setTimeout(() => {
      this.resetSwipeStyles()
      if (this.hasDrawerTarget) {
        this.drawerTarget.classList.remove('snapping-back')
      }
      if (this.hasBackdropTarget) {
        this.backdropTarget.classList.remove('snapping-back')
      }
    }, 250) // Match CSS snap-back transition duration
  }

  // Reset any inline styles applied during swipe
  resetSwipeStyles() {
    if (this.hasDrawerTarget) {
      this.drawerTarget.style.transform = ''
      this.drawerTarget.style.transition = ''
      // Remove any swipe-related classes
      this.drawerTarget.classList.remove('swiping', 'snapping-back')
    }
    if (this.hasBackdropTarget) {
      this.backdropTarget.style.opacity = ''
      // Remove any swipe-related classes
      this.backdropTarget.classList.remove('swiping', 'snapping-back')
    }
  }


  // Utility method for debugging
  debug() {
    console.log("📱 Mobile Menu State:", this.menuState)
    if (this.swipeHandler) {
      console.log("📱 Swipe Handler State:", this.swipeHandler.getState())
    }
  }
}