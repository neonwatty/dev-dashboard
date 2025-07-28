# Phase 3: Touch Interactions & Gestures

## Overview

This phase adds native-like touch interactions and gestures to make the app feel responsive and intuitive on mobile devices.

## Primary Agents

- **Lead**: `javascript-package-expert` (gesture implementation)
- **Support**: `tailwind-css-expert` (visual feedback)
- **Handoff**: `test-runner-fixer` (interaction testing)

## Tasks

### 3.1 Swipe Gestures for Post Actions

**Agent**: `javascript-package-expert`

#### Implementation

Create Stimulus controller for swipe gestures:

```javascript
// app/javascript/controllers/swipe_actions_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card", "actionsLeft", "actionsRight"]
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
    this.cardTarget.addEventListener("touchstart", this.handleTouchStart.bind(this))
    this.cardTarget.addEventListener("touchmove", this.handleTouchMove.bind(this))
    this.cardTarget.addEventListener("touchend", this.handleTouchEnd.bind(this))
    
    // Add visual feedback elements
    this.setupSwipeIndicators()
  }

  handleTouchStart(e) {
    if (e.touches.length !== 1) return
    
    this.initialX = e.touches[0].clientX
    this.currentX = this.initialX
    this.isDragging = true
    this.hasTriggered = false
    
    // Add dragging state
    this.cardTarget.classList.add("dragging")
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
    
    // Execute action if threshold met
    if (Math.abs(deltaX) >= this.thresholdValue) {
      this.executeSwipeAction(deltaX)
    } else {
      this.resetCard()
    }
    
    this.cardTarget.classList.remove("dragging")
  }

  updateSwipeVisuals(deltaX) {
    // Transform card
    this.cardTarget.style.transform = `translateX(${deltaX}px)`
    
    // Show/hide action indicators
    if (deltaX > 0) {
      // Swiping right - show "mark as read" 
      this.showLeftActions(deltaX / this.thresholdValue)
      this.hideRightActions()
    } else if (deltaX < 0) {
      // Swiping left - show "clear/delete"
      this.showRightActions(Math.abs(deltaX) / this.thresholdValue)
      this.hideLeftActions()
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
    // Trigger existing post action
    const readButton = this.cardTarget.querySelector('[data-post-actions-target="readButton"]')
    if (readButton) {
      this.animateSuccess("read")
      readButton.click()
    }
  }

  clearPost() {
    // Trigger existing clear action
    const clearButton = this.cardTarget.querySelector('[data-post-actions-target="clearButton"]')
    if (clearButton) {
      this.animateSuccess("cleared")
      clearButton.click()
    }
  }

  animateSuccess(action) {
    // Add success animation
    this.cardTarget.classList.add(`swipe-${action}`)
    
    // Fade out card
    setTimeout(() => {
      this.cardTarget.style.opacity = "0.3"
      this.cardTarget.style.transform = "scale(0.95)"
    }, 150)
  }

  resetCard() {
    this.cardTarget.style.transform = ""
    this.hideLeftActions()
    this.hideRightActions()
  }

  setupSwipeIndicators() {
    // Create left action indicator (mark as read)
    const leftIndicator = document.createElement("div")
    leftIndicator.className = "swipe-indicator swipe-indicator-left"
    leftIndicator.innerHTML = `
      <svg class="w-6 h-6 text-green-600">
        <path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
      </svg>
      <span>Mark as Read</span>
    `
    
    // Create right action indicator (clear)
    const rightIndicator = document.createElement("div")
    rightIndicator.className = "swipe-indicator swipe-indicator-right"
    rightIndicator.innerHTML = `
      <svg class="w-6 h-6 text-red-600">
        <path d="M6 18L18 6M6 6l12 12"/>
      </svg>
      <span>Clear</span>
    `
    
    this.cardTarget.parentNode.insertBefore(leftIndicator, this.cardTarget)
    this.cardTarget.parentNode.insertBefore(rightIndicator, this.cardTarget.nextSibling)
  }
}
```

#### CSS Support

