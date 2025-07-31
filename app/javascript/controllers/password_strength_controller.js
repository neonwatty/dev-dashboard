import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="password-strength"
export default class extends Controller {
  static targets = ["password", "passwordConfirm", "strengthIndicator", "strengthText", "strengthBar"]
  static classes = ["weak", "fair", "good", "strong", "excellent"]
  static values = { 
    minLength: { type: Number, default: 8 },
    showConfirmation: { type: Boolean, default: true },
    realTimeValidation: { type: Boolean, default: true }
  }

  connect() {
    this.setupPasswordStrength()
    this.setupPasswordConfirmation()
    this.setupIndicatorDisplay()
    this.loadCommonPasswords()
  }

  setupPasswordStrength() {
    if (this.hasPasswordTarget) {
      // Add real-time validation
      this.passwordTarget.addEventListener("input", this.checkPasswordStrength.bind(this))
      this.passwordTarget.addEventListener("focus", this.showStrengthIndicator.bind(this))
      
      // Set up ARIA attributes
      this.passwordTarget.setAttribute("aria-describedby", "password-strength-feedback")
      
      // Create strength indicator if it doesn't exist
      if (!this.hasStrengthIndicatorTarget) {
        this.createStrengthIndicator()
      }
    }
  }

  setupPasswordConfirmation() {
    if (this.showConfirmationValue && this.hasPasswordConfirmTarget) {
      this.passwordConfirmTarget.addEventListener("input", this.checkPasswordMatch.bind(this))
      this.passwordConfirmTarget.addEventListener("blur", this.checkPasswordMatch.bind(this))
      
      // Set up ARIA attributes
      this.passwordConfirmTarget.setAttribute("aria-describedby", "password-match-feedback")
    }
  }

  setupIndicatorDisplay() {
    // Add CSS for strength indicator
    const style = document.createElement("style")
    style.textContent = `
      .password-strength-container {
        margin-top: 0.5rem;
        transition: opacity 0.3s ease, max-height 0.3s ease;
      }
      
      .password-strength-bar {
        height: 4px;
        border-radius: 2px;
        background-color: #e5e7eb;
        overflow: hidden;
        transition: all 0.3s ease;
      }
      
      .password-strength-fill {
        height: 100%;
        border-radius: inherit;
        transition: width 0.3s ease, background-color 0.3s ease;
        width: 0%;
      }
      
      .password-strength-fill.weak {
        background-color: #ef4444;
      }
      
      .password-strength-fill.fair {
        background-color: #f97316;
      }
      
      .password-strength-fill.good {
        background-color: #eab308;
      }
      
      .password-strength-fill.strong {
        background-color: #22c55e;
      }
      
      .password-strength-fill.excellent {
        background-color: #10b981;
      }
      
      .password-strength-text {
        font-size: 0.75rem;
        margin-top: 0.25rem;
        transition: color 0.3s ease;
      }
      
      .password-strength-text.weak {
        color: #ef4444;
      }
      
      .password-strength-text.fair {
        color: #f97316;
      }
      
      .password-strength-text.good {
        color: #eab308;
      }
      
      .password-strength-text.strong {
        color: #22c55e;
      }
      
      .password-strength-text.excellent {
        color: #10b981;
      }
      
      .password-match-error {
        color: #ef4444;
        font-size: 0.75rem;
        margin-top: 0.25rem;
        opacity: 0;
        transition: opacity 0.3s ease;
      }
      
      .password-match-error.show {
        opacity: 1;
      }
      
      .password-requirements {
        font-size: 0.75rem;
        margin-top: 0.5rem;
        color: #6b7280;
      }
      
      .password-requirement {
        display: flex;
        align-items: center;
        margin-bottom: 0.25rem;
        transition: color 0.3s ease;
      }
      
      .password-requirement.met {
        color: #10b981;
      }
      
      .password-requirement-icon {
        width: 12px;
        height: 12px;
        margin-right: 0.5rem;
        border-radius: 50%;
        border: 1px solid currentColor;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 8px;
        font-weight: bold;
      }
      
      .password-requirement.met .password-requirement-icon {
        background-color: #10b981;
        border-color: #10b981;
        color: white;
      }
    `
    
    if (!document.querySelector("#password-strength-styles")) {
      style.id = "password-strength-styles"
      document.head.appendChild(style)
    }
  }

