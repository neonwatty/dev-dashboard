import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form-validation"
export default class extends Controller {
  static targets = ["email", "emailError", "rememberMe"]
  static classes = ["valid", "invalid", "checking"]
  static values = { 
    showRememberMe: { type: Boolean, default: true },
    rememberMeExpiry: { type: Number, default: 30 } // days
  }

  connect() {
    this.debounceTimeout = null
    this.setupEmailValidation()
    this.setupRememberMe()
    this.setupErrorDisplay()
  }

  disconnect() {
    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout)
    }
  }

  setupEmailValidation() {
    if (this.hasEmailTarget) {
      // Add real-time validation on input
      this.emailTarget.addEventListener("input", this.validateEmailDebounced.bind(this))
      this.emailTarget.addEventListener("blur", this.validateEmail.bind(this))
      
      // Set up ARIA attributes
      this.emailTarget.setAttribute("aria-describedby", "email-validation-message")
      
      // Create error message container if it doesn't exist
      if (!this.hasEmailErrorTarget) {
        this.createEmailErrorContainer()
      }
    }
  }

  setupRememberMe() {
    if (this.showRememberMeValue && this.hasRememberMeTarget) {
      // Load saved preference
      const remembered = localStorage.getItem("rememberMe") === "true"
      this.rememberMeTarget.checked = remembered
      
      // Save preference on change
      this.rememberMeTarget.addEventListener("change", (event) => {
        localStorage.setItem("rememberMe", event.target.checked.toString())
        this.updateRememberMeAriaLabel()
      })
      
      this.updateRememberMeAriaLabel()
    }
  }

  setupErrorDisplay() {
    // Set up smooth transitions for error messages
    const style = document.createElement("style")
    style.textContent = `
      .form-validation-error {
        transition: opacity 0.3s ease, max-height 0.3s ease, margin 0.3s ease;
        overflow: hidden;
        opacity: 0;
        max-height: 0;
        margin: 0;
      }
      
      .form-validation-error.show {
        opacity: 1;
        max-height: 100px;
        margin-top: 0.25rem;
      }
      
      .form-validation-success {
        transition: border-color 0.3s ease, box-shadow 0.3s ease;
      }
      
      .form-validation-checking {
        position: relative;
      }
      
      .form-validation-checking::after {
        content: '';
        position: absolute;
        right: 8px;
        top: 50%;
        transform: translateY(-50%);
        width: 16px;
        height: 16px;
        border: 2px solid #e5e7eb;
        border-top-color: #3b82f6;
        border-radius: 50%;
        animation: spin 1s linear infinite;
      }
      
      @keyframes spin {
        to { transform: translateY(-50%) rotate(360deg); }
      }
      
      .form-validation-success-icon::after {
        content: '✓';
        position: absolute;
        right: 8px;
        top: 50%;
        transform: translateY(-50%);
        color: #10b981;
        font-weight: bold;
        font-size: 16px;
      }
      
      .form-validation-error-icon::after {
        content: '✕';
        position: absolute;
        right: 8px;
        top: 50%;
        transform: translateY(-50%);
        color: #ef4444;
        font-weight: bold;
        font-size: 16px;
      }
    `
    
    if (!document.querySelector("#form-validation-styles")) {
      style.id = "form-validation-styles"
      document.head.appendChild(style)
    }
  }

  validateEmailDebounced() {
    // Clear existing timeout
    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout)
    }
    
    // Show checking state immediately
    this.setEmailState("checking")
    
    // Debounce validation by 300ms
    this.debounceTimeout = setTimeout(() => {
      this.validateEmail()
    }, 300)
  }

  validateEmail() {
    if (!this.hasEmailTarget) return

    const email = this.emailTarget.value.trim()
    
    // Clear checking state
    this.setEmailState("neutral")
    
    if (email === "") {
      this.clearEmailValidation()
      return
    }

    // Comprehensive email validation
    const validationResult = this.performEmailValidation(email)
    
    if (validationResult.isValid) {
      this.setEmailState("valid")
      this.clearEmailError()
    } else {
      this.setEmailState("invalid")
      this.showEmailError(validationResult.message)
    }
  }

  performEmailValidation(email) {
    // RFC 5322 compliant email regex (simplified but comprehensive)
    const emailRegex = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/
    
    // Check basic format
    if (!emailRegex.test(email)) {
      return {
        isValid: false,
        message: "Please enter a valid email address"
      }
    }
    
    // Check for common issues
    if (email.length > 254) {
      return {
        isValid: false,
        message: "Email address is too long"
      }
    }
    
    // Check for consecutive dots
    if (email.includes("..")) {
      return {
        isValid: false,
        message: "Email address cannot contain consecutive dots"
      }
    }
    
    // Check domain part
    const [localPart, domainPart] = email.split("@")
    
    if (localPart.length > 64) {
      return {
        isValid: false,
        message: "Local part of email is too long"
      }
    }
    
    if (domainPart.length > 253) {
      return {
        isValid: false,
        message: "Domain part of email is too long"
      }
    }
    
    // Check for valid domain structure
    if (!domainPart.includes(".") || domainPart.startsWith(".") || domainPart.endsWith(".")) {
      return {
        isValid: false,
        message: "Please enter a valid domain name"
      }
    }
    
    return { isValid: true }
  }

  setEmailState(state) {
    if (!this.hasEmailTarget) return
    
    // Remove all state classes
    this.emailTarget.classList.remove(
      "form-validation-checking",
      "form-validation-success",
      "form-validation-success-icon",
      "form-validation-error-icon"
    )
    
    // Remove custom validation classes if defined
    if (this.hasValidClass) {
      this.emailTarget.classList.remove(this.validClass)
    }
    if (this.hasInvalidClass) {
      this.emailTarget.classList.remove(this.invalidClass)
    }
    if (this.hasCheckingClass) {
      this.emailTarget.classList.remove(this.checkingClass)
    }
    
    // Apply new state class
    switch (state) {
      case "checking":
        this.emailTarget.classList.add("form-validation-checking")
        if (this.hasCheckingClass) {
          this.emailTarget.classList.add(this.checkingClass)
        }
        this.emailTarget.setAttribute("aria-invalid", "false")
        break
      case "valid":
        this.emailTarget.classList.add("form-validation-success", "form-validation-success-icon")
        if (this.hasValidClass) {
          this.emailTarget.classList.add(this.validClass)
        }
        this.emailTarget.setAttribute("aria-invalid", "false")
        break
      case "invalid":
        this.emailTarget.classList.add("form-validation-error-icon")
        if (this.hasInvalidClass) {
          this.emailTarget.classList.add(this.invalidClass)
        }
        this.emailTarget.setAttribute("aria-invalid", "true")
        break
      default:
        this.emailTarget.setAttribute("aria-invalid", "false")
        break
    }
  }

  createEmailErrorContainer() {
    const errorDiv = document.createElement("div")
    errorDiv.id = "email-validation-message"
    errorDiv.className = "form-validation-error text-sm text-red-600 dark:text-red-400"
    errorDiv.role = "alert"
    errorDiv.setAttribute("aria-live", "polite")
    
    // Insert after email input
    this.emailTarget.parentNode.insertBefore(errorDiv, this.emailTarget.nextSibling)
    
    // Add to targets
    this.emailErrorTarget = errorDiv
  }

  showEmailError(message) {
    if (!this.hasEmailErrorTarget) {
      this.createEmailErrorContainer()
    }
    
    this.emailErrorTarget.textContent = message
    this.emailErrorTarget.classList.add("show")
    
    // Update ARIA attributes
    this.emailTarget.setAttribute("aria-describedby", "email-validation-message")
  }

  clearEmailError() {
    if (this.hasEmailErrorTarget) {
      this.emailErrorTarget.classList.remove("show")
      // Clear text after animation
      setTimeout(() => {
        if (this.hasEmailErrorTarget) {
          this.emailErrorTarget.textContent = ""
        }
      }, 300)
    }
  }

  clearEmailValidation() {
    this.setEmailState("neutral")
    this.clearEmailError()
  }

  updateRememberMeAriaLabel() {
    if (this.hasRememberMeTarget) {
      const isChecked = this.rememberMeTarget.checked
      const label = isChecked 
        ? `Remember me for ${this.rememberMeExpiryValue} days (currently enabled)`
        : "Remember me (currently disabled)"
      
      this.rememberMeTarget.setAttribute("aria-label", label)
    }
  }

  // Action to validate form before submission
  validateBeforeSubmit(event) {
    let isValid = true
    
    // Validate email
    if (this.hasEmailTarget) {
      this.validateEmail()
      
      const emailValue = this.emailTarget.value.trim()
      if (emailValue === "" || this.emailTarget.getAttribute("aria-invalid") === "true") {
        isValid = false
      }
    }
    
    if (!isValid) {
      event.preventDefault()
      
      // Focus first invalid field
      if (this.hasEmailTarget && this.emailTarget.getAttribute("aria-invalid") === "true") {
        this.emailTarget.focus()
      }
      
      // Announce validation failure to screen readers
      this.announceValidationFailure()
    }
    
    return isValid
  }

  announceValidationFailure() {
    // Create or update live region for validation announcements
    let liveRegion = document.getElementById("form-validation-announcements")
    
    if (!liveRegion) {
      liveRegion = document.createElement("div")
      liveRegion.id = "form-validation-announcements"
      liveRegion.setAttribute("aria-live", "assertive")
      liveRegion.setAttribute("aria-atomic", "true")
      liveRegion.className = "sr-only"
      document.body.appendChild(liveRegion)
    }
    
    liveRegion.textContent = "Please correct the validation errors before submitting"
    
    // Clear announcement after it's been read
    setTimeout(() => {
      liveRegion.textContent = ""
    }, 3000)
  }

  // Stimulus action to manually trigger validation
  validate() {
    this.validateEmail()
  }

  // Stimulus action to clear all validation
  clear() {
    this.clearEmailValidation()
  }
}