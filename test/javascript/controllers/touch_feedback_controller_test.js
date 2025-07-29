import { Application } from "@hotwired/stimulus"
import TouchFeedbackController from "../../../app/javascript/controllers/touch_feedback_controller"

// Mock the ripple utility
jest.mock("../../../app/javascript/utils/ripple", () => ({
  addRippleEffect: jest.fn(() => jest.fn())
}))

import { addRippleEffect } from "../../../app/javascript/utils/ripple"

describe("TouchFeedbackController", () => {
  let application
  let controller
  let element

  beforeEach(() => {
    // Set up DOM
    document.body.innerHTML = `
      <button data-controller="touch-feedback" 
              data-touch-feedback-haptic-value="medium"
              data-touch-feedback-ripple-value="true">
        Click Me
      </button>
    `

    element = document.querySelector('[data-controller="touch-feedback"]')

    // Set up Stimulus
    application = Application.start()
    application.register("touch-feedback", TouchFeedbackController)

    // Mock haptic feedback
    window.HapticFeedback = {
      light: jest.fn(),
      medium: jest.fn(),
      heavy: jest.fn(),
      selection: jest.fn()
    }

    // Mark as touch device
    Object.defineProperty(window, 'ontouchstart', {
      value: () => {},
      configurable: true
    })
  })

  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
    jest.clearAllMocks()
  })

  describe("initialization", () => {
    it("sets up ripple effect when enabled", () => {
      expect(addRippleEffect).toHaveBeenCalledWith(element)
    })

    it("respects ripple configuration", () => {
      document.body.innerHTML = `
        <button data-controller="touch-feedback" 
                data-touch-feedback-ripple-value="false">
          No Ripple
        </button>
      `
      
      const noRippleElement = document.querySelector('[data-controller="touch-feedback"]')
      application.stop()
      
      jest.clearAllMocks()
      application = Application.start()
      application.register("touch-feedback", TouchFeedbackController)
      
      expect(addRippleEffect).not.toHaveBeenCalled()
    })

    it("sets correct default values", () => {
      controller = application.getControllerForElementAndIdentifier(element, "touch-feedback")
      expect(controller.hapticValue).toBe("medium")
      expect(controller.rippleValue).toBe(true)
    })
  })

  describe("touch feedback", () => {
    it("adds visual feedback class on touch start", () => {
      const touchStartEvent = new TouchEvent('touchstart', {
        touches: [{ clientX: 50, clientY: 50 }]
      })
      element.dispatchEvent(touchStartEvent)

      expect(element.classList.contains('touching')).toBe(true)
    })

    it("removes visual feedback class on touch end", () => {
      const touchStartEvent = new TouchEvent('touchstart', {
        touches: [{ clientX: 50, clientY: 50 }]
      })
      element.dispatchEvent(touchStartEvent)

      const touchEndEvent = new TouchEvent('touchend', {})
      element.dispatchEvent(touchEndEvent)

      expect(element.classList.contains('touching')).toBe(false)
    })

    it("removes visual feedback class on touch cancel", () => {
      const touchStartEvent = new TouchEvent('touchstart', {
        touches: [{ clientX: 50, clientY: 50 }]
      })
      element.dispatchEvent(touchStartEvent)

      const touchCancelEvent = new TouchEvent('touchcancel', {})
      element.dispatchEvent(touchCancelEvent)

      expect(element.classList.contains('touching')).toBe(false)
    })
  })

  describe("haptic feedback", () => {
    it("triggers light haptic by default", () => {
      document.body.innerHTML = `
        <button data-controller="touch-feedback">Light Haptic</button>
      `
      
      const lightElement = document.querySelector('[data-controller="touch-feedback"]')
      application.register("touch-feedback", TouchFeedbackController)

      const touchStartEvent = new TouchEvent('touchstart', {
        touches: [{ clientX: 50, clientY: 50 }]
      })
      lightElement.dispatchEvent(touchStartEvent)

      expect(window.HapticFeedback.light).toHaveBeenCalled()
    })

    it("triggers medium haptic when configured", () => {
      const touchStartEvent = new TouchEvent('touchstart', {
        touches: [{ clientX: 50, clientY: 50 }]
      })
      element.dispatchEvent(touchStartEvent)

      expect(window.HapticFeedback.medium).toHaveBeenCalled()
    })

    it("triggers heavy haptic when configured", () => {
      document.body.innerHTML = `
        <button data-controller="touch-feedback" 
                data-touch-feedback-haptic-value="heavy">
          Heavy Haptic
        </button>
      `
      
      const heavyElement = document.querySelector('[data-controller="touch-feedback"]')
      application.register("touch-feedback", TouchFeedbackController)

      const touchStartEvent = new TouchEvent('touchstart', {
        touches: [{ clientX: 50, clientY: 50 }]
      })
      heavyElement.dispatchEvent(touchStartEvent)

      expect(window.HapticFeedback.heavy).toHaveBeenCalled()
    })

    it("triggers selection haptic on click for touch devices", () => {
      const clickEvent = new MouseEvent('click', {
        bubbles: true,
        cancelable: true,
        isTrusted: true
      })
      element.dispatchEvent(clickEvent)

      expect(window.HapticFeedback.selection).toHaveBeenCalled()
    })

    it("does not trigger haptic on non-touch devices", () => {
      // Remove touch support
      delete window.ontouchstart

      const clickEvent = new MouseEvent('click', {
        bubbles: true,
        cancelable: true,
        isTrusted: true
      })
      element.dispatchEvent(clickEvent)

      expect(window.HapticFeedback.selection).not.toHaveBeenCalled()
    })
  })

  describe("cleanup", () => {
    it("removes ripple effect on disconnect", () => {
      const removeRipple = jest.fn()
      addRippleEffect.mockReturnValue(removeRipple)

      // Create new controller to get mocked removeRipple
      document.body.innerHTML = `
        <button data-controller="touch-feedback">Test</button>
      `
      const newElement = document.querySelector('[data-controller="touch-feedback"]')
      application.register("touch-feedback", TouchFeedbackController)
      
      const controller = application.getControllerForElementAndIdentifier(newElement, "touch-feedback")
      controller.disconnect()

      expect(removeRipple).toHaveBeenCalled()
    })
  })
})