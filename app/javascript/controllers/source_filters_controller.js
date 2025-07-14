import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "label", "form", "advancedFilters", "advancedToggleText"]

  connect() {
    console.log("Source filters controller connected")
  }

  disconnect() {
    // Clean up any resources if needed
  }

  // Handle source checkbox toggle
  toggleSource(event) {
    event.preventDefault()
    const label = event.currentTarget
    const checkbox = label.querySelector('input[type="checkbox"]')
    
    if (checkbox) {
      checkbox.checked = !checkbox.checked
      this.updateLabelVisualState(label, checkbox.checked)
    }
  }

  // Update the visual state of a label based on checkbox state
  updateLabelVisualState(label, isChecked) {
    const span = label.querySelector('span')
    if (span) {
      if (isChecked) {
        span.classList.remove('bg-gray-100', 'text-gray-700')
        span.classList.add('bg-blue-600', 'text-white')
      } else {
        span.classList.remove('bg-blue-600', 'text-white')
        span.classList.add('bg-gray-100', 'text-gray-700')
      }
    }
  }

  // Select all sources
  selectAllSources() {
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = true
      const label = checkbox.closest('label')
      if (label) {
        this.updateLabelVisualState(label, true)
      }
    })
  }

  // Clear all sources
  clearAllSources() {
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = false
      const label = checkbox.closest('label')
      if (label) {
        this.updateLabelVisualState(label, false)
      }
    })
  }

  // Toggle advanced filters
  toggleAdvancedFilters() {
    const advancedFilters = this.advancedFiltersTarget
    const toggleText = this.advancedToggleTextTarget
    
    if (advancedFilters.classList.contains('hidden')) {
      advancedFilters.classList.remove('hidden')
      toggleText.textContent = 'Hide Filters'
    } else {
      advancedFilters.classList.add('hidden')
      toggleText.textContent = 'More Filters'
    }
  }

  // Handle search form submission on enter
  handleSearchKeypress(event) {
    if (event.key === 'Enter') {
      event.preventDefault()
      event.currentTarget.form.submit()
    }
  }

}