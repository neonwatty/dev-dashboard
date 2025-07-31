import { Controller } from "@hotwired/stimulus"

// Connect this controller to the document body or main container
export default class extends Controller {
  static targets = ["guide"]
  static values = { 
    enabled: { type: Boolean, default: true },
    keySequenceTimeout: { type: Number, default: 2000 }
  }

  // Track key sequences like "g+h"
  keySequence = []
  keySequenceTimer = null
  shortcutGuideModal = null

  // Define keyboard shortcuts mapping
  shortcuts = {
    // Single key shortcuts
    single: {
      '/': { action: 'focusSearch', description: 'Focus search (if available)' },
      '?': { action: 'showShortcutGuide', description: 'Show keyboard shortcuts guide' },
      'r': { action: 'refreshPage', description: 'Refresh current page' },
      'm': { action: 'markAllAsRead', description: 'Mark all posts as read' },
      'j': { action: 'navigateDown', description: 'Navigate down in lists' },
      'k': { action: 'navigateUp', description: 'Navigate up in lists' },
      'ArrowDown': { action: 'navigateDown', description: 'Navigate down in lists' },
      'ArrowUp': { action: 'navigateUp', description: 'Navigate up in lists' },
      'Enter': { action: 'activateItem', description: 'Activate selected item' },
      'Escape': { action: 'closeModals', description: 'Close modals/overlays' }
    },
    
    // Key sequences (like g+h)
    sequences: {
      'gh': { action: 'goHome', description: 'Go to dashboard/home' },
      'gs': { action: 'goSources', description: 'Go to sources page' },
      'ga': { action: 'goAnalysis', description: 'Go to analysis page' },
      'gn': { action: 'goNewSource', description: 'Go to new source page' },
      'gt': { action: 'toggleTheme', description: 'Toggle dark/light theme' }
    }
  }

  // Current focused item index for navigation
  currentItemIndex = -1
  navigableItems = []

  connect() {
    console.log("Keyboard shortcuts controller connected")
    
    // Only enable if user hasn't disabled shortcuts
    if (!this.enabledValue) {
      console.log("Keyboard shortcuts disabled by user setting")
      return
    }

    // Add keyboard event listeners
    document.addEventListener('keydown', this.handleKeyDown.bind(this))
    document.addEventListener('keyup', this.handleKeyUp.bind(this))
    
    // Initialize navigable items
    this.updateNavigableItems()
    
    // Re-scan for navigable items when DOM changes
    document.addEventListener('turbo:load', this.updateNavigableItems.bind(this))
    document.addEventListener('turbo:frame-load', this.updateNavigableItems.bind(this))

    // Announce shortcuts to screen readers
    this.announceShortcutsAvailable()
  }

  disconnect() {
    document.removeEventListener('keydown', this.handleKeyDown.bind(this))
    document.removeEventListener('keyup', this.handleKeyUp.bind(this))
    document.removeEventListener('turbo:load', this.updateNavigableItems.bind(this))
    document.removeEventListener('turbo:frame-load', this.updateNavigableItems.bind(this))
    
    if (this.keySequenceTimer) {
      clearTimeout(this.keySequenceTimer)
    }
  }

  handleKeyDown(event) {
    if (!this.enabledValue) return

    // Don't interfere when user is typing in inputs
    if (this.isUserTyping(event.target)) return

    // Don't interfere with browser shortcuts that use modifiers
    if (event.ctrlKey || event.metaKey || event.altKey) return

    const key = event.key

    // Special handling for potentially conflicting browser shortcuts
    if (this.isConflictingBrowserShortcut(key, event)) {
      console.log(`Skipping potentially conflicting shortcut: ${key}`)
      return
    }

    // Handle escape key specially - always works
    if (key === 'Escape') {
      this.closeModals()
      this.clearKeySequence()
      return
    }

    // Check for single key shortcuts first
    if (this.shortcuts.single[key]) {
      event.preventDefault()
      this.executeShortcut(this.shortcuts.single[key].action, event)
      return
    }

    // Handle key sequences (like g+h)
    if (this.isSequenceKey(key)) {
      event.preventDefault()
      this.addToKeySequence(key)
      return
    }
  }

  handleKeyUp(event) {
    // Currently not needed, but keeping for future enhancements
  }

  isUserTyping(element) {
    const tagName = element.tagName.toLowerCase()
    const inputTypes = ['input', 'textarea', 'select']
    const editableElements = element.contentEditable === 'true'
    
    return inputTypes.includes(tagName) || editableElements
  }

