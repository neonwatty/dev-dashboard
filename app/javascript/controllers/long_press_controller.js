import { Controller } from "@hotwired/stimulus"
import HapticFeedback from "../utils/haptics"

export default class extends Controller {
  static targets = ["element"]
  static values = { 
    duration: { type: Number, default: 500 },
    actions: { type: Array, default: [] }
  }

  connect() {
    this.pressTimer = null
    this.isPressed = false
    this.touchStartX = 0
    this.touchStartY = 0
    this.currentMenu = null
    
    const element = this.hasElementTarget ? this.elementTarget : this.element
    
    element.addEventListener("touchstart", this.handleTouchStart.bind(this), { passive: false })
    element.addEventListener("touchend", this.handleTouchEnd.bind(this), { passive: true })
    element.addEventListener("touchmove", this.handleTouchMove.bind(this), { passive: true })
    element.addEventListener("contextmenu", this.handleContextMenu.bind(this))
  }

  disconnect() {
    const element = this.hasElementTarget ? this.elementTarget : this.element
    
    element.removeEventListener("touchstart", this.handleTouchStart.bind(this))
    element.removeEventListener("touchend", this.handleTouchEnd.bind(this))
    element.removeEventListener("touchmove", this.handleTouchMove.bind(this))
    element.removeEventListener("contextmenu", this.handleContextMenu.bind(this))
    
    if (this.currentMenu) {
      this.hideActionMenu(this.currentMenu)
    }
  }

  handleTouchStart(e) {
    // Only handle single touch
    if (e.touches.length !== 1) return
    
    e.preventDefault()
    this.isPressed = true
    this.touchStartX = e.touches[0].clientX
    this.touchStartY = e.touches[0].clientY
    
    // Start haptic feedback timer
    this.pressTimer = setTimeout(() => {
      if (this.isPressed) {
        this.triggerLongPress(e)
      }
    }, this.durationValue)
    
    // Visual feedback
    const element = this.hasElementTarget ? this.elementTarget : this.element
    element.classList.add("long-pressing")
  }

  handleTouchEnd(e) {
    this.cancelLongPress()
  }

  handleTouchMove(e) {
    if (!this.isPressed) return
    
    // Cancel if finger moves too much (more than 10px)
    const deltaX = Math.abs(e.touches[0].clientX - this.touchStartX)
    const deltaY = Math.abs(e.touches[0].clientY - this.touchStartY)
    
    if (deltaX > 10 || deltaY > 10) {
      this.cancelLongPress()
    }
  }

  handleContextMenu(e) {
    // Prevent default context menu on long press
    e.preventDefault()
  }

  triggerLongPress(e) {
    // Haptic feedback
    HapticFeedback.heavy()
    
    // Show action menu at touch position
    this.showActionMenu(this.touchStartX, this.touchStartY)
  }

  showActionMenu(x, y) {
    // Remove any existing menu
    if (this.currentMenu) {
      this.hideActionMenu(this.currentMenu)
    }
    
    const menu = this.createActionMenu()
    document.body.appendChild(menu)
    this.currentMenu = menu
    
    // Position menu - adjust if too close to edges
    const rect = menu.getBoundingClientRect()
    let menuX = x - (rect.width / 2)
    let menuY = y - rect.height - 20 // Position above finger
    
    // Keep menu on screen
    menuX = Math.max(10, Math.min(menuX, window.innerWidth - rect.width - 10))
    menuY = Math.max(10, menuY)
    
    // If too close to top, position below finger instead
    if (menuY < 10) {
      menuY = y + 20
    }
    
    menu.style.left = `${menuX}px`
    menu.style.top = `${menuY}px`
    
    // Animate in
    requestAnimationFrame(() => {
      menu.classList.add("visible")
    })
    
    // Auto-dismiss after delay
    this.dismissTimer = setTimeout(() => {
      this.hideActionMenu(menu)
    }, 3000)
    
    // Close on any outside tap
    this.outsideClickHandler = (e) => {
      if (!menu.contains(e.target)) {
        this.hideActionMenu(menu)
      }
    }
    document.addEventListener("touchstart", this.outsideClickHandler)
  }

  createActionMenu() {
    const menu = document.createElement("div")
    menu.className = "long-press-menu"
    
    // If no actions provided, use default actions based on available buttons
    let actions = this.actionsValue
    if (!actions || actions.length === 0) {
      actions = this.getDefaultActions()
    }
    
    actions.forEach(action => {
      const button = document.createElement("button")
      button.className = "long-press-action"
      button.innerHTML = `
        <span class="long-press-action-icon">${this.getActionIcon(action.icon || action.label)}</span>
        <span class="long-press-action-label">${action.label}</span>
      `
      button.addEventListener("click", (e) => {
        e.preventDefault()
        e.stopPropagation()
        this.executeAction(action)
        this.hideActionMenu(menu)
      })
      menu.appendChild(button)
    })
    
    return menu
  }

  getDefaultActions() {
    const actions = []
    const element = this.hasElementTarget ? this.elementTarget : this.element
    
    // Look for action buttons in the post card
    const readButton = element.querySelector('[data-action*="markAsRead"]')
    if (readButton && !readButton.disabled) {
      actions.push({
        label: "Mark as Read",
        target: "markAsRead",
        icon: "check"
      })
    }
    
    const clearButton = element.querySelector('[data-action*="clear"]')
    if (clearButton && !clearButton.disabled) {
      actions.push({
        label: "Clear",
        target: "clear",
        icon: "x"
      })
    }
    
    const respondButton = element.querySelector('[data-action*="markAsResponded"]')
    if (respondButton && !respondButton.disabled) {
      actions.push({
        label: "Mark as Responded",
        target: "markAsResponded",
        icon: "reply"
      })
    }
    
    return actions
  }

  getActionIcon(type) {
    const icons = {
      "check": '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>',
      "x": '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>',
      "reply": '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6"></path></svg>',
      "share": '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m9.632 4.684C18.114 16.938 18 16.482 18 16c0-.482.114-.938.316-1.342m0 2.684a3 3 0 110-2.684M9.316 8.658C9.114 9.062 9 9.518 9 10c0 .482.114.938.316 1.342M3 11a3 3 0 100-2 3 3 0 000 2zm12 5a3 3 0 100-2 3 3 0 000 2z"></path></svg>',
      "link": '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"></path></svg>',
      "archive": '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4"></path></svg>',
      "Mark as Read": '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>',
      "Clear": '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>',
      "Mark as Responded": '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6"></path></svg>'
    }
    return icons[type] || ""
  }

  executeAction(action) {
    const element = this.hasElementTarget ? this.elementTarget : this.element
    
    // Find the button with the matching action
    const button = element.querySelector(`[data-action*="${action.target}"]`)
    if (button) {
      // Light haptic feedback for action
      HapticFeedback.light()
      button.click()
    }
  }

  hideActionMenu(menu) {
    if (!menu) return
    
    clearTimeout(this.dismissTimer)
    document.removeEventListener("touchstart", this.outsideClickHandler)
    
    menu.classList.remove("visible")
    
    setTimeout(() => {
      if (menu.parentNode) {
        menu.remove()
      }
    }, 200)
    
    if (this.currentMenu === menu) {
      this.currentMenu = null
    }
  }

  cancelLongPress() {
    this.isPressed = false
    if (this.pressTimer) {
      clearTimeout(this.pressTimer)
      this.pressTimer = null
    }
    
    const element = this.hasElementTarget ? this.elementTarget : this.element
    element.classList.remove("long-pressing")
  }
}