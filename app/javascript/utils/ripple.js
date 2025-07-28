// Ripple effect utility for touch feedback
export function createRipple(event, element) {
  const ripple = document.createElement('span')
  const rect = element.getBoundingClientRect()
  
  // Calculate ripple size - should cover entire element diagonally
  const size = Math.sqrt(rect.width * rect.width + rect.height * rect.height) * 2
  
  // Position ripple at click/touch point
  const x = event.clientX - rect.left - size / 2
  const y = event.clientY - rect.top - size / 2
  
  ripple.style.width = ripple.style.height = size + 'px'
  ripple.style.left = x + 'px'
  ripple.style.top = y + 'px'
  ripple.classList.add('ripple')
  
  // Only set position if not already set
  const currentPosition = window.getComputedStyle(element).position
  if (currentPosition === 'static') {
    element.style.position = 'relative'
  }
  
  // Ensure overflow is hidden
  element.style.overflow = 'hidden'
  
  element.appendChild(ripple)
  
  // Add active class on next frame for animation
  requestAnimationFrame(() => {
    ripple.classList.add('ripple-active')
  })
  
  // Remove ripple after animation
  setTimeout(() => {
    ripple.remove()
  }, 700)
}

// Add ripple effect to an element
export function addRippleEffect(element) {
  // Only set position if not already positioned
  const currentPosition = window.getComputedStyle(element).position
  if (currentPosition === 'static') {
    element.style.position = 'relative'
  }
  element.style.overflow = 'hidden'
  
  const handleClick = (e) => {
    createRipple(e, element)
  }
  
  element.addEventListener('click', handleClick)
  
  // Return cleanup function
  return () => {
    element.removeEventListener('click', handleClick)
  }
}

export default { createRipple, addRippleEffect }