  isConflictingBrowserShortcut(key, event) {
    // Common browser shortcuts to avoid overriding
    const browserShortcuts = {
      'F1': 'Help',
      'F3': 'Find Next',
      'F5': 'Refresh',
      'F11': 'Fullscreen',
      'F12': 'Developer Tools',
      'Tab': 'Navigation',
      'Enter': 'Activation (but we use this intentionally)'
    }

    // Don't override browser shortcuts with function keys
    if (key.startsWith('F') && browserShortcuts[key]) {
      return true
    }

    // Be careful with Tab navigation
    if (key === 'Tab') {
      return true
    }

    // Allow our intentional shortcuts
    return false
  }

  isSequenceKey(key) {
    // Keys that can start or continue sequences
    const sequenceKeys = ['g', 'h', 's', 'a', 'n', 't']
    return sequenceKeys.includes(key.toLowerCase())
  }

  addToKeySequence(key) {
    this.keySequence.push(key.toLowerCase())
    
    // Clear existing timer
    if (this.keySequenceTimer) {
      clearTimeout(this.keySequenceTimer)
    }

    // Check if we have a complete sequence
    const sequenceString = this.keySequence.join('')
    if (this.shortcuts.sequences[sequenceString]) {
      this.executeShortcut(this.shortcuts.sequences[sequenceString].action)
      this.clearKeySequence()
      return
    }

    // Set timer to clear sequence if no more keys pressed
    this.keySequenceTimer = setTimeout(() => {
      this.clearKeySequence()
    }, this.keySequenceTimeoutValue)
  }

  clearKeySequence() {
    this.keySequence = []
    if (this.keySequenceTimer) {
      clearTimeout(this.keySequenceTimer)
      this.keySequenceTimer = null
    }
  }

  executeShortcut(action, event = null) {
    console.log(`Executing shortcut: ${action}`)

    switch (action) {
      case 'focusSearch':
        this.focusSearch()
        break
      case 'showShortcutGuide':
        this.showShortcutGuide()
        break
      case 'refreshPage':
        this.refreshPage()
        break
      case 'markAllAsRead':
        this.markAllAsRead()
        break
      case 'navigateDown':
        this.navigateDown()
        break
      case 'navigateUp':
        this.navigateUp()
        break
      case 'activateItem':
        this.activateItem()
        break
      case 'closeModals':
        this.closeModals()
        break
      case 'goHome':
        this.goHome()
        break
      case 'goSources':
        this.goSources()
        break
      case 'goAnalysis':
        this.goAnalysis()
        break
      case 'goNewSource':
        this.goNewSource()
        break
      case 'toggleTheme':
        this.toggleTheme()
        break
      default:
        console.warn(`Unknown shortcut action: ${action}`)
    }
  }

  // Navigation shortcuts
  goHome() {
    window.location.href = '/'
    this.announceNavigation('Dashboard')
  }

  goSources() {
    window.location.href = '/sources'
    this.announceNavigation('Sources')
  }

  goAnalysis() {
    window.location.href = '/analysis'
    this.announceNavigation('Analysis')
  }

  goNewSource() {
    window.location.href = '/sources/new'
    this.announceNavigation('New Source')
  }

  // Action shortcuts
  refreshPage() {
    // Try to find refresh button first, otherwise reload page
    const refreshButton = document.querySelector('[data-action*="refresh"], .refresh-btn, #refresh-btn')
    if (refreshButton) {
      refreshButton.click()
      this.announceAction('Refreshing posts')
    } else {
      window.location.reload()
      this.announceAction('Refreshing page')
    }
  }

  markAllAsRead() {
    // Look for mark all as read functionality
    const markAllButton = document.querySelector('[data-action*="mark-all"], .mark-all-read, #mark-all-read')
    if (markAllButton) {
      markAllButton.click()
      this.announceAction('Marking all posts as read')
    } else {
      this.announceAction('Mark all as read feature not available on this page')
    }
  }

  toggleTheme() {
    // Find dark mode toggle button
    const themeToggle = document.querySelector('[data-action*="dark-mode#toggle"]')
    if (themeToggle) {
      themeToggle.click()
      this.announceAction('Theme toggled')
    }
  }

  focusSearch() {
    // Look for search input
    const searchInput = document.querySelector('input[type="search"], input[placeholder*="search" i], .search-input, #search')
    if (searchInput) {
      searchInput.focus()
      this.announceAction('Search focused')
    } else {
      this.announceAction('Search not available on this page')
    }
  }