```scss
// app/assets/stylesheets/swipe_gestures.scss
.swipe-indicator {
  @apply absolute inset-y-0 flex items-center justify-center;
  @apply px-4 opacity-0 transition-opacity duration-200;
  @apply text-white font-medium text-sm;
  
  &.active {
    @apply opacity-100;
  }
  
  &-left {
    @apply left-0 bg-green-500;
  }
  
  &-right {
    @apply right-0 bg-red-500;
  }
}

.post-card {
  @apply relative transition-transform duration-200;
  
  &.dragging {
    @apply transition-none;
  }
  
  &.swipe-read {
    @apply bg-green-50 dark:bg-green-900/20;
  }
  
  &.swipe-cleared {
    @apply bg-red-50 dark:bg-red-900/20;
  }
}
```

### 3.2 Pull-to-Refresh Implementation

**Agent**: `javascript-package-expert`

#### Stimulus Controller

```javascript
// app/javascript/controllers/pull_to_refresh_controller.js
import { Controller } from "@hotwired/stimulus"

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
    
    this.containerTarget.addEventListener("touchstart", this.handleTouchStart.bind(this))
    this.containerTarget.addEventListener("touchmove", this.handleTouchMove.bind(this))
    this.containerTarget.addEventListener("touchend", this.handleTouchEnd.bind(this))
    
    this.createRefreshIndicator()
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
    const progress = Math.min(deltaY / this.thresholdValue, 1)
    const rotation = progress * 180
    
    // Update indicator position and rotation
    this.indicatorTarget.style.transform = `translateY(${deltaY * 0.5}px) rotate(${rotation}deg)`
    this.indicatorTarget.style.opacity = progress
    
    // Change indicator state at threshold
    if (progress >= 1) {
      this.indicatorTarget.classList.add("ready")
    } else {
      this.indicatorTarget.classList.remove("ready")
    }
  }

  triggerRefresh() {
    this.isRefreshing = true
    this.indicatorTarget.classList.add("refreshing")
    
    // Show loading state
    this.showRefreshSpinner()
    
    // Trigger refresh
    fetch(this.urlValue, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
    .then(response => response.text())
    .then(html => {
      // Handle Turbo Stream response
      Turbo.renderStreamMessage(html)
      this.completeRefresh()
    })
    .catch(error => {
      console.error("Refresh failed:", error)
      this.completeRefresh()
    })
  }

  completeRefresh() {
    setTimeout(() => {
      this.isRefreshing = false
      this.resetPull()
      this.hideRefreshSpinner()
    }, 500)
  }

  resetPull() {
    this.indicatorTarget.style.transform = ""
    this.indicatorTarget.style.opacity = "0"
    this.indicatorTarget.classList.remove("ready", "refreshing")
  }

  createRefreshIndicator() {
    const indicator = document.createElement("div")
    indicator.className = "pull-refresh-indicator"
    indicator.innerHTML = `
      <svg class="w-6 h-6 text-blue-600">
        <path d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
      </svg>
    `
    
    this.containerTarget.insertBefore(indicator, this.containerTarget.firstChild)
    this.indicatorTarget = indicator
  }
}
```

### 3.3 Long Press Quick Actions

**Agent**: `javascript-package-expert`

#### Implementation

