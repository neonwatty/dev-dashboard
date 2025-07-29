import { Application } from "@hotwired/stimulus"
import SwipeActionsController from "../../../app/javascript/controllers/swipe_actions_controller"

describe("SwipeActionsController", () => {
  let application
  let controller
  let element
  let cardElement

  beforeEach(() => {
    // Set up DOM
    document.body.innerHTML = `
      <div data-controller="swipe-actions" 
           data-swipe-actions-threshold-value="100"
           data-swipe-actions-max-swipe-value="200">
        <div data-swipe-actions-target="card" class="post-card">
          <button data-action="post-actions#markAsRead">Mark as Read</button>
          <button data-action="post-actions#clear">Clear</button>
        </div>
      </div>
    `

    element = document.querySelector('[data-controller="swipe-actions"]')
    cardElement = document.querySelector('[data-swipe-actions-target="card"]')

    // Set up Stimulus
    application = Application.start()
    application.register("swipe-actions", SwipeActionsController)
  })

  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })

  describe("initialization", () => {
    it("sets up swipe indicators", () => {
      // Wait for controller to connect
      setTimeout(() => {
        expect(document.querySelector('.swipe-indicator-left')).toBeTruthy()
        expect(document.querySelector('.swipe-indicator-right')).toBeTruthy()
      }, 100)
    })

    it("initializes with correct default values", () => {
      controller = application.getControllerForElementAndIdentifier(element, "swipe-actions")
      expect(controller.thresholdValue).toBe(100)
      expect(controller.maxSwipeValue).toBe(200)
    })
  })

  describe("touch handling", () => {
    it("tracks touch start position", () => {
      const touchStartEvent = new TouchEvent('touchstart', {
        touches: [{ clientX: 100, clientY: 200 }]
      })
      
      cardElement.dispatchEvent(touchStartEvent)
      
      controller = application.getControllerForElementAndIdentifier(element, "swipe-actions")
      expect(controller.initialX).toBe(100)
      expect(controller.isDragging).toBe(true)
    })

    it("updates position during touch move", () => {
      // Start touch
      const touchStartEvent = new TouchEvent('touchstart', {
        touches: [{ clientX: 100, clientY: 200 }]
      })
      cardElement.dispatchEvent(touchStartEvent)

      // Move touch
      const touchMoveEvent = new TouchEvent('touchmove', {
        touches: [{ clientX: 150, clientY: 200 }]
      })
      cardElement.dispatchEvent(touchMoveEvent)

      // Check transform
      const transform = cardElement.style.transform
      expect(transform).toContain('translateX(50px)')
    })

    it("constrains swipe distance to max value", () => {
      // Start touch
      const touchStartEvent = new TouchEvent('touchstart', {
        touches: [{ clientX: 100, clientY: 200 }]
      })
      cardElement.dispatchEvent(touchStartEvent)

      // Move beyond max distance
      const touchMoveEvent = new TouchEvent('touchmove', {
        touches: [{ clientX: 400, clientY: 200 }]
      })
      cardElement.dispatchEvent(touchMoveEvent)

      // Transform should be capped at max value
      const transform = cardElement.style.transform
      expect(transform).toContain('translateX(200px)')
    })

    it("executes action when threshold is met", () => {
      const markAsReadButton = document.querySelector('[data-action*="markAsRead"]')
      const clickSpy = jest.spyOn(markAsReadButton, 'click')

      // Simulate full swipe right
      const touchStartEvent = new TouchEvent('touchstart', {
        touches: [{ clientX: 100, clientY: 200 }]
      })
      cardElement.dispatchEvent(touchStartEvent)

      const touchMoveEvent = new TouchEvent('touchmove', {
        touches: [{ clientX: 220, clientY: 200 }]
      })
      cardElement.dispatchEvent(touchMoveEvent)

      const touchEndEvent = new TouchEvent('touchend', {})
      cardElement.dispatchEvent(touchEndEvent)

      // Should trigger button click after animation
      setTimeout(() => {
        expect(clickSpy).toHaveBeenCalled()
      }, 200)
    })

    it("resets card position if threshold not met", () => {
      // Simulate partial swipe
      const touchStartEvent = new TouchEvent('touchstart', {
        touches: [{ clientX: 100, clientY: 200 }]
      })
      cardElement.dispatchEvent(touchStartEvent)

      const touchMoveEvent = new TouchEvent('touchmove', {
        touches: [{ clientX: 150, clientY: 200 }]
      })
      cardElement.dispatchEvent(touchMoveEvent)

      const touchEndEvent = new TouchEvent('touchend', {})
      cardElement.dispatchEvent(touchEndEvent)

      // Card should reset
      setTimeout(() => {
        expect(cardElement.style.transform).toBe('')
      }, 100)
    })
  })

  describe("visual indicators", () => {
    it("shows left indicator when swiping right", () => {
      controller = application.getControllerForElementAndIdentifier(element, "swipe-actions")
      controller.updateSwipeVisuals(50)

      const leftIndicator = document.querySelector('.swipe-indicator-left')
      expect(leftIndicator.style.opacity).toBe('0.5')
    })

    it("shows right indicator when swiping left", () => {
      controller = application.getControllerForElementAndIdentifier(element, "swipe-actions")
      controller.updateSwipeVisuals(-50)

      const rightIndicator = document.querySelector('.swipe-indicator-right')
      expect(rightIndicator.style.opacity).toBe('0.5')
    })

    it("adds active class when threshold is reached", () => {
      controller = application.getControllerForElementAndIdentifier(element, "swipe-actions")
      controller.updateSwipeVisuals(100)

      const leftIndicator = document.querySelector('.swipe-indicator-left')
      expect(leftIndicator.classList.contains('active')).toBe(true)
    })
  })

  describe("haptic feedback", () => {
    it("triggers haptic feedback at threshold", () => {
      // Mock haptic feedback
      window.HapticFeedback = {
        light: jest.fn()
      }

      controller = application.getControllerForElementAndIdentifier(element, "swipe-actions")
      
      // Below threshold - no haptic
      controller.checkActionTriggers(50)
      expect(window.HapticFeedback.light).not.toHaveBeenCalled()

      // At threshold - trigger haptic
      controller.checkActionTriggers(100)
      expect(window.HapticFeedback.light).toHaveBeenCalled()
    })
  })
})