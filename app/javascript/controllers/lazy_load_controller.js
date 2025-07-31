import { Controller } from "@hotwired/stimulus"

// Lazy loading controller for community icons and other images
// Uses Intersection Observer API for optimal performance
export default class extends Controller {
  static targets = ["image", "placeholder"]
  static values = { 
    threshold: { type: Number, default: 100 }, // Distance from viewport in pixels
    fadeInDuration: { type: Number, default: 300 }, // Animation duration in ms
    preloadCount: { type: Number, default: 3 } // Number of images to preload
  }

  connect() {
    this.imageCache = new Set()
    this.loadedImages = new Set()
    this.setupIntersectionObserver()
    this.preloadCriticalImages()
    
    // Add fallback for browsers without Intersection Observer
    if (!this.observer) {
      this.fallbackToImmediateLoad()
    }
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  setupIntersectionObserver() {
    // Check for Intersection Observer support
    if (!window.IntersectionObserver) {
      console.warn("Intersection Observer not supported, falling back to immediate load")
      this.observer = null
      return
    }

    // Calculate root margin from threshold value (convert px to viewport margin)
    const rootMargin = `${this.thresholdValue}px`

    const options = {
      root: null, // viewport
      rootMargin: rootMargin,
      threshold: 0.01 // Trigger as soon as 1% is visible
    }

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          this.loadImage(entry.target)
          this.observer.unobserve(entry.target)
        }
      })
    }, options)

    // Observe all image targets
    this.imageTargets.forEach(image => {
      if (!this.shouldPreload(image)) {
        this.observer.observe(image)
      }
    })
  }

  preloadCriticalImages() {
    // Load the first N images immediately (above the fold)
    const criticalImages = this.imageTargets.slice(0, this.preloadCountValue)
    criticalImages.forEach(image => {
      this.loadImage(image)
    })
  }

  shouldPreload(image) {
    const index = this.imageTargets.indexOf(image)
    return index < this.preloadCountValue
  }

  loadImage(imageElement) {
    const dataSrc = imageElement.dataset.src
    const dataAlt = imageElement.dataset.alt || ""
    
    if (!dataSrc || this.loadedImages.has(imageElement)) {
      return
    }

    // Create a new image to preload
    const img = new Image()
    
    img.onload = () => {
      this.handleImageLoad(imageElement, dataSrc, dataAlt)
    }
    
    img.onerror = () => {
      this.handleImageError(imageElement)
    }
    
    // Cache the image
    this.imageCache.add(dataSrc)
    img.src = dataSrc
  }

  handleImageLoad(imageElement, src, alt) {
    // Mark as loaded
    this.loadedImages.add(imageElement)
    
    // Update the image element
    if (imageElement.tagName === 'IMG') {
      imageElement.src = src
      imageElement.alt = alt
    } else {
      // Handle background images or other elements
      imageElement.style.backgroundImage = `url(${src})`
    }
    
    // Remove loading class and add loaded class
    imageElement.classList.remove('lazy-loading')
    imageElement.classList.add('lazy-loaded')
    
    // Hide placeholder if it exists
    const placeholder = imageElement.closest('[data-lazy-load-target="placeholder"]')
    if (placeholder) {
      placeholder.style.display = 'none'
    }
    
    // Trigger fade-in animation
    this.animateFadeIn(imageElement)
    
    // Dispatch custom event
    imageElement.dispatchEvent(new CustomEvent('lazy:loaded', {
      detail: { src, element: imageElement }
    }))
  }

  handleImageError(imageElement) {
    console.warn('Failed to load lazy image:', imageElement.dataset.src)
    imageElement.classList.remove('lazy-loading')
    imageElement.classList.add('lazy-error')
    
    // Show fallback content or placeholder
    const placeholder = imageElement.closest('[data-lazy-load-target="placeholder"]')
    if (placeholder) {
      placeholder.classList.add('lazy-error')
    }
    
    // Dispatch error event
    imageElement.dispatchEvent(new CustomEvent('lazy:error', {
      detail: { src: imageElement.dataset.src, element: imageElement }
    }))
  }

  animateFadeIn(element) {
    // Set initial opacity to 0
    element.style.opacity = '0'
    element.style.transition = `opacity ${this.fadeInDurationValue}ms ease-in-out`
    
    // Force reflow
    element.offsetHeight
    
    // Fade in
    element.style.opacity = '1'
  }

  fallbackToImmediateLoad() {
    // Load all images immediately for browsers without Intersection Observer
    console.log('Using lazy loading fallback: loading all images immediately')
    setTimeout(() => {
      this.imageTargets.forEach(image => {
        this.loadImage(image)
      })
    }, 100) // Small delay to allow DOM to settle
  }

  // Public method to manually trigger image loading
  loadImageNow(event) {
    const imageElement = event.currentTarget
    this.loadImage(imageElement)
  }

  // Method to check if image is cached
  isImageCached(src) {
    return this.imageCache.has(src)
  }

  // Method to preload additional images
  preloadImages(imageSources) {
    imageSources.forEach(src => {
      if (!this.imageCache.has(src)) {
        const img = new Image()
        img.src = src
        this.imageCache.add(src)
      }
    })
  }
}