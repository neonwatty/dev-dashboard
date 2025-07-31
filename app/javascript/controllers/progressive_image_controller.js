import { Controller } from "@hotwired/stimulus"

// Progressive Image Loading Controller
// Handles LQIP (Low Quality Image Placeholder) to high-quality image transitions
// with blur-to-sharp effects and WebP/JPEG fallback support
export default class extends Controller {
  static targets = ["image", "placeholder", "picture"]
  static values = { 
    lqip: String,              // Low Quality Image Placeholder data URI
    webp: String,              // WebP source URL
    jpeg: String,              // JPEG fallback URL
    alt: String,               // Alt text for accessibility
    sizes: String,             // Responsive sizes attribute
    srcset: String,            // Source set for responsive images
    transitionDuration: { type: Number, default: 300 }, // Transition duration in ms
    blurAmount: { type: Number, default: 10 },           // Initial blur amount in pixels
    loadingThreshold: { type: Number, default: 100 },   // Distance threshold for loading
    enableDominantColor: { type: Boolean, default: true }, // Use dominant color background
    dominantColor: String      // Dominant color from server-side processing
  }
  
  static classes = [
    "loading",      // Applied during loading state
    "loaded",       // Applied when image is fully loaded
    "error",        // Applied when image fails to load
    "blurred",      // Applied to create blur effect
    "transitioned"  // Applied after transition completes
  ]

  connect() {
    this.imageCache = new Set()
    this.setupIntersectionObserver()
    this.initializePlaceholder()
    
    // Preload critical images that are above the fold
    if (this.isAboveFold()) {
      this.loadImage()
    }
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
    this.cleanupTransitions()
  }

