// Import and start Turbo Rails (includes Turbo Streams)
import "@hotwired/turbo-rails"

console.log('Dev Dashboard loaded with Turbo')

// Debug Turbo Stream events
document.addEventListener('turbo:before-stream-render', (event) => {
  const stream = event.detail.newStream
  console.log('Turbo Stream received:', {
    action: stream.action,
    target: stream.target,
    content: stream.querySelector('template')?.innerHTML?.substring(0, 100) + '...'
  })
})
