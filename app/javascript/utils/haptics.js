export class HapticFeedback {
  static isSupported() {
    return 'vibrate' in navigator
  }

  static light() {
    if (this.isSupported()) {
      navigator.vibrate(10)
    }
  }

  static medium() {
    if (this.isSupported()) {
      navigator.vibrate(25)
    }
  }

  static heavy() {
    if (this.isSupported()) {
      navigator.vibrate(50)
    }
  }

  static success() {
    if (this.isSupported()) {
      navigator.vibrate([25, 50, 25])
    }
  }

  static error() {
    if (this.isSupported()) {
      navigator.vibrate([50, 100, 50, 100, 50])
    }
  }

  static selection() {
    this.light()
  }

  static impact(style = 'medium') {
    switch (style) {
      case 'light':
        this.light()
        break
      case 'heavy':
        this.heavy()
        break
      default:
        this.medium()
    }
  }

  static notification(type = 'success') {
    switch (type) {
      case 'error':
      case 'warning':
        this.error()
        break
      case 'success':
      default:
        this.success()
    }
  }
}

// Export as default for convenience
export default HapticFeedback