  async loadCommonPasswords() {
    // Load a basic list of common passwords for checking
    this.commonPasswords = new Set([
      "password", "123456", "123456789", "12345678", "12345", "1234567",
      "password123", "admin", "qwerty", "abc123", "letmein", "welcome",
      "monkey", "dragon", "password1", "123123", "welcome123", "admin123",
      "root", "toor", "pass", "test", "guest", "info", "user", "login"
    ])
  }

  createStrengthIndicator() {
    const container = document.createElement("div")
    container.className = "password-strength-container"
    container.id = "password-strength-feedback"
    container.setAttribute("aria-live", "polite")
    
    // Create strength bar
    const barContainer = document.createElement("div")
    barContainer.className = "password-strength-bar"
    
    const barFill = document.createElement("div")
    barFill.className = "password-strength-fill"
    barContainer.appendChild(barFill)
    
    // Create strength text
    const strengthText = document.createElement("div")
    strengthText.className = "password-strength-text"
    strengthText.setAttribute("aria-label", "Password strength")
    
    // Create requirements list
    const requirements = document.createElement("div")
    requirements.className = "password-requirements"
    requirements.innerHTML = `
      <div class="password-requirement" data-requirement="length">
        <span class="password-requirement-icon"></span>
        <span>At least ${this.minLengthValue} characters</span>
      </div>
      <div class="password-requirement" data-requirement="uppercase">
        <span class="password-requirement-icon"></span>
        <span>One uppercase letter</span>
      </div>
      <div class="password-requirement" data-requirement="lowercase">
        <span class="password-requirement-icon"></span>
        <span>One lowercase letter</span>
      </div>
      <div class="password-requirement" data-requirement="number">
        <span class="password-requirement-icon"></span>
        <span>One number</span>
      </div>
      <div class="password-requirement" data-requirement="special">
        <span class="password-requirement-icon"></span>
        <span>One special character</span>
      </div>
    `
    
    container.appendChild(barContainer)
    container.appendChild(strengthText)
    container.appendChild(requirements)
    
    // Insert after password field
    this.passwordTarget.parentNode.insertBefore(container, this.passwordTarget.nextSibling)
    
    // Add to targets
    this.strengthIndicatorTarget = container
    this.strengthBarTarget = barFill
    this.strengthTextTarget = strengthText
  }

  checkPasswordStrength() {
    if (!this.hasPasswordTarget) return

    const password = this.passwordTarget.value
    const strength = this.calculatePasswordStrength(password)
    
    this.updateStrengthIndicator(strength)
    this.updateRequirements(password)
    
    // Check password confirmation if it exists and has content
    if (this.hasPasswordConfirmTarget && this.passwordConfirmTarget.value !== "") {
      this.checkPasswordMatch()
    }
  }

