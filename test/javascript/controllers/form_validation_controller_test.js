/**
 * @jest-environment jsdom
 */

import { Application } from "@hotwired/stimulus"
import FormValidationController from "../../../app/javascript/controllers/form_validation_controller"

describe("FormValidationController", () => {
  let application
  let container

  beforeEach(() => {
    application = Application.start()
    application.register("form-validation", FormValidationController)
    
    container = document.createElement("div")
    document.body.appendChild(container)
  })

  afterEach(() => {
    application.stop()
    document.body.removeChild(container)
  })

  describe("email validation", () => {
    beforeEach(() => {
      container.innerHTML = `
        <div data-controller="form-validation">
          <input type="email" data-form-validation-target="email" id="email-input">
          <div data-form-validation-target="emailError" id="email-error"></div>
          <input type="checkbox" data-form-validation-target="rememberMe" id="remember-me">
        </div>
      `
    })

    it("validates email format correctly", () => {
      const emailInput = container.querySelector("#email-input")
      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector("[data-controller]"), 
        "form-validation"
      )

      // Test valid email
      emailInput.value = "test@example.com"
      controller.validateEmail()
      expect(emailInput.getAttribute("aria-invalid")).toBe("false")

      // Test invalid email
      emailInput.value = "invalid-email"
      controller.validateEmail()
      expect(emailInput.getAttribute("aria-invalid")).toBe("true")
    })

    it("shows error messages for invalid emails", () => {
      const emailInput = container.querySelector("#email-input")
      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector("[data-controller]"), 
        "form-validation"
      )

      emailInput.value = "invalid-email"
      controller.validateEmail()

      // Should show error message
      const errorElement = container.querySelector("#email-validation-message")
      expect(errorElement).toBeTruthy()
      expect(errorElement.textContent).toContain("valid email address")
    })

    it("clears validation when email is empty", () => {
      const emailInput = container.querySelector("#email-input")
      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector("[data-controller]"), 
        "form-validation"
      )

      // Set invalid email first
      emailInput.value = "invalid-email"
      controller.validateEmail()
      expect(emailInput.getAttribute("aria-invalid")).toBe("true")

      // Clear email
      emailInput.value = ""
      controller.validateEmail()
      expect(emailInput.getAttribute("aria-invalid")).toBe("false")
    })

    it("validates complex email formats", () => {
      const emailInput = container.querySelector("#email-input")
      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector("[data-controller]"), 
        "form-validation"
      )

      const validEmails = [
        "user@example.com",
        "user.name@example.com",
        "user+tag@example.com",
        "user123@example-site.com",
        "test@sub.example.co.uk"
      ]

      const invalidEmails = [
        "plainaddress",
        "@missinglocal.com",
        "missing@.com",
        "missing@domain",
        "spaces @example.com",
        "user@",
        "user..double.dot@example.com"
      ]

      validEmails.forEach(email => {
        emailInput.value = email
        controller.validateEmail()
        expect(emailInput.getAttribute("aria-invalid")).toBe("false")
      })

      invalidEmails.forEach(email => {
        emailInput.value = email
        controller.validateEmail()
        expect(emailInput.getAttribute("aria-invalid")).toBe("true")
      })
    })
  })

  describe("remember me functionality", () => {
    beforeEach(() => {
      localStorage.clear()
      container.innerHTML = `
        <div data-controller="form-validation" data-form-validation-show-remember-me-value="true">
          <input type="email" data-form-validation-target="email" id="email-input">
          <input type="checkbox" data-form-validation-target="rememberMe" id="remember-me">
        </div>
      `
    })

    it("loads saved remember me preference", () => {
      localStorage.setItem("rememberMe", "true")
      
      // Re-create controller to test loading
      container.innerHTML = `
        <div data-controller="form-validation" data-form-validation-show-remember-me-value="true">
          <input type="email" data-form-validation-target="email" id="email-input">
          <input type="checkbox" data-form-validation-target="rememberMe" id="remember-me">
        </div>
      `

      const rememberMeInput = container.querySelector("#remember-me")
      expect(rememberMeInput.checked).toBe(true)
    })

    it("saves remember me preference when changed", () => {
      const rememberMeInput = container.querySelector("#remember-me")
      
      rememberMeInput.checked = true
      rememberMeInput.dispatchEvent(new Event("change"))
      
      expect(localStorage.getItem("rememberMe")).toBe("true")
      
      rememberMeInput.checked = false
      rememberMeInput.dispatchEvent(new Event("change"))
      
      expect(localStorage.getItem("rememberMe")).toBe("false")
    })
  })

  describe("form submission validation", () => {
    beforeEach(() => {
      container.innerHTML = `
        <form data-controller="form-validation">
          <input type="email" data-form-validation-target="email" id="email-input" required>
          <button type="submit">Submit</button>
        </form>
      `
    })

    it("prevents submission with invalid email", () => {
      const form = container.querySelector("form")
      const emailInput = container.querySelector("#email-input")
      const controller = application.getControllerForElementAndIdentifier(form, "form-validation")

      emailInput.value = "invalid-email"
      
      const submitEvent = new Event("submit", { cancelable: true })
      const result = controller.validateBeforeSubmit(submitEvent)

      expect(result).toBe(false)
      expect(submitEvent.defaultPrevented).toBe(true)
    })

    it("allows submission with valid email", () => {
      const form = container.querySelector("form")
      const emailInput = container.querySelector("#email-input")
      const controller = application.getControllerForElementAndIdentifier(form, "form-validation")

      emailInput.value = "test@example.com"
      
      const submitEvent = new Event("submit", { cancelable: true })
      const result = controller.validateBeforeSubmit(submitEvent)

      expect(result).toBe(true)
      expect(submitEvent.defaultPrevented).toBe(false)
    })
  })

  describe("accessibility", () => {
    beforeEach(() => {
      container.innerHTML = `
        <div data-controller="form-validation">
          <input type="email" data-form-validation-target="email" id="email-input">
        </div>
      `
    })

    it("sets proper ARIA attributes", () => {
      const emailInput = container.querySelector("#email-input")
      
      expect(emailInput.getAttribute("aria-describedby")).toBe("email-validation-message")
    })

    it("announces validation failures", () => {
      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector("[data-controller]"), 
        "form-validation"
      )

      controller.announceValidationFailure()
      
      const liveRegion = document.getElementById("form-validation-announcements")
      expect(liveRegion).toBeTruthy()
      expect(liveRegion.getAttribute("aria-live")).toBe("assertive")
      expect(liveRegion.textContent).toContain("correct the validation errors")
    })
  })
})