  // List navigation
  updateNavigableItems() {
    // Find navigable items (posts, sources, etc.)
    this.navigableItems = Array.from(document.querySelectorAll(
      '.post-card, .source-row, [data-keyboard-navigable], .list-item, .card'
    ))
    this.currentItemIndex = -1
  }

  navigateDown() {
    if (this.navigableItems.length === 0) {
      this.announceAction('No navigable items on this page')
      return
    }

    this.currentItemIndex = Math.min(this.currentItemIndex + 1, this.navigableItems.length - 1)
    this.highlightCurrentItem()
  }

  navigateUp() {
    if (this.navigableItems.length === 0) {
      this.announceAction('No navigable items on this page')
      return
    }

    this.currentItemIndex = Math.max(this.currentItemIndex - 1, 0)
    this.highlightCurrentItem()
  }

  highlightCurrentItem() {
    // Remove previous highlights
    this.navigableItems.forEach(item => {
      item.classList.remove('keyboard-focused')
      item.removeAttribute('aria-selected')
    })

    if (this.currentItemIndex >= 0 && this.currentItemIndex < this.navigableItems.length) {
      const currentItem = this.navigableItems[this.currentItemIndex]
      currentItem.classList.add('keyboard-focused')
      currentItem.setAttribute('aria-selected', 'true')
      
      // Scroll into view if needed
      currentItem.scrollIntoView({ behavior: 'smooth', block: 'nearest' })

      // Announce current item to screen readers
      const itemText = currentItem.textContent.trim().substring(0, 100)
      this.announceToScreenReader(`Selected: ${itemText}`)
    }
  }

  activateItem() {
    if (this.currentItemIndex >= 0 && this.currentItemIndex < this.navigableItems.length) {
      const currentItem = this.navigableItems[this.currentItemIndex]
      
      // Try to find the main link/button to activate
      const link = currentItem.querySelector('a') || currentItem.querySelector('button')
      if (link) {
        link.click()
        this.announceAction('Item activated')
      } else if (currentItem.tagName.toLowerCase() === 'a' || currentItem.tagName.toLowerCase() === 'button') {
        currentItem.click()
        this.announceAction('Item activated')
      }
    }
  }

  // Modal management
  closeModals() {
    // Close keyboard shortcut guide if open
    if (this.shortcutGuideModal) {
      this.hideShortcutGuide()
      return
    }

    // Close mobile menu if open
    const mobileMenuController = this.application.getControllerForElementAndIdentifier(document.body, 'mobile-menu')
    if (mobileMenuController && mobileMenuController.isOpen) {
      mobileMenuController.close()
      return
    }

    // Close any other modals
    const openModals = document.querySelectorAll('.modal:not([hidden]), [data-modal-open="true"], .modal-open')
    openModals.forEach(modal => {
      // Try to find close button
      const closeButton = modal.querySelector('.modal-close, .close-btn, [data-action*="close"]')
      if (closeButton) {
        closeButton.click()
      } else {
        modal.hidden = true
        modal.removeAttribute('data-modal-open')
        modal.classList.remove('modal-open')
      }
    })

    if (openModals.length > 0) {
      this.announceAction('Modals closed')
    }
  }

  // Shortcut guide modal
  showShortcutGuide() {
    // Check if we have a pre-rendered guide first
    const preRenderedGuide = document.getElementById('keyboard-guide')
    if (preRenderedGuide) {
      preRenderedGuide.classList.remove('hidden')
      preRenderedGuide.querySelector('button').focus()
      this.announceAction('Keyboard shortcuts guide opened')
      return
    }

    // Fall back to JavaScript-generated modal
    if (this.shortcutGuideModal) {
      this.hideShortcutGuide()
      return
    }

    this.createShortcutGuideModal()
    this.announceAction('Keyboard shortcuts guide opened')
  }

  hideShortcutGuide() {
    // Check for pre-rendered guide first
    const preRenderedGuide = document.getElementById('keyboard-guide')
    if (preRenderedGuide && !preRenderedGuide.classList.contains('hidden')) {
      preRenderedGuide.classList.add('hidden')
      this.announceAction('Keyboard shortcuts guide closed')
      return
    }

    // Fall back to JavaScript-generated modal
    if (this.shortcutGuideModal) {
      this.shortcutGuideModal.remove()
      this.shortcutGuideModal = null
      this.announceAction('Keyboard shortcuts guide closed')
    }
  }