  calculatePasswordStrength(password) {
    if (password === "") {
      return { score: 0, level: "none", message: "Enter a password" }
    }

    let score = 0
    let feedback = []

    // Length scoring (0-25 points)
    if (password.length >= this.minLengthValue) {
      score += 10
      if (password.length >= 12) score += 5
      if (password.length >= 16) score += 5
      if (password.length >= 20) score += 5
    } else {
      feedback.push(`Use at least ${this.minLengthValue} characters`)
    }

    // Character variety (0-40 points)
    if (/[a-z]/.test(password)) score += 5
    else feedback.push("Add lowercase letters")
    
    if (/[A-Z]/.test(password)) score += 5
    else feedback.push("Add uppercase letters")
    
    if (/[0-9]/.test(password)) score += 5
    else feedback.push("Add numbers")
    
    if (/[^A-Za-z0-9]/.test(password)) score += 10
    else feedback.push("Add special characters")

    // Complexity bonuses (0-15 points)
    if (/[a-z].*[A-Z]|[A-Z].*[a-z]/.test(password)) score += 5 // Mixed case
    if (/\d.*[^A-Za-z0-9]|[^A-Za-z0-9].*\d/.test(password)) score += 5 // Numbers + symbols
    if (password.length >= 12 && /[a-z]/.test(password) && /[A-Z]/.test(password) && /\d/.test(password) && /[^A-Za-z0-9]/.test(password)) {
      score += 5 // All character types + good length
    }

    // Pattern penalties (0 to -20 points)
    if (/(.)\1{2,}/.test(password)) score -= 5 // Repeated characters
    if (/123|abc|qwe/i.test(password)) score -= 5 // Sequential characters
    if (this.commonPasswords && this.commonPasswords.has(password.toLowerCase())) score -= 10 // Common password

    // Dictionary word penalty
    if (this.containsDictionaryWord(password)) score -= 5

    // Ensure score is within bounds
    score = Math.max(0, Math.min(100, score))

    // Determine strength level
    let level, message
    if (score === 0) {
      level = "none"
      message = "Enter a password"
    } else if (score < 20) {
      level = "weak"
      message = "Very weak password"
    } else if (score < 40) {
      level = "fair"
      message = "Weak password"
    } else if (score < 60) {
      level = "good"
      message = "Fair password"
    } else if (score < 80) {
      level = "strong"
      message = "Strong password"
    } else {
      level = "excellent"
      message = "Excellent password"
    }

    return { score, level, message, feedback }
  }

  containsDictionaryWord(password) {
    // Simple check for common English words (could be expanded)
    const commonWords = [
      "password", "admin", "user", "login", "welcome", "hello", "world",
      "computer", "internet", "security", "system", "access", "account"
    ]
    
    const lowerPassword = password.toLowerCase()
    return commonWords.some(word => lowerPassword.includes(word))
  }

  updateStrengthIndicator(strength) {
    if (!this.hasStrengthBarTarget || !this.hasStrengthTextTarget) return

    // Update bar fill
    const percentage = strength.level === "none" ? 0 : Math.max(20, strength.score)
    this.strengthBarTarget.style.width = `${percentage}%`
    
    // Remove all strength classes
    const strengthClasses = ["weak", "fair", "good", "strong", "excellent"]
    strengthClasses.forEach(cls => {
      this.strengthBarTarget.classList.remove(cls)
      this.strengthTextTarget.classList.remove(cls)
    })
    
    // Add current strength class
    if (strength.level !== "none") {
      this.strengthBarTarget.classList.add(strength.level)
      this.strengthTextTarget.classList.add(strength.level)
    }
    
    // Update text
    this.strengthTextTarget.textContent = strength.message
    
    // Update ARIA label for accessibility
    const ariaLabel = `Password strength: ${strength.message}. Score: ${strength.score} out of 100.`
    this.strengthTextTarget.setAttribute("aria-label", ariaLabel)
  }

  updateRequirements(password) {
    if (!this.hasStrengthIndicatorTarget) return

    const requirements = this.strengthIndicatorTarget.querySelectorAll(".password-requirement")
    
    requirements.forEach(req => {
      const type = req.dataset.requirement
      let isMet = false
      
      switch (type) {
        case "length":
          isMet = password.length >= this.minLengthValue
          break
        case "uppercase":
          isMet = /[A-Z]/.test(password)
          break
        case "lowercase":
          isMet = /[a-z]/.test(password)
          break
        case "number":
          isMet = /[0-9]/.test(password)
          break
        case "special":
          isMet = /[^A-Za-z0-9]/.test(password)
          break
      }
      
      if (isMet) {
        req.classList.add("met")
        req.querySelector(".password-requirement-icon").textContent = "✓"
      } else {
        req.classList.remove("met")
        req.querySelector(".password-requirement-icon").textContent = ""
      }
    })
  }