  setupIntersectionObserver() {
    if (!window.IntersectionObserver) {
      // Fallback for browsers without Intersection Observer
      this.loadImage()
      return
    }

    const options = {
      root: null,
      rootMargin: `${this.loadingThresholdValue}px`,
      threshold: 0.01
    }

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting && !this.isLoaded) {
          this.loadImage()
          this.observer.unobserve(entry.target)
        }
      })
    }, options)

    this.observer.observe(this.element)
  }

  initializePlaceholder() {
    // Set up the initial placeholder state
    if (this.hasPlaceholderTarget) {
      this.element.classList.add(this.loadingClass || 'progressive-loading')
      
      // Apply LQIP if available
      if (this.hasLqipValue) {
        this.displayLQIP()
      }
      
      // Apply dominant color background if available
      if (this.enableDominantColorValue && this.hasDominantColorValue) {
        this.placeholderTarget.style.backgroundColor = this.dominantColorValue
      }
    }
  }

  displayLQIP() {
    if (this.hasPlaceholderTarget && this.hasLqipValue) {
      const lqipImg = document.createElement('img')
      lqipImg.src = this.lqipValue
      lqipImg.alt = ''
      lqipImg.className = `${this.blurredClass || 'progressive-blurred'} w-full h-full object-cover`
      lqipImg.style.filter = `blur(${this.blurAmountValue}px)`
      lqipImg.style.transform = 'scale(1.1)' // Slight scale to hide blur edges
      lqipImg.style.transition = `filter ${this.transitionDurationValue}ms ease-out, transform ${this.transitionDurationValue}ms ease-out`
      
      this.placeholderTarget.appendChild(lqipImg)
      this.lqipElement = lqipImg
    }
  }

  async loadImage() {
    if (this.isLoaded || this.isLoading) {
      return
    }

    this.isLoading = true
    
    try {
      // Determine the best image source to load
      const imageSource = this.selectOptimalImageSource()
      
      // Preload the image
      await this.preloadImage(imageSource.url)
      
      // Update the image element
      this.updateImageElement(imageSource)
      
      // Trigger the progressive transition
      this.startProgressiveTransition()
      
    } catch (error) {
      this.handleImageError(error)
    }
  }

  selectOptimalImageSource() {
    // Check for WebP support
    const supportsWebP = this.supportsWebP()
    
    // Use WebP if supported and available, otherwise use JPEG
    if (supportsWebP && this.hasWebpValue) {
      return {
        url: this.webpValue,
        format: 'webp',
        srcset: this.hasSrcsetValue ? this.srcsetValue.replace(/\.jpe?g/gi, '.webp') : null
      }
    } else if (this.hasJpegValue) {
      return {
        url: this.jpegValue,
        format: 'jpeg',
        srcset: this.hasSrcsetValue ? this.srcsetValue : null
      }
    } else if (this.hasImageTarget) {
      // Fallback to data-src attribute
      return {
        url: this.imageTarget.dataset.src,
        format: 'unknown',
        srcset: this.imageTarget.dataset.srcset || null
      }
    }
    
    throw new Error('No valid image source found')
  }

  preloadImage(url) {
    return new Promise((resolve, reject) => {
      // Check cache first
      if (this.imageCache.has(url)) {
        resolve()
        return
      }

      const img = new Image()
      
      img.onload = () => {
        this.imageCache.add(url)
        resolve()
      }
      
      img.onerror = () => {
        reject(new Error(`Failed to load image: ${url}`))
      }
      
      // Set a timeout for slow connections
      const timeout = setTimeout(() => {
        reject(new Error(`Image load timeout: ${url}`))
      }, 10000) // 10 second timeout
      
      img.onload = () => {
        clearTimeout(timeout)
        this.imageCache.add(url)
        resolve()
      }
      
      img.src = url
    })
  }

  updateImageElement(imageSource) {
    if (this.hasImageTarget) {
      this.imageTarget.src = imageSource.url
      this.imageTarget.alt = this.hasAltValue ? this.altValue : ''
      
      // Add responsive attributes
      if (imageSource.srcset) {
        this.imageTarget.srcset = imageSource.srcset
      }
      
      if (this.hasSizesValue) {
        this.imageTarget.sizes = this.sizesValue
      }
    }
    
    // Handle picture elements for advanced responsive images
    if (this.hasPictureTarget) {
      this.updatePictureElement(imageSource)
    }
  }

  updatePictureElement(imageSource) {
    const picture = this.pictureTarget
    const sources = picture.querySelectorAll('source')
    
    // Update source elements with appropriate format
    sources.forEach(source => {
      const type = source.getAttribute('type')
      if (type === 'image/webp' && imageSource.format === 'webp') {
        source.srcset = this.webpValue
      } else if (type === 'image/jpeg' || !type) {
        source.srcset = this.jpegValue
      }
    })
  }

  startProgressiveTransition() {
    // Remove loading state
    this.element.classList.remove(this.loadingClass || 'progressive-loading')
    this.element.classList.add(this.loadedClass || 'progressive-loaded')
    
    // Animate out the LQIP
    if (this.lqipElement) {
      this.lqipElement.style.filter = 'blur(0px)'
      this.lqipElement.style.transform = 'scale(1)'
      this.lqipElement.style.opacity = '0'
      
      // Remove LQIP after transition
      setTimeout(() => {
        if (this.lqipElement && this.lqipElement.parentNode) {
          this.lqipElement.parentNode.removeChild(this.lqipElement)
        }
      }, this.transitionDurationValue)
    }
    
    // Fade in the high-quality image
    if (this.hasImageTarget) {
      this.imageTarget.style.opacity = '0'
      this.imageTarget.style.transition = `opacity ${this.transitionDurationValue}ms ease-in-out`
      
      // Force reflow
      this.imageTarget.offsetHeight
      
      this.imageTarget.style.opacity = '1'
    }
    
    // Mark as loaded
    this.isLoaded = true
    this.isLoading = false
    
    // Add final transition class
    setTimeout(() => {
      this.element.classList.add(this.transitionedClass || 'progressive-transitioned')
    }, this.transitionDurationValue)
    
    // Dispatch loaded event
    this.dispatch('loaded', {
      detail: {
        element: this.element,
        source: this.hasImageTarget ? this.imageTarget.src : null
      }
    })
  }

  handleImageError(error) {
    console.warn('Progressive image loading failed:', error)
    
    this.element.classList.remove(this.loadingClass || 'progressive-loading')
    this.element.classList.add(this.errorClass || 'progressive-error')
    
    this.isLoading = false
    
    // Dispatch error event
    this.dispatch('error', {
      detail: {
        element: this.element,
        error: error.message
      }
    })
  }

  // Utility methods
  
  isAboveFold() {
    const rect = this.element.getBoundingClientRect()
    const viewportHeight = window.innerHeight || document.documentElement.clientHeight
    return rect.top < viewportHeight && rect.bottom > 0
  }

  supportsWebP() {
    // Check if browser supports WebP
    if (this.webpSupported !== undefined) {
      return this.webpSupported
    }
    
    const canvas = document.createElement('canvas')
    canvas.width = 1
    canvas.height = 1
    
    this.webpSupported = canvas.toDataURL('image/webp').indexOf('webp') > -1
    return this.webpSupported
  }

  cleanupTransitions() {
    if (this.lqipElement) {
      this.lqipElement.style.transition = 'none'
    }
    
    if (this.hasImageTarget) {
      this.imageTarget.style.transition = 'none'
    }
  }

  // Public API methods
  
  reload() {
    this.isLoaded = false
    this.isLoading = false
    this.initializePlaceholder()
    this.loadImage()
  }

  forceLoad() {
    this.loadImage()
  }
}