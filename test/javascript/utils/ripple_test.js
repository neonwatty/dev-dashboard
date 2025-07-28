import { addRippleEffect } from "../../../app/javascript/utils/ripple"

describe("Ripple Effect Utility", () => {
  let element
  let cleanup

  beforeEach(() => {
    document.body.innerHTML = `
      <button style="position: relative; width: 200px; height: 50px;">
        Test Button
      </button>
    `
    element = document.querySelector('button')
  })

  afterEach(() => {
    if (cleanup) {
      cleanup()
      cleanup = null
    }
    document.body.innerHTML = ""
  })

  describe("ripple creation", () => {
    it("creates ripple element on click", () => {
      cleanup = addRippleEffect(element)
      
      const clickEvent = new MouseEvent('click', {
        bubbles: true,
        clientX: 100,
        clientY: 25
      })
      element.dispatchEvent(clickEvent)

      const ripple = element.querySelector('.ripple')
      expect(ripple).toBeTruthy()
    })

    it("positions ripple at click location", () => {
      cleanup = addRippleEffect(element)
      
      // Mock getBoundingClientRect
      element.getBoundingClientRect = jest.fn(() => ({
        left: 50,
        top: 100,
        width: 200,
        height: 50
      }))

      const clickEvent = new MouseEvent('click', {
        bubbles: true,
        clientX: 150,
        clientY: 125
      })
      element.dispatchEvent(clickEvent)

      const ripple = element.querySelector('.ripple')
      const expectedLeft = 100 - 50 // clientX - rect.left - rippleSize/2
      const expectedTop = 25 - 50  // clientY - rect.top - rippleSize/2
      
      expect(ripple.style.left).toBe(`${expectedLeft}px`)
      expect(ripple.style.top).toBe(`${expectedTop}px`)
    })

    it("sets ripple size based on element dimensions", () => {
      cleanup = addRippleEffect(element)
      
      element.getBoundingClientRect = jest.fn(() => ({
        left: 0,
        top: 0,
        width: 200,
        height: 100
      }))

      const clickEvent = new MouseEvent('click', {
        bubbles: true,
        clientX: 100,
        clientY: 50
      })
      element.dispatchEvent(clickEvent)

      const ripple = element.querySelector('.ripple')
      // Size should be based on diagonal of element
      const expectedSize = Math.sqrt(200 * 200 + 100 * 100) * 2
      
      expect(ripple.style.width).toBe(`${expectedSize}px`)
      expect(ripple.style.height).toBe(`${expectedSize}px`)
    })

    it("adds ripple-active class immediately", () => {
      cleanup = addRippleEffect(element)
      
      const clickEvent = new MouseEvent('click', {
        bubbles: true,
        clientX: 100,
        clientY: 25
      })
      element.dispatchEvent(clickEvent)

      const ripple = element.querySelector('.ripple')
      
      // Use setTimeout to check after next tick
      setTimeout(() => {
        expect(ripple.classList.contains('ripple-active')).toBe(true)
      }, 0)
    })

    it("removes ripple after animation", (done) => {
      cleanup = addRippleEffect(element)
      
      const clickEvent = new MouseEvent('click', {
        bubbles: true,
        clientX: 100,
        clientY: 25
      })
      element.dispatchEvent(clickEvent)

      const ripple = element.querySelector('.ripple')
      expect(ripple).toBeTruthy()

      // Wait for removal timeout
      setTimeout(() => {
        expect(element.querySelector('.ripple')).toBeFalsy()
        done()
      }, 800)
    })
  })

  describe("multiple ripples", () => {
    it("supports multiple concurrent ripples", () => {
      cleanup = addRippleEffect(element)
      
      // First click
      const clickEvent1 = new MouseEvent('click', {
        bubbles: true,
        clientX: 50,
        clientY: 25
      })
      element.dispatchEvent(clickEvent1)

      // Second click immediately after
      const clickEvent2 = new MouseEvent('click', {
        bubbles: true,
        clientX: 150,
        clientY: 25
      })
      element.dispatchEvent(clickEvent2)

      const ripples = element.querySelectorAll('.ripple')
      expect(ripples.length).toBe(2)
    })
  })

  describe("element styles", () => {
    it("sets position relative if not positioned", () => {
      element.style.position = 'static'
      cleanup = addRippleEffect(element)

      expect(element.style.position).toBe('relative')
    })

    it("preserves existing position styles", () => {
      element.style.position = 'absolute'
      cleanup = addRippleEffect(element)

      expect(element.style.position).toBe('absolute')
    })

    it("sets overflow hidden", () => {
      cleanup = addRippleEffect(element)

      expect(element.style.overflow).toBe('hidden')
    })
  })

  describe("cleanup", () => {
    it("removes event listener on cleanup", () => {
      const removeEventListenerSpy = jest.spyOn(element, 'removeEventListener')
      
      cleanup = addRippleEffect(element)
      cleanup()

      expect(removeEventListenerSpy).toHaveBeenCalledWith('click', expect.any(Function))
    })

    it("does not create ripples after cleanup", () => {
      cleanup = addRippleEffect(element)
      cleanup()

      const clickEvent = new MouseEvent('click', {
        bubbles: true,
        clientX: 100,
        clientY: 25
      })
      element.dispatchEvent(clickEvent)

      const ripple = element.querySelector('.ripple')
      expect(ripple).toBeFalsy()
    })
  })

  describe("edge cases", () => {
    it("handles clicks at element edges", () => {
      cleanup = addRippleEffect(element)
      
      element.getBoundingClientRect = jest.fn(() => ({
        left: 0,
        top: 0,
        width: 200,
        height: 50
      }))

      // Click at top-left corner
      const clickEvent = new MouseEvent('click', {
        bubbles: true,
        clientX: 0,
        clientY: 0
      })
      element.dispatchEvent(clickEvent)

      const ripple = element.querySelector('.ripple')
      expect(ripple).toBeTruthy()
    })

    it("handles rapid successive clicks", () => {
      cleanup = addRippleEffect(element)
      
      // Simulate rapid clicks
      for (let i = 0; i < 10; i++) {
        const clickEvent = new MouseEvent('click', {
          bubbles: true,
          clientX: 100 + i * 10,
          clientY: 25
        })
        element.dispatchEvent(clickEvent)
      }

      const ripples = element.querySelectorAll('.ripple')
      expect(ripples.length).toBe(10)
    })
  })
})