  checkPasswordMatch() {
    if (!this.hasPasswordTarget || !this.hasPasswordConfirmTarget) return

    const password = this.passwordTarget.value
    const confirmation = this.passwordConfirmTarget.value
    
    // Don't validate empty confirmation
    if (confirmation === "") {
      this.clearPasswordMatchError()
      return
    }
    
    const matches = password === confirmation
    
    if (matches) {
      this.clearPasswordMatchError()
      this.passwordConfirmTarget.setAttribute("aria-invalid", "false")
    } else {
      this.showPasswordMatchError("Passwords do not match")
      this.passwordConfirmTarget.setAttribute("aria-invalid", "true")
    }
  }

  showPasswordMatchError(message) {
    let errorElement = document.getElementById("password-match-feedback")
    
    if (!errorElement) {
      errorElement = document.createElement("div")
      errorElement.id = "password-match-feedback"
      errorElement.className = "password-match-error"
      errorElement.setAttribute("role", "alert")
      errorElement.setAttribute("aria-live", "polite")
      
      this.passwordConfirmTarget.parentNode.insertBefore(
        errorElement, 
        this.passwordConfirmTarget.nextSibling
      )
    }
    
    errorElement.textContent = message
    errorElement.classList.add("show")
  }

  clearPasswordMatchError() {
    const errorElement = document.getElementById("password-match-feedback")
    if (errorElement) {
      errorElement.classList.remove("show")
    }
  }

  showStrengthIndicator() {
    if (this.hasStrengthIndicatorTarget) {
      this.strengthIndicatorTarget.style.opacity = "1"
      this.strengthIndicatorTarget.style.maxHeight = "200px"
    }
  }

  hideStrengthIndicator() {
    if (this.hasStrengthIndicatorTarget) {
      this.strengthIndicatorTarget.style.opacity = "0"
      this.strengthIndicatorTarget.style.maxHeight = "0"
    }
  }

  // Stimulus action to validate passwords before form submission
  validateBeforeSubmit(event) {
    let isValid = true
    
    if (this.hasPasswordTarget) {
      const password = this.passwordTarget.value
      const strength = this.calculatePasswordStrength(password)
      
      // Require at least fair strength
      if (strength.score < 20) {
        isValid = false
        this.announceValidationFailure("Password is too weak")
      }
      
      // Check password confirmation
      if (this.hasPasswordConfirmTarget) {
        const confirmation = this.passwordConfirmTarget.value
        if (password !== confirmation) {
          isValid = false
          this.showPasswordMatchError("Passwords do not match")
        }
      }
    }
    
    if (!isValid) {
      event.preventDefault()
      
      // Focus first problematic field
      if (this.hasPasswordTarget) {
        this.passwordTarget.focus()
      }
    }
    
    return isValid
  }

  announceValidationFailure(message) {
    // Create or update live region for validation announcements
    let liveRegion = document.getElementById("password-validation-announcements")
    
    if (!liveRegion) {
      liveRegion = document.createElement("div")
      liveRegion.id = "password-validation-announcements"
      liveRegion.setAttribute("aria-live", "assertive")
      liveRegion.setAttribute("aria-atomic", "true")
      liveRegion.className = "sr-only"
      document.body.appendChild(liveRegion)
    }
    
    liveRegion.textContent = message
    
    // Clear announcement after it's been read
    setTimeout(() => {
      liveRegion.textContent = ""
    }, 3000)
  }

  // Stimulus actions
  checkStrength() {
    this.checkPasswordStrength()
  }

  checkMatch() {
    this.checkPasswordMatch()
  }

  toggleVisibility() {
    if (this.hasPasswordTarget) {
      const isPassword = this.passwordTarget.type === "password"
      this.passwordTarget.type = isPassword ? "text" : "password"
      
      // Update aria-label for accessibility
      const label = isPassword ? "Hide password" : "Show password"
      const button = event.target
      button.setAttribute("aria-label", label)
    }
  }
}