  createShortcutGuideModal() {
    const modal = document.createElement('div')
    modal.className = 'fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4'
    modal.setAttribute('role', 'dialog')
    modal.setAttribute('aria-modal', 'true')
    modal.setAttribute('aria-labelledby', 'shortcut-guide-title')

    modal.innerHTML = `
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div class="p-6">
          <div class="flex justify-between items-center mb-6">
            <h2 id="shortcut-guide-title" class="text-2xl font-bold text-gray-900 dark:text-gray-100">
              Keyboard Shortcuts
            </h2>
            <button class="p-2 rounded-lg text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
                    onclick="this.closest('[role=dialog]').remove()"
                    aria-label="Close shortcuts guide">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
              </svg>
            </button>
          </div>

          <div class="space-y-6">
            <div>
              <h3 class="text-lg font-semibold text-gray-800 dark:text-gray-200 mb-3">Navigation</h3>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                ${this.generateShortcutItems([
                  ['g h', 'Go to Dashboard'],
                  ['g s', 'Go to Sources'],
                  ['g a', 'Go to Analysis'],
                  ['g n', 'New Source'],
                  ['j or ↓', 'Navigate down'],
                  ['k or ↑', 'Navigate up'],
                  ['Enter', 'Activate item']
                ])}
              </div>
            </div>

            <div>
              <h3 class="text-lg font-semibold text-gray-800 dark:text-gray-200 mb-3">Actions</h3>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                ${this.generateShortcutItems([
                  ['r', 'Refresh'],
                  ['m', 'Mark all as read'],
                  ['g t', 'Toggle theme'],
                  ['/', 'Focus search'],
                  ['?', 'Show this guide'],
                  ['Esc', 'Close modals']
                ])}
              </div>
            </div>

            <div class="pt-4 border-t border-gray-200 dark:border-gray-700">
              <p class="text-sm text-gray-600 dark:text-gray-400">
                Press <kbd class="px-2 py-1 bg-gray-100 dark:bg-gray-700 rounded font-mono text-xs">?</kbd> 
                anytime to show this guide. Shortcuts work when you're not typing in form fields.
              </p>
            </div>
          </div>
        </div>
      </div>
    `

    // Close on backdrop click
    modal.addEventListener('click', (e) => {
      if (e.target === modal) {
        modal.remove()
        this.shortcutGuideModal = null
      }
    })

    // Close on escape key
    const handleEscape = (e) => {
      if (e.key === 'Escape') {
        modal.remove()
        this.shortcutGuideModal = null
        document.removeEventListener('keydown', handleEscape)
      }
    }
    document.addEventListener('keydown', handleEscape)

    document.body.appendChild(modal)
    this.shortcutGuideModal = modal

    // Focus the modal for accessibility
    modal.querySelector('button').focus()
  }

  generateShortcutItems(shortcuts) {
    return shortcuts.map(([key, description]) => `
      <div class="flex justify-between items-center py-2 px-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
        <span class="text-sm text-gray-900 dark:text-gray-100">${description}</span>
        <kbd class="px-2 py-1 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded font-mono text-xs text-gray-800 dark:text-gray-200">
          ${key}
        </kbd>
      </div>
    `).join('')
  }

  // Screen reader announcements
  announceShortcutsAvailable() {
    setTimeout(() => {
      this.announceToScreenReader('Keyboard shortcuts are available. Press question mark for the shortcuts guide.')
    }, 2000)
  }

  announceNavigation(destination) {
    this.announceToScreenReader(`Navigating to ${destination}`)
  }

  announceAction(action) {
    this.announceToScreenReader(action)
  }

  announceToScreenReader(message) {
    // Find the polite announcement region
    const announceRegion = document.getElementById('sr-polite-announcements')
    if (announceRegion) {
      announceRegion.textContent = message
      
      // Clear after a delay to ensure it can be announced again later
      setTimeout(() => {
        announceRegion.textContent = ''
      }, 1000)
    }
  }

  // Method called from the erb partial
  hideGuide() {
    this.hideShortcutGuide()
  }

  // Settings management
  enableShortcuts() {
    this.enabledValue = true
    this.announceAction('Keyboard shortcuts enabled')
  }

  disableShortcuts() {
    this.enabledValue = false
    this.announceAction('Keyboard shortcuts disabled')
  }

  toggleShortcuts() {
    this.enabledValue = !this.enabledValue
    this.announceAction(`Keyboard shortcuts ${this.enabledValue ? 'enabled' : 'disabled'}`)
  }
}