// test/javascript/source_filters_controller_test.js
import { Application } from "@hotwired/stimulus"
import SourceFiltersController from "../../app/javascript/controllers/source_filters_controller"

describe("SourceFiltersController", () => {
  let application
  let element
  
  beforeEach(() => {
    // Set up DOM with source filters
    document.body.innerHTML = `
      <div data-controller="source-filters" class="bg-white rounded-lg shadow-md p-6 mb-6">
        <!-- Sources Filter -->
        <div class="mb-4 pt-4 border-t border-gray-200">
          <div class="flex items-center justify-between mb-3">
            <h3 class="text-sm font-medium text-gray-700">Filter by Sources</h3>
            <div class="flex gap-2">
              <button type="button" data-action="click->source-filters#selectAllSources" class="text-xs text-blue-600 hover:text-blue-800">Select All</button>
              <button type="button" data-action="click->source-filters#clearAllSources" class="text-xs text-blue-600 hover:text-blue-800">Clear All</button>
            </div>
          </div>
          
          <form id="sources-filter-form">
            <div class="flex flex-wrap gap-2 mb-3">
              <label class="inline-flex items-center cursor-pointer" 
                     data-source-filters-target="label" 
                     data-action="click->source-filters#toggleSource">
                <input type="checkbox" name="sources[]" value="GitHub" 
                       class="sr-only source-checkbox" 
                       data-source-filters-target="checkbox">
                <span class="inline-flex items-center px-3 py-1.5 rounded-full text-sm font-medium transition-colors bg-gray-100 text-gray-700 hover:bg-gray-200">
                  GitHub
                </span>
              </label>
              
              <label class="inline-flex items-center cursor-pointer" 
                     data-source-filters-target="label" 
                     data-action="click->source-filters#toggleSource">
                <input type="checkbox" name="sources[]" value="HuggingFace" 
                       class="sr-only source-checkbox" 
                       data-source-filters-target="checkbox" checked>
                <span class="inline-flex items-center px-3 py-1.5 rounded-full text-sm font-medium transition-colors bg-blue-600 text-white">
                  HuggingFace
                </span>
              </label>
              
              <label class="inline-flex items-center cursor-pointer" 
                     data-source-filters-target="label" 
                     data-action="click->source-filters#toggleSource">
                <input type="checkbox" name="sources[]" value="Reddit" 
                       class="sr-only source-checkbox" 
                       data-source-filters-target="checkbox">
                <span class="inline-flex items-center px-3 py-1.5 rounded-full text-sm font-medium transition-colors bg-gray-100 text-gray-700 hover:bg-gray-200">
                  Reddit
                </span>
              </label>
            </div>
          </form>
        </div>
        
        <!-- Search -->
        <div class="flex items-center gap-4">
          <form class="flex-1">
            <div class="relative">
              <input type="text" name="keyword" placeholder="Search posts..." 
                     class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                     data-action="keypress->source-filters#handleSearchKeypress">
            </div>
          </form>
          
          <button type="button" 
                  data-action="click->source-filters#toggleAdvancedFilters"
                  class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-lg text-sm font-medium text-gray-700 bg-white hover:bg-gray-50">
            <span data-source-filters-target="advancedToggleText">More Filters</span>
          </button>
        </div>
        
        <!-- Advanced Filters -->
        <div data-source-filters-target="advancedFilters" class="hidden mt-4 pt-4 border-t border-gray-200">
          <p>Advanced filters content here</p>
        </div>
      </div>
    `
    
    // Start Stimulus
    application = Application.start()
    application.register("source-filters", SourceFiltersController)
    
    element = document.querySelector('[data-controller="source-filters"]')
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ''
  })
  
  describe("initialization", () => {
    it("connects to the controller", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "source-filters")
      expect(controller).toBeTruthy()
    })
    
    it("finds all targets", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "source-filters")
      expect(controller.checkboxTargets.length).toBe(3)
      expect(controller.labelTargets.length).toBe(3)
      expect(controller.hasAdvancedFiltersTarget).toBe(true)
      expect(controller.hasAdvancedToggleTextTarget).toBe(true)
    })
    
    it("logs connection message", () => {
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation()
      application.getControllerForElementAndIdentifier(element, "source-filters")
      expect(consoleSpy).toHaveBeenCalledWith("Source filters controller connected")
      consoleSpy.mockRestore()
    })
  })
  
  describe("toggleSource", () => {
    it("toggles checkbox state when label is clicked", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "source-filters")
      const githubLabel = element.querySelector('label[data-action*="toggleSource"]')
      const githubCheckbox = githubLabel.querySelector('input[value="GitHub"]')
      
      expect(githubCheckbox.checked).toBe(false)
      
      const clickEvent = new Event('click', { bubbles: true })
      githubLabel.dispatchEvent(clickEvent)
      
      expect(githubCheckbox.checked).toBe(true)
    })
    
    it("updates visual state when toggling", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "source-filters")
      const githubLabel = element.querySelector('label[data-action*="toggleSource"]')
      const githubSpan = githubLabel.querySelector('span')
      
      // Initially unchecked (gray)
      expect(githubSpan.classList.contains('bg-gray-100')).toBe(true)
      expect(githubSpan.classList.contains('text-gray-700')).toBe(true)
      
      // Click to check
      const clickEvent = new Event('click', { bubbles: true })
      githubLabel.dispatchEvent(clickEvent)
      
      // Should be checked (blue)
      expect(githubSpan.classList.contains('bg-blue-600')).toBe(true)
      expect(githubSpan.classList.contains('text-white')).toBe(true)
      expect(githubSpan.classList.contains('bg-gray-100')).toBe(false)
      expect(githubSpan.classList.contains('text-gray-700')).toBe(false)
    })
    
    it("does not auto-submit the form", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "source-filters")
      const githubLabel = element.querySelector('label[data-action*="toggleSource"]')
      const form = element.querySelector('#sources-filter-form')
      
      // Mock form.requestSubmit()
      const submitSpy = jest.spyOn(form, 'requestSubmit').mockImplementation()
      
      // Click the label
      const clickEvent = new Event('click', { bubbles: true })
      githubLabel.dispatchEvent(clickEvent)
      
      // Should NOT auto-submit
      expect(submitSpy).not.toHaveBeenCalled()
      
      // Even after a delay, should not submit
      setTimeout(() => {
        expect(submitSpy).not.toHaveBeenCalled()
      }, 600)
      
      submitSpy.mockRestore()
    })
  })
  
  describe("selectAllSources", () => {
    it("checks all source checkboxes", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "source-filters")
      const selectAllButton = element.querySelector('[data-action*="selectAllSources"]')
      
      // Initially only HuggingFace is checked
      const checkboxes = controller.checkboxTargets
      expect(checkboxes.filter(cb => cb.checked).length).toBe(1)
      
      selectAllButton.click()
      
      // All should be checked
      expect(checkboxes.filter(cb => cb.checked).length).toBe(3)
      checkboxes.forEach(checkbox => {
        expect(checkbox.checked).toBe(true)
      })
    })
    
    it("updates visual state for all sources", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "source-filters")
      const selectAllButton = element.querySelector('[data-action*="selectAllSources"]')
      
      selectAllButton.click()
      
      const spans = element.querySelectorAll('span')
      spans.forEach(span => {
        if (span.textContent.includes('GitHub') || span.textContent.includes('HuggingFace') || span.textContent.includes('Reddit')) {
          expect(span.classList.contains('bg-blue-600')).toBe(true)
          expect(span.classList.contains('text-white')).toBe(true)
        }
      })
    })
  })
  
  describe("clearAllSources", () => {
    it("unchecks all source checkboxes", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "source-filters")
      const clearAllButton = element.querySelector('[data-action*="clearAllSources"]')
      
      // Initially HuggingFace is checked
      const checkboxes = controller.checkboxTargets
      expect(checkboxes.filter(cb => cb.checked).length).toBe(1)
      
      clearAllButton.click()
      
      // All should be unchecked
      expect(checkboxes.filter(cb => cb.checked).length).toBe(0)
      checkboxes.forEach(checkbox => {
        expect(checkbox.checked).toBe(false)
      })
    })
    
    it("updates visual state for all sources", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "source-filters")
      const clearAllButton = element.querySelector('[data-action*="clearAllSources"]')
      
      clearAllButton.click()
      
      const spans = element.querySelectorAll('span')
      spans.forEach(span => {
        if (span.textContent.includes('GitHub') || span.textContent.includes('HuggingFace') || span.textContent.includes('Reddit')) {
          expect(span.classList.contains('bg-gray-100')).toBe(true)
          expect(span.classList.contains('text-gray-700')).toBe(true)
        }
      })
    })
  })
  
  describe("toggleAdvancedFilters", () => {
    it("shows advanced filters when hidden", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "source-filters")
      const toggleButton = element.querySelector('[data-action*="toggleAdvancedFilters"]')
      const advancedFilters = controller.advancedFiltersTarget
      const toggleText = controller.advancedToggleTextTarget
      
      expect(advancedFilters.classList.contains('hidden')).toBe(true)
      expect(toggleText.textContent).toBe('More Filters')
      
      toggleButton.click()
      
      expect(advancedFilters.classList.contains('hidden')).toBe(false)
      expect(toggleText.textContent).toBe('Hide Filters')
    })
    
    it("hides advanced filters when visible", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "source-filters")
      const toggleButton = element.querySelector('[data-action*="toggleAdvancedFilters"]')
      const advancedFilters = controller.advancedFiltersTarget
      const toggleText = controller.advancedToggleTextTarget
      
      // First click to show
      toggleButton.click()
      expect(advancedFilters.classList.contains('hidden')).toBe(false)
      
      // Second click to hide
      toggleButton.click()
      expect(advancedFilters.classList.contains('hidden')).toBe(true)
      expect(toggleText.textContent).toBe('More Filters')
    })
  })
  
  describe("handleSearchKeypress", () => {
    it("submits form on Enter key", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "source-filters")
      const searchInput = element.querySelector('input[name="keyword"]')
      const form = searchInput.closest('form')
      
      // Mock form.submit()
      const submitSpy = jest.spyOn(form, 'submit').mockImplementation()
      
      const enterEvent = new KeyboardEvent('keypress', { key: 'Enter' })
      searchInput.dispatchEvent(enterEvent)
      
      expect(submitSpy).toHaveBeenCalled()
      submitSpy.mockRestore()
    })
    
    it("does not submit form on other keys", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "source-filters")
      const searchInput = element.querySelector('input[name="keyword"]')
      const form = searchInput.closest('form')
      
      // Mock form.submit()
      const submitSpy = jest.spyOn(form, 'submit').mockImplementation()
      
      const aKeyEvent = new KeyboardEvent('keypress', { key: 'a' })
      searchInput.dispatchEvent(aKeyEvent)
      
      expect(submitSpy).not.toHaveBeenCalled()
      submitSpy.mockRestore()
    })
  })
  
  describe("updateLabelVisualState", () => {
    it("applies correct styles for checked state", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "source-filters")
      const githubLabel = element.querySelector('label[data-action*="toggleSource"]')
      
      controller.updateLabelVisualState(githubLabel, true)
      
      const span = githubLabel.querySelector('span')
      expect(span.classList.contains('bg-blue-600')).toBe(true)
      expect(span.classList.contains('text-white')).toBe(true)
      expect(span.classList.contains('bg-gray-100')).toBe(false)
      expect(span.classList.contains('text-gray-700')).toBe(false)
    })
    
    it("applies correct styles for unchecked state", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "source-filters")
      const huggingfaceLabel = element.querySelector('input[value="HuggingFace"]').closest('label')
      
      controller.updateLabelVisualState(huggingfaceLabel, false)
      
      const span = huggingfaceLabel.querySelector('span')
      expect(span.classList.contains('bg-gray-100')).toBe(true)
      expect(span.classList.contains('text-gray-700')).toBe(true)
      expect(span.classList.contains('bg-blue-600')).toBe(false)
      expect(span.classList.contains('text-white')).toBe(false)
    })
  })
})