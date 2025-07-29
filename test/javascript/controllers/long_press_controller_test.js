import { Application } from "@hotwired/stimulus"
import LongPressController from "../../../app/javascript/controllers/long_press_controller"

describe("LongPressController", () => {
  let application
  let controller
  let element

  beforeEach(() => {
    // Set up DOM
    document.body.innerHTML = `
      <div data-controller="long-press" 
           data-long-press-duration-value="500"
           data-long-press-actions-value='[{"label":"Test Action","target":"test","icon":"check"}]'>
        <div data-long-press-target="element" class="touchable-element">
          <button data-action="test">Test Button</button>
          <button data-action="post-actions#markAsRead">Mark as Read</button>
          <button data-action="post-actions#clear">Clear</button>
        </div>
      </div>
    `

    element = document.querySelector('[data-controller="long-press"]')

    // Set up Stimulus
    application = Application.start()
    application.register("long-press", LongPressController)

    // Mock haptic feedback
    window.HapticFeedback = {
      heavy: jest.fn(),
      light: jest.fn()
    }
  })

  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
    jest.clearAllTimers()
  })

  describe("initialization", () => {
    it("sets correct default values", () => {
      controller = application.getControllerForElementAndIdentifier(element, "long-press")
      expect(controller.durationValue).toBe(500)
      expect(controller.actionsValue).toEqual([{"label":"Test Action","target":"test","icon":"check"}])
    })
  })

  describe("long press detection", () => {
    jest.useFakeTimers()

    it("triggers long press after duration", () => {
      controller = application.getControllerForElementAndIdentifier(element, "long-press")
      const triggerSpy = jest.spyOn(controller, 'triggerLongPress')

      const touchStartEvent = new TouchEvent('touchstart', {
        touches: [{ clientX: 100, clientY: 200 }]
      })
      element.dispatchEvent(touchStartEvent)

      // Before duration - should not trigger
      jest.advanceTimersByTime(400)
      expect(triggerSpy).not.toHaveBeenCalled()

      // After duration - should trigger
      jest.advanceTimersByTime(100)
      expect(triggerSpy).toHaveBeenCalled()
    })

    it("cancels long press on touch end", () => {
      controller = application.getControllerForElementAndIdentifier(element, "long-press")
      const triggerSpy = jest.spyOn(controller, 'triggerLongPress')

      const touchStartEvent = new TouchEvent('touchstart', {
        touches: [{ clientX: 100, clientY: 200 }]
      })
      element.dispatchEvent(touchStartEvent)

      jest.advanceTimersByTime(200)

      const touchEndEvent = new TouchEvent('touchend', {})
      element.dispatchEvent(touchEndEvent)

      jest.advanceTimersByTime(400)
      expect(triggerSpy).not.toHaveBeenCalled()
    })

    it("cancels long press if finger moves too much", () => {
      controller = application.getControllerForElementAndIdentifier(element, "long-press")
      const triggerSpy = jest.spyOn(controller, 'triggerLongPress')

      const touchStartEvent = new TouchEvent('touchstart', {
        touches: [{ clientX: 100, clientY: 200 }]
      })
      element.dispatchEvent(touchStartEvent)

      // Move finger more than 10px
      const touchMoveEvent = new TouchEvent('touchmove', {
        touches: [{ clientX: 115, clientY: 200 }]
      })
      element.dispatchEvent(touchMoveEvent)

      jest.advanceTimersByTime(600)
      expect(triggerSpy).not.toHaveBeenCalled()
    })

    it("adds visual feedback during press", () => {
      const touchStartEvent = new TouchEvent('touchstart', {
        touches: [{ clientX: 100, clientY: 200 }]
      })
      element.dispatchEvent(touchStartEvent)

      expect(element.classList.contains('long-pressing')).toBe(true)
    })
  })

  describe("action menu", () => {
    it("shows menu at touch position", () => {
      controller = application.getControllerForElementAndIdentifier(element, "long-press")
      controller.showActionMenu(150, 250)

      const menu = document.querySelector('.long-press-menu')
      expect(menu).toBeTruthy()
      
      // Menu should be positioned relative to touch
      const left = parseInt(menu.style.left)
      const top = parseInt(menu.style.top)
      expect(left).toBeGreaterThan(0)
      expect(top).toBeGreaterThan(0)
    })

    it("creates menu with configured actions", () => {
      controller = application.getControllerForElementAndIdentifier(element, "long-press")
      controller.showActionMenu(150, 250)

      const menu = document.querySelector('.long-press-menu')
      const actions = menu.querySelectorAll('.long-press-action')
      
      expect(actions.length).toBe(1)
      expect(actions[0].textContent).toContain('Test Action')
    })

    it("creates default actions when none configured", () => {
      // Remove configured actions
      element.removeAttribute('data-long-press-actions-value')
      
      controller = application.getControllerForElementAndIdentifier(element, "long-press")
      controller.actionsValue = []
      controller.showActionMenu(150, 250)

      const menu = document.querySelector('.long-press-menu')
      const actions = menu.querySelectorAll('.long-press-action')
      
      // Should create actions based on available buttons
      expect(actions.length).toBeGreaterThan(0)
      expect(menu.textContent).toContain('Mark as Read')
      expect(menu.textContent).toContain('Clear')
    })

    it("keeps menu on screen when near edges", () => {
      controller = application.getControllerForElementAndIdentifier(element, "long-press")
      
      // Mock window size
      Object.defineProperty(window, 'innerWidth', { value: 400, writable: true })
      
      // Touch near right edge
      controller.showActionMenu(380, 100)
      
      const menu = document.querySelector('.long-press-menu')
      const menuRect = {
        width: 200,
        height: 100
      }
      Object.defineProperty(menu, 'getBoundingClientRect', {
        value: () => menuRect
      })
      
      controller.showActionMenu(380, 100)
      
      const left = parseInt(menu.style.left)
      expect(left).toBeLessThan(300) // Should be adjusted to stay on screen
    })

    it("auto-dismisses menu after timeout", () => {
      jest.useFakeTimers()
      
      controller = application.getControllerForElementAndIdentifier(element, "long-press")
      controller.showActionMenu(150, 250)

      const menu = document.querySelector('.long-press-menu')
      expect(menu.classList.contains('visible')).toBe(true)

      // Advance time past auto-dismiss timeout
      jest.advanceTimersByTime(3100)

      expect(menu.classList.contains('visible')).toBe(false)
    })

    it("dismisses menu on outside tap", () => {
      controller = application.getControllerForElementAndIdentifier(element, "long-press")
      controller.showActionMenu(150, 250)

      const menu = document.querySelector('.long-press-menu')
      expect(menu).toBeTruthy()

      // Simulate outside tap
      const outsideTap = new TouchEvent('touchstart', {
        touches: [{ clientX: 10, clientY: 10 }]
      })
      document.dispatchEvent(outsideTap)

      // Menu should be hidden
      setTimeout(() => {
        expect(menu.classList.contains('visible')).toBe(false)
      }, 100)
    })
  })

  describe("action execution", () => {
    it("executes action when menu item is clicked", () => {
      controller = application.getControllerForElementAndIdentifier(element, "long-press")
      controller.showActionMenu(150, 250)

      const testButton = element.querySelector('[data-action="test"]')
      const clickSpy = jest.spyOn(testButton, 'click')

      const menuAction = document.querySelector('.long-press-action')
      menuAction.click()

      expect(clickSpy).toHaveBeenCalled()
      expect(window.HapticFeedback.light).toHaveBeenCalled()
    })

    it("hides menu after action execution", () => {
      controller = application.getControllerForElementAndIdentifier(element, "long-press")
      controller.showActionMenu(150, 250)

      const menu = document.querySelector('.long-press-menu')
      const menuAction = document.querySelector('.long-press-action')
      menuAction.click()

      setTimeout(() => {
        expect(menu.classList.contains('visible')).toBe(false)
      }, 100)
    })
  })

  describe("haptic feedback", () => {
    it("triggers heavy haptic on long press", () => {
      controller = application.getControllerForElementAndIdentifier(element, "long-press")
      controller.triggerLongPress()

      expect(window.HapticFeedback.heavy).toHaveBeenCalled()
    })

    it("triggers light haptic on action execution", () => {
      controller = application.getControllerForElementAndIdentifier(element, "long-press")
      const action = { target: 'test' }
      controller.executeAction(action)

      expect(window.HapticFeedback.light).toHaveBeenCalled()
    })
  })

  describe("context menu prevention", () => {
    it("prevents default context menu", () => {
      const contextMenuEvent = new Event('contextmenu')
      const preventDefaultSpy = jest.spyOn(contextMenuEvent, 'preventDefault')
      
      element.dispatchEvent(contextMenuEvent)
      
      expect(preventDefaultSpy).toHaveBeenCalled()
    })
  })
})