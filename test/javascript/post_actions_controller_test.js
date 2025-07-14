// test/javascript/post_actions_controller_test.js
import { Application } from "@hotwired/stimulus"
import PostActionsController from "../../app/javascript/controllers/post_actions_controller"

describe("PostActionsController", () => {
  let application
  let element
  
  beforeEach(() => {
    // Set up DOM
    document.body.innerHTML = `
      <div id="notifications"></div>
      <div id="post-count">Posts: 10</div>
      
      <turbo-frame id="post_1">
        <div data-controller="post-actions" data-post-actions-target="card">
          <span data-status-badge>Unread</span>
          <div data-post-actions-target="buttons">
            <button data-action="click->post-actions#markAsRead" 
                    data-url="/posts/1/mark_as_read"
                    data-post-actions-target="readButton">
              Read
            </button>
            <button data-action="click->post-actions#clear" 
                    data-url="/posts/1/mark_as_ignored"
                    data-post-actions-target="clearButton">
              Clear
            </button>
            <button data-action="click->post-actions#markAsResponded" 
                    data-url="/posts/1/mark_as_responded"
                    data-post-actions-target="respondButton">
              Respond
            </button>
          </div>
        </div>
      </turbo-frame>
      
      <meta name="csrf-token" content="test-token">
    `
    
    // Start Stimulus
    application = Application.start()
    application.register("post-actions", PostActionsController)
    
    element = document.querySelector('[data-controller="post-actions"]')
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ''
  })
  
  describe("initialization", () => {
    it("connects to the controller", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "post-actions")
      expect(controller).toBeTruthy()
    })
    
    it("finds all targets", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "post-actions")
      expect(controller.hasCardTarget).toBe(true)
      expect(controller.hasButtonsTarget).toBe(true)
      expect(controller.hasReadButtonTarget).toBe(true)
      expect(controller.hasClearButtonTarget).toBe(true)
      expect(controller.hasRespondButtonTarget).toBe(true)
    })
  })
  
  describe("csrfToken", () => {
    it("retrieves CSRF token from meta tag", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "post-actions")
      expect(controller.csrfToken).toBe("test-token")
    })
  })
  
  describe("setLoadingState", () => {
    it("shows spinner when loading", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "post-actions")
      const button = controller.clearButtonTarget
      
      controller.setLoadingState(button, true)
      
      expect(button.disabled).toBe(true)
      expect(button.classList.contains('opacity-50')).toBe(true)
      expect(button.innerHTML).toContain('animate-spin')
    })
    
    it("restores original content when not loading", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "post-actions")
      const button = controller.clearButtonTarget
      const originalHTML = button.innerHTML
      
      controller.setLoadingState(button, true)
      controller.setLoadingState(button, false)
      
      expect(button.disabled).toBe(false)
      expect(button.classList.contains('opacity-50')).toBe(false)
      expect(button.innerHTML).toBe(originalHTML)
    })
  })
  
  describe("updateStatusBadge", () => {
    it("updates badge text and styling for read status", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "post-actions")
      controller.updateStatusBadge('read')
      
      const badge = element.querySelector('[data-status-badge]')
      expect(badge.textContent).toBe('Read')
      expect(badge.classList.contains('bg-green-100')).toBe(true)
      expect(badge.classList.contains('text-green-800')).toBe(true)
    })
    
    it("updates badge text and styling for responded status", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "post-actions")
      controller.updateStatusBadge('responded')
      
      const badge = element.querySelector('[data-status-badge]')
      expect(badge.textContent).toBe('Responded')
      expect(badge.classList.contains('bg-blue-100')).toBe(true)
      expect(badge.classList.contains('text-blue-800')).toBe(true)
    })
  })
  
  describe("updatePostCount", () => {
    it("decrements post count", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "post-actions")
      controller.updatePostCount()
      
      const postCount = document.getElementById('post-count')
      expect(postCount.textContent).toBe('Posts: 9')
    })
  })
  
  describe("removeCard", () => {
    it("adds fade out animation", (done) => {
      const controller = application.getControllerForElementAndIdentifier(element, "post-actions")
      controller.removeCard()
      
      const card = controller.cardTarget
      expect(card.style.opacity).toBe('0')
      expect(card.style.transform).toBe('translateX(-20px)')
      
      // Check that element is removed after animation
      setTimeout(() => {
        expect(document.querySelector('turbo-frame#post_1')).toBe(null)
        done()
      }, 400)
    })
  })
  
  describe("error handling", () => {
    it("shows error notification when showError is called", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "post-actions")
      controller.showError('Test error message')
      
      const notification = document.querySelector('[data-controller="notification"]')
      expect(notification).toBeTruthy()
      expect(notification.textContent).toContain('Test error message')
      expect(notification.classList.contains('bg-red-100')).toBe(true)
    })
  })
})

// Note: Full integration tests with fetch() would require mocking or a test server
// These tests focus on the DOM manipulation and controller logic