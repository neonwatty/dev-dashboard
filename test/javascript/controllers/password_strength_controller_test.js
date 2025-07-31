/**
 * @jest-environment jsdom
 */

import { Application } from "@hotwired/stimulus"
import PasswordStrengthController from "../../../app/javascript/controllers/password_strength_controller"

describe("PasswordStrengthController", () => {
  let application
  let container

  beforeEach(() => {
    application = Application.start()
    application.register("password-strength", PasswordStrengthController)
    
    container = document.createElement("div")
    document.body.appendChild(container)
  })

  afterEach(() => {
    application.stop()
    document.body.removeChild(container)
  })

  describe("password strength calculation", () => {
    beforeEach(() => {
      container.innerHTML = `
        <div data-controller="password-strength">
          <input type="password" data-password-strength-target="password" id="password-input">
          <input type="password" data-password-strength-target="passwordConfirm" id="password-confirm-input">
        </div>
      `
    })

    it("calculates strength for various passwords", () => {
      const passwordInput = container.querySelector("#password-input")
      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector("[data-controller]"), 
        "password-strength"
      )

      const testCases = [
        { password: "", expectedLevel: "none" },
        { password: "123", expectedLevel: "weak" },
        { password: "password", expectedLevel: "weak" },
        { password: "Password1", expectedLevel: "fair" },
        { password: "Password123!", expectedLevel: "strong" },
        { password: "MyVerySecureP@ssw0rd2024!", expectedLevel: "excellent" }
      ]

      testCases.forEach(({ password, expectedLevel }) => {
        const strength = controller.calculatePasswordStrength(password)
        expect(strength.level).toBe(expectedLevel)
      })
    })

    it("penalizes common passwords", () => {
      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector("[data-controller]"), 
        "password-strength"
      )

      const commonPassword = controller.calculatePasswordStrength("password123")
      const uniquePassword = controller.calculatePasswordStrength("MyUnique123!")

      expect(commonPassword.score).toBeLessThan(uniquePassword.score)
    })

    it("penalizes repeated characters", () => {
      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector("[data-controller]"), 
        "password-strength"
      )

      const repeatedPassword = controller.calculatePasswordStrength("Passssword123!")
      const normalPassword = controller.calculatePasswordStrength("Password123!")

      expect(repeatedPassword.score).toBeLessThan(normalPassword.score)
    })

    it("rewards character variety", () => {
      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector("[data-controller]"), 
        "password-strength"
      )

      const varied = controller.calculatePasswordStrength("MyPassword123!")
      const simple = controller.calculatePasswordStrength("mypassword")

      expect(varied.score).toBeGreaterThan(simple.score)
    })
  })

  describe("password confirmation", () => {
    beforeEach(() => {
      container.innerHTML = `
        <div data-controller="password-strength">
          <input type="password" data-password-strength-target="password" id="password-input">
          <input type="password" data-password-strength-target="passwordConfirm" id="password-confirm-input">
        </div>
      `
    })

    it("validates password confirmation matches", () => {
      const passwordInput = container.querySelector("#password-input")
      const confirmInput = container.querySelector("#password-confirm-input")
      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector("[data-controller]"), 
        "password-strength"
      )

      passwordInput.value = "TestPassword123!"
      confirmInput.value = "TestPassword123!"
      
      controller.checkPasswordMatch()
      expect(confirmInput.getAttribute("aria-invalid")).toBe("false")

      confirmInput.value = "DifferentPassword"
      controller.checkPasswordMatch()
      expect(confirmInput.getAttribute("aria-invalid")).toBe("true")
    })

    it("shows error message for mismatched passwords", () => {
      const passwordInput = container.querySelector("#password-input")
      const confirmInput = container.querySelector("#password-confirm-input")
      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector("[data-controller]"), 
        "password-strength"
      )

      passwordInput.value = "TestPassword123!"
      confirmInput.value = "DifferentPassword"
      
      controller.checkPasswordMatch()

      const errorElement = document.getElementById("password-match-feedback")
      expect(errorElement).toBeTruthy()
      expect(errorElement.textContent).toContain("do not match")
    })

    it("clears error when passwords match", () => {
      const passwordInput = container.querySelector("#password-input")
      const confirmInput = container.querySelector("#password-confirm-input")
      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector("[data-controller]"), 
        "password-strength"
      )

      // First create mismatch
      passwordInput.value = "TestPassword123!"
      confirmInput.value = "DifferentPassword"
      controller.checkPasswordMatch()

      const errorElement = document.getElementById("password-match-feedback")
      expect(errorElement.classList.contains("show")).toBe(true)

      // Then fix it
      confirmInput.value = "TestPassword123!"
      controller.checkPasswordMatch()
      expect(errorElement.classList.contains("show")).toBe(false)
    })
  })

  describe("visual indicators", () => {
    beforeEach(() => {
      container.innerHTML = `
        <div data-controller="password-strength">
          <input type="password" data-password-strength-target="password" id="password-input">
        </div>
      `
    })

    it("creates strength indicator automatically", () => {
      const passwordInput = container.querySelector("#password-input")
      
      // Trigger connection to create indicator
      passwordInput.focus()

      const strengthIndicator = document.getElementById("password-strength-feedback")
      expect(strengthIndicator).toBeTruthy()
      expect(strengthIndicator.querySelector(".password-strength-bar")).toBeTruthy()
      expect(strengthIndicator.querySelector(".password-strength-text")).toBeTruthy()
    })

    it("updates strength bar based on password quality", () => {
      const passwordInput = container.querySelector("#password-input")
      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector("[data-controller]"), 
        "password-strength"
      )

      // Create indicator first
      controller.createStrengthIndicator()

      passwordInput.value = "weak"
      controller.checkPasswordStrength()

      const strengthBar = container.querySelector(".password-strength-fill")
      expect(strengthBar.classList.contains("weak")).toBe(true)

      passwordInput.value = "StrongPassword123!"
      controller.checkPasswordStrength()

      expect(strengthBar.classList.contains("strong")).toBe(true)
    })

    it("updates requirements checklist", () => {
      const passwordInput = container.querySelector("#password-input")
      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector("[data-controller]"), 
        "password-strength"
      )

      // Create indicator first
      controller.createStrengthIndicator()

      passwordInput.value = "TestPassword123!"
      controller.checkPasswordStrength()

      const requirements = container.querySelectorAll(".password-requirement")
      expect(requirements.length).toBeGreaterThan(0)

      // Check that requirements are marked as met
      const lengthReq = container.querySelector('[data-requirement="length"]')
      const uppercaseReq = container.querySelector('[data-requirement="uppercase"]')
      const numberReq = container.querySelector('[data-requirement="number"]')

      expect(lengthReq.classList.contains("met")).toBe(true)
      expect(uppercaseReq.classList.contains("met")).toBe(true)
      expect(numberReq.classList.contains("met")).toBe(true)
    })
  })

  describe("form submission validation", () => {
    beforeEach(() => {
      container.innerHTML = `
        <form data-controller="password-strength">
          <input type="password" data-password-strength-target="password" id="password-input">
          <input type="password" data-password-strength-target="passwordConfirm" id="password-confirm-input">
          <button type="submit">Submit</button>
        </form>
      `
    })

    it("prevents submission with weak password", () => {
      const form = container.querySelector("form")
      const passwordInput = container.querySelector("#password-input")
      const controller = application.getControllerForElementAndIdentifier(form, "password-strength")

      passwordInput.value = "weak"
      
      const submitEvent = new Event("submit", { cancelable: true })
      const result = controller.validateBeforeSubmit(submitEvent)

      expect(result).toBe(false)
      expect(submitEvent.defaultPrevented).toBe(true)
    })

    it("prevents submission with mismatched passwords", () => {
      const form = container.querySelector("form")
      const passwordInput = container.querySelector("#password-input")
      const confirmInput = container.querySelector("#password-confirm-input")
      const controller = application.getControllerForElementAndIdentifier(form, "password-strength")

      passwordInput.value = "StrongPassword123!"
      confirmInput.value = "DifferentPassword"
      
      const submitEvent = new Event("submit", { cancelable: true })
      const result = controller.validateBeforeSubmit(submitEvent)

      expect(result).toBe(false)
      expect(submitEvent.defaultPrevented).toBe(true)
    })

    it("allows submission with strong matching passwords", () => {
      const form = container.querySelector("form")
      const passwordInput = container.querySelector("#password-input")
      const confirmInput = container.querySelector("#password-confirm-input")
      const controller = application.getControllerForElementAndIdentifier(form, "password-strength")

      passwordInput.value = "StrongPassword123!"
      confirmInput.value = "StrongPassword123!"
      
      const submitEvent = new Event("submit", { cancelable: true })
      const result = controller.validateBeforeSubmit(submitEvent)

      expect(result).toBe(true)
      expect(submitEvent.defaultPrevented).toBe(false)
    })
  })

  describe("accessibility", () => {
    beforeEach(() => {
      container.innerHTML = `
        <div data-controller="password-strength">
          <input type="password" data-password-strength-target="password" id="password-input">
        </div>
      `
    })

    it("sets proper ARIA attributes", () => {
      const passwordInput = container.querySelector("#password-input")
      
      expect(passwordInput.getAttribute("aria-describedby")).toBe("password-strength-feedback")
    })

    it("provides live region for announcements", () => {
      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector("[data-controller]"), 
        "password-strength"
      )

      controller.announceValidationFailure("Test message")
      
      const liveRegion = document.getElementById("password-validation-announcements")
      expect(liveRegion).toBeTruthy()
      expect(liveRegion.getAttribute("aria-live")).toBe("assertive")
      expect(liveRegion.textContent).toBe("Test message")
    })

    it("updates ARIA labels for strength feedback", () => {
      const passwordInput = container.querySelector("#password-input")
      const controller = application.getControllerForElementAndIdentifier(
        container.querySelector("[data-controller]"), 
        "password-strength"
      )

      // Create indicator first
      controller.createStrengthIndicator()

      passwordInput.value = "TestPassword123!"
      controller.checkPasswordStrength()

      const strengthText = container.querySelector(".password-strength-text")
      const ariaLabel = strengthText.getAttribute("aria-label")
      expect(ariaLabel).toContain("Password strength:")
      expect(ariaLabel).toContain("Score:")
    })
  })
})