```javascript
// app/javascript/controllers/long_press_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["element"]
  static values = { 
    duration: { type: Number, default: 500 },
    actions: Array
  }

  connect() {
    this.pressTimer = null
    this.isPressed = false
    
    this.elementTarget.addEventListener("touchstart", this.handleTouchStart.bind(this))
    this.elementTarget.addEventListener("touchend", this.handleTouchEnd.bind(this))
    this.elementTarget.addEventListener("touchmove", this.handleTouchMove.bind(this))
  }

  handleTouchStart(e) {
    e.preventDefault()
    this.isPressed = true
    
    // Start haptic feedback timer
    this.pressTimer = setTimeout(() => {
      if (this.isPressed) {
        this.triggerLongPress(e)
      }
    }, this.durationValue)
    
    // Visual feedback
    this.elementTarget.classList.add("long-pressing")
  }

  handleTouchEnd(e) {
    this.cancelLongPress()
  }

  handleTouchMove(e) {
    // Cancel if finger moves too much
    this.cancelLongPress()
  }

  triggerLongPress(e) {
    // Haptic feedback
    if (navigator.vibrate) {
      navigator.vibrate(50)
    }
    
    // Show action menu
    this.showActionMenu(e.touches[0].clientX, e.touches[0].clientY)
  }

  showActionMenu(x, y) {
    const menu = this.createActionMenu()
    document.body.appendChild(menu)
    
    // Position menu
    menu.style.left = `${x}px`
    menu.style.top = `${y}px`
    
    // Animate in
    setTimeout(() => menu.classList.add("visible"), 10)
    
    // Auto-dismiss after delay
    setTimeout(() => this.hideActionMenu(menu), 3000)
  }

  createActionMenu() {
    const menu = document.createElement("div")
    menu.className = "long-press-menu"
    
    this.actionsValue.forEach(action => {
      const button = document.createElement("button")
      button.className = "action-button"
      button.textContent = action.label
      button.addEventListener("click", () => {
        this.executeAction(action)
        this.hideActionMenu(menu)
      })
      menu.appendChild(button)
    })
    
    return menu
  }

  executeAction(action) {
    // Trigger the specified action
    const element = this.elementTarget.querySelector(`[data-action="${action.target}"]`)
    if (element) {
      element.click()
    }
  }

  cancelLongPress() {
    this.isPressed = false
    if (this.pressTimer) {
      clearTimeout(this.pressTimer)
      this.pressTimer = null
    }
    this.elementTarget.classList.remove("long-pressing")
  }
}
```

### 3.4 Haptic Feedback Integration

**Agent**: `javascript-package-expert`

#### Haptic Utility

```javascript
// app/javascript/utils/haptics.js
export class HapticFeedback {
  static isSupported() {
    return 'vibrate' in navigator
  }

  static light() {
    if (this.isSupported()) {
      navigator.vibrate(10)
    }
  }

  static medium() {
    if (this.isSupported()) {
      navigator.vibrate(25)
    }
  }

  static heavy() {
    if (this.isSupported()) {
      navigator.vibrate(50)
    }
  }

  static success() {
    if (this.isSupported()) {
      navigator.vibrate([25, 50, 25])
    }
  }

  static error() {
    if (this.isSupported()) {
      navigator.vibrate([50, 100, 50, 100, 50])
    }
  }

  static selection() {
    this.light()
  }
}
```

### 3.5 Enhanced Touch Feedback

**Agent**: `tailwind-css-expert`

#### CSS for Touch States

```scss
// app/assets/stylesheets/touch_feedback.scss
.touch-target {
  @apply relative overflow-hidden;
  
  // Touch ripple effect
  &::before {
    content: '';
    @apply absolute inset-0 opacity-0 bg-current;
    @apply transition-opacity duration-200 pointer-events-none;
    border-radius: inherit;
  }
  
  &:active::before {
    @apply opacity-10;
  }
  
  // Enhanced touch feedback
  &.touch-feedback-light:active {
    @apply transform scale-95 transition-transform duration-100;
  }
  
  &.touch-feedback-medium:active {
    @apply bg-gray-100 dark:bg-gray-700;
  }
  
  &.touch-feedback-heavy:active {
    @apply shadow-inner transform scale-98;
  }
}

// Button specific feedback
.btn-touch {
  @apply touch-target touch-feedback-medium;
  @apply min-h-[44px] min-w-[44px] flex items-center justify-center;
  
  &:active {
    @apply bg-opacity-80 transform scale-95;
  }
}

// Card touch feedback
.card-touch {
  @apply touch-target touch-feedback-light;
  @apply transition-all duration-200;
  
  &:active {
    @apply shadow-md;
  }
}
```

## Integration with Existing Components

### 3.6 Update Post Cards

**Agent**: `tailwind-css-expert`

Add swipe functionality to post cards:

