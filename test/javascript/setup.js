// Jest setup file for JavaScript tests

// Mock Touch constructor for older Jest versions
global.Touch = class Touch {
  constructor(props) {
    Object.assign(this, {
      identifier: 0,
      target: null,
      clientX: 0,
      clientY: 0,
      screenX: 0,
      screenY: 0,
      pageX: 0,
      pageY: 0,
      radiusX: 1,
      radiusY: 1,
      rotationAngle: 0,
      force: 1,
      ...props
    })
  }
}

// Mock TouchEvent constructor
global.TouchEvent = class TouchEvent extends Event {
  constructor(type, props = {}) {
    super(type, props)
    this.touches = props.touches || []
    this.targetTouches = props.targetTouches || []
    this.changedTouches = props.changedTouches || []
  }
}

// Mock performance.memory for memory tests
Object.defineProperty(performance, 'memory', {
  writable: true,
  value: {
    usedJSHeapSize: 1000000,
    totalJSHeapSize: 2000000,
    jsHeapSizeLimit: 3000000
  }
})

// Mock window.navigator.vibrate for haptic tests
global.navigator.vibrate = jest.fn()

// Mock HapticFeedback for touch feedback tests
global.HapticFeedback = {
  light: jest.fn(),
  medium: jest.fn(),
  heavy: jest.fn(),
  selection: jest.fn(),
  success: jest.fn(),
  warning: jest.fn(),
  error: jest.fn()
}

// Mock IntersectionObserver
global.IntersectionObserver = class IntersectionObserver {
  constructor() {}
  observe() { return null }
  unobserve() { return null }
  disconnect() { return null }
}

// Mock ResizeObserver
global.ResizeObserver = class ResizeObserver {
  constructor() {}
  observe() { return null }
  unobserve() { return null }
  disconnect() { return null }
}

// Set up default window dimensions
Object.defineProperty(window, 'innerWidth', {
  writable: true,
  configurable: true,
  value: 1024
})

Object.defineProperty(window, 'innerHeight', {
  writable: true,
  configurable: true,
  value: 768
})

// Mock requestAnimationFrame
global.requestAnimationFrame = (callback) => {
  setTimeout(callback, 16)
}

// Mock Turbo
global.Turbo = {
  renderStreamMessage: jest.fn(),
  visit: jest.fn()
}