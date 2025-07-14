import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="post-actions"
export default class extends Controller {
  static targets = [ "card", "buttons", "readButton", "clearButton", "respondButton" ]
  
  connect() {
    console.log("✅ Post actions controller connected")
  }
  
  // Mark post as ignored/cleared - removes from view
  async clear(event) {
    event.preventDefault()
    const button = event.currentTarget
    const url = button.dataset.url
    
    console.log('Clear button clicked, URL:', url)
    
    // Disable button and show loading state
    this.setLoadingState(button, true)
    
    try {
      const response = await fetch(url, {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': this.csrfToken,
          'Accept': 'text/vnd.turbo-stream.html, text/html, application/json',
          'Content-Type': 'application/json'
        },
        credentials: 'same-origin'
      })
      
      console.log('Response status:', response.status)
      
      if (!response.ok) {
        // Check if it's an auth issue
        if (response.status === 401 || response.status === 302) {
          window.location.href = '/session/new'
          return
        }
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      // Get the response content type
      const contentType = response.headers.get('content-type') || ''
      console.log('Response content-type:', contentType)
      
      if (contentType.includes('text/vnd.turbo-stream.html')) {
        // Handle Turbo Stream response
        const text = await response.text()
        console.log('Turbo Stream response received, processing...')
        
        // Use Turbo's built-in handler
        if (window.Turbo) {
          window.Turbo.renderStreamMessage(text)
        } else {
          // Fallback: manually remove the card
          this.removeCard()
        }
      } else {
        // For any other response type, just remove the card
        this.removeCard()
        this.updatePostCount()
      }
      
    } catch (error) {
      console.error('Error clearing post:', error)
      this.setLoadingState(button, false)
      this.showError('Failed to clear post. Please try again.')
    }
  }
  
  // Mark post as read - updates status badge
  async markAsRead(event) {
    event.preventDefault()
    const button = event.currentTarget
    const url = button.dataset.url
    
    console.log('Mark as read clicked, URL:', url)
    
    this.setLoadingState(button, true)
    
    try {
      const response = await fetch(url, {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': this.csrfToken,
          'Accept': 'text/vnd.turbo-stream.html, text/html, application/json',
          'Content-Type': 'application/json'
        },
        credentials: 'same-origin'
      })
      
      if (!response.ok) {
        if (response.status === 401 || response.status === 302) {
          window.location.href = '/session/new'
          return
        }
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      const contentType = response.headers.get('content-type') || ''
      
      if (contentType.includes('text/vnd.turbo-stream.html')) {
        const text = await response.text()
        if (window.Turbo) {
          window.Turbo.renderStreamMessage(text)
        } else {
          this.updateStatusBadge('read')
          button.remove()
        }
      } else {
        // Manual update for non-Turbo responses
        this.updateStatusBadge('read')
        button.remove()
      }
      
    } catch (error) {
      console.error('Error marking post as read:', error)
      this.setLoadingState(button, false)
      this.showError('Failed to mark post as read. Please try again.')
    }
  }
  
  // Mark post as responded - updates status badge
  async markAsResponded(event) {
    event.preventDefault()
    const button = event.currentTarget
    const url = button.dataset.url
    
    console.log('Mark as responded clicked, URL:', url)
    
    this.setLoadingState(button, true)
    
    try {
      const response = await fetch(url, {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': this.csrfToken,
          'Accept': 'text/vnd.turbo-stream.html, text/html, application/json',
          'Content-Type': 'application/json'
        },
        credentials: 'same-origin'
      })
      
      if (!response.ok) {
        if (response.status === 401 || response.status === 302) {
          window.location.href = '/session/new'
          return
        }
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      const contentType = response.headers.get('content-type') || ''
      
      if (contentType.includes('text/vnd.turbo-stream.html')) {
        const text = await response.text()
        if (window.Turbo) {
          window.Turbo.renderStreamMessage(text)
        } else {
          this.updateStatusBadge('responded')
          button.remove()
        }
      } else {
        // Manual update for non-Turbo responses
        this.updateStatusBadge('responded')
        button.remove()
      }
      
    } catch (error) {
      console.error('Error marking post as responded:', error)
      this.setLoadingState(button, false)
      this.showError('Failed to mark post as responded. Please try again.')
    }
  }
  
  // Helper methods
  
  get csrfToken() {
    const token = document.querySelector('meta[name="csrf-token"]')?.content || ''
    console.log('CSRF Token found:', token.substring(0, 20) + '...')
    return token
  }
  
  setLoadingState(button, loading) {
    if (loading) {
      button.disabled = true
      button.classList.add('opacity-50', 'cursor-not-allowed')
      // Store original HTML
      button.dataset.originalHtml = button.innerHTML
      button.innerHTML = `
        <svg class="animate-spin h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
      `
    } else {
      button.disabled = false
      button.classList.remove('opacity-50', 'cursor-not-allowed')
      if (button.dataset.originalHtml) {
        button.innerHTML = button.dataset.originalHtml
      }
    }
  }
  
  removeCard() {
    console.log('Removing card...')
    // Add fade out animation
    this.cardTarget.style.transition = 'opacity 0.3s ease-out, transform 0.3s ease-out'
    this.cardTarget.style.opacity = '0'
    this.cardTarget.style.transform = 'translateX(-20px)'
    
    // Remove the entire turbo frame after animation
    setTimeout(() => {
      const turboFrame = this.element.closest('turbo-frame')
      if (turboFrame) {
        turboFrame.remove()
      } else {
        this.element.remove()
      }
    }, 300)
  }
  
  updateStatusBadge(newStatus) {
    console.log('Updating status badge to:', newStatus)
    const badge = this.element.querySelector('[data-status-badge]')
    if (badge) {
      // Update badge text
      badge.textContent = newStatus.charAt(0).toUpperCase() + newStatus.slice(1)
      
      // Update badge classes based on status
      badge.className = 'inline-flex items-center px-2.5 py-1 rounded-md text-xs font-medium '
      
      switch(newStatus) {
        case 'read':
          badge.className += 'bg-green-100 text-green-800'
          break
        case 'responded':
          badge.className += 'bg-blue-100 text-blue-800'
          break
        default:
          badge.className += 'bg-gray-100 text-gray-800'
      }
    }
  }
  
  updatePostCount() {
    // Update the post count in the navigation
    const postCountElement = document.getElementById('post-count')
    if (postCountElement) {
      const currentText = postCountElement.textContent
      const match = currentText.match(/Posts: (\d+)/)
      if (match) {
        const currentCount = parseInt(match[1])
        postCountElement.textContent = `Posts: ${currentCount - 1}`
      }
    }
  }
  
  showError(message) {
    console.error('Error:', message)
    
    // Show a notification
    const notificationsContainer = document.getElementById('notifications')
    if (notificationsContainer) {
      const notification = document.createElement('div')
      notification.innerHTML = `
        <div class="fixed top-4 right-4 bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded shadow-lg"
             data-controller="notification"
             data-notification-delay-value="5000">
          <div class="flex items-center">
            <svg class="h-5 w-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
            </svg>
            <span>${message}</span>
          </div>
        </div>
      `
      notificationsContainer.appendChild(notification.firstElementChild)
    } else {
      // Fallback to alert
      alert(message)
    }
  }
}