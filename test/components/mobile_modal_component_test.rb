require "test_helper"

class MobileModalComponentTest < ViewComponent::TestCase
  def setup
    @component = MobileModalComponent.new(
      id: "test-modal",
      title: "Test Modal"
    )
  end

  test "renders mobile modal with required attributes" do
    render_inline(@component) do
      "Modal content"
    end

    # Should have modal wrapper with correct attributes
    assert_selector "[data-controller='modal']"
    assert_selector "[role='dialog']"
    assert_selector "[aria-modal='true']"
    assert_selector "[aria-labelledby='test-modal-title']"
  end

  test "renders with correct title" do
    render_inline(@component) do
      "Modal content"
    end

    assert_selector "#test-modal-title", text: "Test Modal"
  end

  test "renders mobile-responsive modal classes" do
    render_inline(@component) do
      "Modal content"
    end

    # Should have full-screen mobile and centered desktop classes
    assert_selector ".fixed.inset-0.z-50"
    assert_selector ".flex.min-h-screen.items-end.sm\\:items-center"
  end

  test "renders close button with touch target" do
    render_inline(@component) do
      "Modal content"
    end

    # Close button should be touch-friendly
    close_button = page.find("button[data-action*='modal#close']")
    assert_includes close_button["class"], "p-2"
    
    # Should have SVG icon
    assert_selector "button[data-action*='modal#close'] svg"
  end

  test "renders backdrop when backdrop_close is enabled" do
    @component = MobileModalComponent.new(
      id: "test-modal",
      title: "Test Modal",
      backdrop_close: true
    )

    render_inline(@component) do
      "Modal content"
    end

    backdrop = page.find(".fixed.inset-0.bg-black.bg-opacity-50")
    assert_includes backdrop["data-action"], "modal#close"
  end

  test "does not render backdrop action when backdrop_close is disabled" do
    @component = MobileModalComponent.new(
      id: "test-modal",
      title: "Test Modal",
      backdrop_close: false
    )

    render_inline(@component) do
      "Modal content"
    end

    backdrop = page.find(".fixed.inset-0.bg-black.bg-opacity-50")
    assert_not_includes backdrop["data-action"] || "", "modal#close"
  end

  test "renders different modal sizes correctly" do
    sizes_and_classes = {
      sm: "sm:max-w-md",
      md: "sm:max-w-lg", 
      lg: "sm:max-w-2xl",
      xl: "sm:max-w-4xl"
    }

    sizes_and_classes.each do |size, expected_class|
      component = MobileModalComponent.new(
        id: "test-modal-#{size}",
        title: "Test Modal",
        size: size
      )

      render_inline(component) do
        "Modal content"
      end

      assert_selector ".#{expected_class.gsub(':', '\\:')}"
    end
  end

  test "renders footer when show_footer is true" do
    @component = MobileModalComponent.new(
      id: "test-modal",
      title: "Test Modal",
      show_footer: true
    )

    render_inline(@component) do
      "Modal body content"
    end

    # Footer should be present with sticky positioning
    assert_selector ".sticky.bottom-0"
  end

  test "does not render footer when show_footer is false" do
    @component = MobileModalComponent.new(
      id: "test-modal",
      title: "Test Modal",
      show_footer: false
    )

    render_inline(@component) do
      "Modal content"
    end

    # Footer should not be present
    assert_no_selector ".sticky.bottom-0"
  end

  test "modal header is sticky on mobile" do
    render_inline(@component) do
      "Modal content"
    end

    # Header should have sticky positioning
    assert_selector ".sticky.top-0"
    assert_selector ".border-b.border-gray-200"
  end

  test "modal content area is scrollable" do
    render_inline(@component) do
      "Modal content"
    end

    # Content area should be scrollable
    assert_selector ".flex-1.overflow-y-auto"
  end

  test "modal has mobile-specific animations" do
    render_inline(@component) do
      "Modal content"
    end

    # Should include slide-up animation classes
    modal_content = page.find(".relative.w-full")
    assert_includes modal_content["class"], "transform transition-all"
  end

  test "modal renders with dark mode support" do
    render_inline(@component) do
      "Modal content"
    end

    # Should have dark mode classes
    assert_selector ".dark\\:bg-gray-800"
    assert_selector ".dark\\:border-gray-700"
  end

  test "modal content supports accessibility features" do
    render_inline(@component) do
      "Modal content"
    end

    # Should have proper ARIA attributes
    assert_selector "[role='dialog']"
    assert_selector "[aria-modal='true']" 
    assert_selector "[aria-labelledby='test-modal-title']"
    
    # Title should have correct ID
    assert_selector "#test-modal-title"
  end

  test "close button has proper accessibility attributes" do
    render_inline(@component) do
      "Modal content"
    end

    close_button = page.find("button[data-action*='modal#close']")
    
    # Should have accessible SVG with proper attributes
    svg = close_button.find("svg")
    assert_equal "currentColor", svg["stroke"]
    # Check for viewBox or similar attributes (case sensitive)
    viewbox_attr = svg["viewBox"] || svg["viewbox"]
    assert viewbox_attr.present?, "SVG should have a viewBox attribute"
  end

  test "modal wrapper is initially hidden" do
    render_inline(@component) do
      "Modal content"
    end

    # Modal wrapper should have hidden class initially
    assert_selector ".fixed.inset-0.z-50.overflow-y-auto.hidden"
  end

  test "component handles custom options" do
    @component = MobileModalComponent.new(
      id: "custom-modal",
      title: "Custom Modal",
      size: :lg,
      show_footer: true,
      backdrop_close: false,
      custom_class: "additional-class"
    )

    render_inline(@component) do
      "Custom content"
    end

    # Should render with all custom options
    assert_selector "#custom-modal-title", text: "Custom Modal"
    assert_selector ".sm\\:max-w-2xl" # lg size
    
    # Footer should be available for rendering
    # Backdrop should not have close action
    backdrop = page.find(".fixed.inset-0.bg-black.bg-opacity-50")
    assert_not_includes backdrop["data-action"] || "", "modal#close"
  end
end