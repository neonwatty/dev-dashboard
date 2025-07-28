import { Application } from "@hotwired/stimulus"
import PullToRefreshController from "../../../app/javascript/controllers/pull_to_refresh_controller"

describe("PullToRefreshController", () => {
  let application
  let controller
  let element

  beforeEach(() => {
    // Set up DOM
    document.body.innerHTML = `
      <div data-controller="pull-to-refresh" 
           data-pull-to-refresh-threshold-value="80"
           data-pull-to-refresh-url-value="/posts">
        <div data-pull-to-refresh-target="container">
          <div class="content">Content here</div>
        </div>
      </div>
    `

    element = document.querySelector('[data-controller="pull-to-refresh"]')

    // Set up Stimulus
    application = Application.start()
    application.register("pull-to-refresh", PullToRefreshController)

    // Mock window.scrollY
    Object.defineProperty(window, 'scrollY', {
      writable: true,
      value: 0
    })
  })

  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })

  describe("initialization", () => {
    it("creates refresh indicator", (done) => {
      setTimeout(() => {
        const indicator = document.querySelector('.pull-refresh-indicator')
        expect(indicator).toBeTruthy()
        expect(indicator.style.transform).toContain('translateY(-60px)')
        expect(indicator.style.opacity).toBe('0')
        done()
      }, 100)
    })

    it("sets correct default values", () => {
      controller = application.getControllerForElementAndIdentifier(element, "pull-to-refresh")
      expect(controller.thresholdValue).toBe(80)
      expect(controller.urlValue).toBe('/posts')
    })
  })

  describe("pull detection", () => {
    it("only activates when at top of page", () => {
      controller = application.getControllerForElementAndIdentifier(element, "pull-to-refresh")
      
      // Simulate being scrolled down
      window.scrollY = 100
      
      const touchStartEvent = new TouchEvent('touchstart', {
        touches: [{ clientX: 100, clientY: 100 }]
      })
      element.dispatchEvent(touchStartEvent)

      const touchMoveEvent = new TouchEvent('touchmove', {
        touches: [{ clientX: 100, clientY: 150 }]
      })
      element.dispatchEvent(touchMoveEvent)

      // Should not activate pull
      expect(controller.isPulling).toBe(false)
    })

    it("activates when pulling down at top of page", () => {
      controller = application.getControllerForElementAndIdentifier(element, "pull-to-refresh")
      
      // At top of page
      window.scrollY = 0
      
      const touchStartEvent = new TouchEvent('touchstart', {
        touches: [{ clientX: 100, clientY: 100 }]
      })
      element.dispatchEvent(touchStartEvent)

      const touchMoveEvent = new TouchEvent('touchmove', {
        touches: [{ clientX: 100, clientY: 150 }]
      })
      element.dispatchEvent(touchMoveEvent)

      expect(controller.isPulling).toBe(true)
    })
  })

  describe("visual feedback", () => {
    it("updates indicator position based on pull distance", (done) => {
      setTimeout(() => {
        controller = application.getControllerForElementAndIdentifier(element, "pull-to-refresh")
        const indicator = document.querySelector('.pull-refresh-indicator')
        
        controller.updatePullIndicator(40)
        
        expect(indicator.style.transform).toContain('translateY(20px)')
        expect(indicator.style.opacity).toBe('0.5')
        done()
      }, 100)
    })

    it("adds ready class when threshold is reached", (done) => {
      setTimeout(() => {
        controller = application.getControllerForElementAndIdentifier(element, "pull-to-refresh")
        const indicator = document.querySelector('.pull-refresh-indicator')
        
        controller.updatePullIndicator(80)
        
        expect(indicator.classList.contains('ready')).toBe(true)
        done()
      }, 100)
    })

    it("rotates indicator during pull", (done) => {
      setTimeout(() => {
        controller = application.getControllerForElementAndIdentifier(element, "pull-to-refresh")
        const indicator = document.querySelector('.pull-refresh-indicator')
        
        controller.updatePullIndicator(40)
        
        expect(indicator.style.transform).toContain('rotate(90deg)')
        done()
      }, 100)
    })
  })

  describe("refresh trigger", () => {
    beforeEach(() => {
      // Mock fetch
      global.fetch = jest.fn(() =>
        Promise.resolve({
          ok: true,
          text: () => Promise.resolve('<turbo-stream action="append" target="posts"></turbo-stream>')
        })
      )

      // Mock Turbo
      window.Turbo = {
        renderStreamMessage: jest.fn()
      }
    })

    it("triggers refresh when threshold is met", () => {
      controller = application.getControllerForElementAndIdentifier(element, "pull-to-refresh")
      
      // Simulate pull past threshold
      const touchStartEvent = new TouchEvent('touchstart', {
        touches: [{ clientX: 100, clientY: 100 }]
      })
      element.dispatchEvent(touchStartEvent)

      controller.currentY = 180
      const touchEndEvent = new TouchEvent('touchend', {})
      element.dispatchEvent(touchEndEvent)

      expect(global.fetch).toHaveBeenCalledWith('/posts', expect.objectContaining({
        headers: expect.objectContaining({
          'Accept': 'text/vnd.turbo-stream.html'
        })
      }))
    })

    it("does not trigger refresh when below threshold", () => {
      controller = application.getControllerForElementAndIdentifier(element, "pull-to-refresh")
      
      // Simulate pull below threshold
      const touchStartEvent = new TouchEvent('touchstart', {
        touches: [{ clientX: 100, clientY: 100 }]
      })
      element.dispatchEvent(touchStartEvent)

      controller.currentY = 140
      const touchEndEvent = new TouchEvent('touchend', {})
      element.dispatchEvent(touchEndEvent)

      expect(global.fetch).not.toHaveBeenCalled()
    })

    it("shows loading state during refresh", (done) => {
      controller = application.getControllerForElementAndIdentifier(element, "pull-to-refresh")
      controller.triggerRefresh()

      setTimeout(() => {
        const indicator = document.querySelector('.pull-refresh-indicator')
        expect(indicator.classList.contains('refreshing')).toBe(true)
        expect(document.querySelector('.animate-spin')).toBeTruthy()
        done()
      }, 100)
    })

    it("handles successful refresh", async () => {
      controller = application.getControllerForElementAndIdentifier(element, "pull-to-refresh")
      
      await controller.triggerRefresh()
      
      // Wait for completion
      await new Promise(resolve => setTimeout(resolve, 600))
      
      expect(window.Turbo.renderStreamMessage).toHaveBeenCalled()
    })

    it("handles failed refresh", async () => {
      // Mock failed fetch
      global.fetch = jest.fn(() => Promise.reject(new Error('Network error')))
      
      controller = application.getControllerForElementAndIdentifier(element, "pull-to-refresh")
      
      await controller.triggerRefresh()
      
      // Wait for completion
      await new Promise(resolve => setTimeout(resolve, 600))
      
      const indicator = document.querySelector('.pull-refresh-indicator')
      expect(indicator.classList.contains('error')).toBe(false) // Should be removed after timeout
    })
  })

  describe("haptic feedback", () => {
    beforeEach(() => {
      window.HapticFeedback = {
        light: jest.fn(),
        success: jest.fn(),
        error: jest.fn()
      }
    })

    it("triggers haptic when ready", (done) => {
      setTimeout(() => {
        controller = application.getControllerForElementAndIdentifier(element, "pull-to-refresh")
        controller.updatePullIndicator(80)
        
        expect(window.HapticFeedback.light).toHaveBeenCalled()
        done()
      }, 100)
    })

    it("triggers success haptic on successful refresh", async () => {
      controller = application.getControllerForElementAndIdentifier(element, "pull-to-refresh")
      controller.completeRefresh(true)
      
      expect(window.HapticFeedback.success).toHaveBeenCalled()
    })

    it("triggers error haptic on failed refresh", async () => {
      controller = application.getControllerForElementAndIdentifier(element, "pull-to-refresh")
      controller.completeRefresh(false)
      
      expect(window.HapticFeedback.error).toHaveBeenCalled()
    })
  })
})