```erb
<!-- app/views/posts/_post_card.html.erb -->
<%= turbo_frame_tag dom_id(post) do %>
  <div class="post-card card-touch" 
       data-controller="swipe-actions long-press" 
       data-swipe-actions-post-id="<%= post.id %>"
       data-long-press-actions-value='[
         {"label": "Mark as Read", "target": "mark-read"},
         {"label": "Clear", "target": "clear"},
         {"label": "Mark as Responded", "target": "respond"}
       ]'>
    <!-- existing post card content -->
  </div>
<% end %>
```

### 3.7 Add Pull-to-Refresh to Posts Index

**Agent**: `javascript-package-expert`

```erb
<!-- app/views/posts/index.html.erb -->
<div data-controller="pull-to-refresh" 
     data-pull-to-refresh-url-value="<%= request.url %>"
     class="min-h-screen">
  
  <!-- existing content -->
  
</div>
```

## Testing Requirements

### 3.8 Touch Interaction Tests

**Agent**: `test-runner-fixer`

```javascript
// spec/system/touch_interactions_spec.js
describe("Touch Interactions", () => {
  beforeEach(() => {
    cy.viewport("iphone-x")
  })

  it("enables swipe to mark as read", () => {
    cy.visit("/posts")
    cy.get(".post-card").first()
      .trigger("touchstart", { touches: [{ clientX: 100, clientY: 100 }] })
      .trigger("touchmove", { touches: [{ clientX: 200, clientY: 100 }] })
      .trigger("touchend")
    
    cy.get(".post-card").first().should("have.class", "swipe-read")
  })

  it("shows pull-to-refresh indicator", () => {
    cy.visit("/posts")
    cy.get("[data-controller='pull-to-refresh']")
      .trigger("touchstart", { touches: [{ clientX: 100, clientY: 50 }] })
      .trigger("touchmove", { touches: [{ clientX: 100, clientY: 150 }] })
    
    cy.get(".pull-refresh-indicator").should("be.visible")
  })

  it("triggers long press menu", () => {
    cy.visit("/posts")
    cy.get(".post-card").first()
      .trigger("touchstart")
      .wait(600) // longer than long press duration
    
    cy.get(".long-press-menu").should("be.visible")
  })
})
```

### 3.9 Performance Testing

Ensure interactions maintain 60fps:

```javascript
// Performance monitoring
const observer = new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    if (entry.duration > 16.67) { // 60fps threshold
      console.warn("Frame drop detected:", entry)
    }
  }
})

observer.observe({ entryTypes: ["measure"] })
```

## Handoff Protocol

### Completion Checklist
- [ ] Swipe gestures work smoothly
- [ ] Pull-to-refresh functions correctly
- [ ] Long press shows action menu
- [ ] Haptic feedback works on supported devices
- [ ] Touch feedback is responsive
- [ ] Performance maintains 60fps
- [ ] All interactions work with existing functionality

### Handoff Data
```json
{
  "implemented_gestures": [
    "swipe_to_action",
    "pull_to_refresh", 
    "long_press_menu"
  ],
  "haptic_feedback": "enabled",
  "performance_optimized": true,
  "touch_targets_compliant": true,
  "ready_for": "ui_polish_and_testing"
}
```

### Next Agent: `tailwind-css-expert`
Continue with Phase 4: UI Polish & Testing

## Implementation Commands

```bash
# Start touch interactions
Task(description="Implement touch gestures",
     subagent_type="javascript-package-expert",
     prompt="Add swipe gestures, pull-to-refresh, and long press from phase-3-interactions.md.
             Include haptic feedback and performance optimization.")

# Add visual feedback
Task(description="Touch feedback styles",
     subagent_type="tailwind-css-expert", 
     prompt="Add touch feedback CSS and animations.
             Ensure all touch targets meet accessibility requirements.")

# Test interactions
Task(description="Test touch interactions",
     subagent_type="test-runner-fixer",
     prompt="Write comprehensive tests for touch gestures.
             Verify performance and cross-device compatibility.")
```