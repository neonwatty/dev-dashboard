require "test_helper"

class MobileResponsiveComponentTest < ViewComponent::TestCase
  def setup
    @component = MobileResponsiveComponent.new
  end

  # Test responsive_classes helper
  test "responsive_classes combines mobile and desktop classes correctly" do
    result = @component.send(:responsive_classes, 
                            mobile_classes: "text-sm px-2", 
                            desktop_classes: "text-lg px-4", 
                            shared_classes: "font-bold")
    
    expected = "font-bold text-sm px-2 sm:text-lg sm:px-4"
    assert_equal expected, result
  end

  test "responsive_classes works with only mobile classes" do
    result = @component.send(:responsive_classes, mobile_classes: "text-sm")
    assert_equal "text-sm", result
  end

  test "responsive_classes works with only desktop classes" do
    result = @component.send(:responsive_classes, desktop_classes: "text-lg")
    assert_equal "sm:text-lg", result
  end

  # Test mobile padding classes
  test "mobile_padding_classes returns correct responsive padding" do
    result = @component.send(:mobile_padding_classes)
    expected = "px-4 py-4 sm:px-6 sm:py-6 lg:px-8 lg:py-8"
    assert_equal expected, result
  end

  # Test mobile spacing classes
  test "mobile_spacing_classes returns correct responsive spacing" do
    result = @component.send(:mobile_spacing_classes)
    expected = "space-y-4 sm:space-y-6 lg:space-y-8"
    assert_equal expected, result
  end

  # Test touch target classes
  test "touch_target_classes includes minimum touch target size" do
    result = @component.send(:touch_target_classes)
    
    assert_includes result, "min-h-[44px]"
    assert_includes result, "min-w-[44px]"
    assert_includes result, "max-[768px]:min-h-[48px]"
    assert_includes result, "max-[768px]:min-w-[48px]"
    assert_includes result, "flex items-center justify-center"
  end

  # Test responsive text size
  test "responsive_text_size works with both mobile and desktop sizes" do
    result = @component.send(:responsive_text_size, 
                            mobile_size: "text-sm", 
                            desktop_size: "text-lg")
    
    expected = "text-sm sm:text-lg"
    assert_equal expected, result
  end

  test "responsive_text_size works with only mobile size" do
    result = @component.send(:responsive_text_size, mobile_size: "text-base")
    assert_equal "text-base", result
  end

  # Test mobile input classes
  test "mobile_input_classes prevents iOS zoom" do
    result = @component.send(:mobile_input_classes)
    
    assert_includes result, "min-h-[48px]"
    assert_includes result, "text-base"
    assert_includes result, "sm:text-sm"
    assert_includes result, "focus:ring-2"
    assert_includes result, "focus:ring-blue-500"
  end

  # Test mobile card layout classes
  test "mobile_card_layout_classes provides responsive flex layout" do
    result = @component.send(:mobile_card_layout_classes)
    expected = "flex flex-col sm:flex-row sm:items-start sm:gap-4"
    assert_equal expected, result
  end

  # Test hide scrollbar classes
  test "hide_scrollbar_classes includes cross-browser scrollbar hiding" do
    result = @component.send(:hide_scrollbar_classes)
    
    assert_includes result, "scrollbar-none"
    assert_includes result, "[-ms-overflow-style:none]"
    assert_includes result, "[scrollbar-width:none]"
    assert_includes result, "[&::-webkit-scrollbar]:hidden"
  end

  # Test safe area classes
  test "safe_area_classes handles different directions" do
    bottom_result = @component.send(:safe_area_classes, direction: :bottom)
    top_result = @component.send(:safe_area_classes, direction: :top)
    both_result = @component.send(:safe_area_classes, direction: :both)
    
    assert_equal "[padding-bottom:env(safe-area-inset-bottom,1rem)]", bottom_result
    assert_equal "[padding-top:env(safe-area-inset-top,0)]", top_result
    assert_includes both_result, "padding-bottom:env(safe-area-inset-bottom,1rem)"
    assert_includes both_result, "padding-top:env(safe-area-inset-top,0)"
  end

  # Test line clamp classes
  test "line_clamp_classes works with single line count" do
    result = @component.send(:line_clamp_classes, lines: 3)
    assert_equal "line-clamp-3", result
  end

  test "line_clamp_classes works with different mobile and desktop counts" do
    result = @component.send(:line_clamp_classes, lines: 3, mobile_lines: 2)
    expected = "line-clamp-2 sm:line-clamp-3"
    assert_equal expected, result
  end

  # Test responsive grid classes
  test "responsive_grid_classes creates mobile-first grid" do
    result = @component.send(:responsive_grid_classes, mobile_cols: 1, desktop_cols: 3)
    expected = "grid grid-cols-1 sm:grid-cols-3 gap-4"
    assert_equal expected, result
  end

  test "responsive_grid_classes uses defaults correctly" do
    result = @component.send(:responsive_grid_classes)
    expected = "grid grid-cols-1 sm:grid-cols-2 gap-4"
    assert_equal expected, result
  end

  # Test mobile animation classes
  test "mobile_animation_classes provides different animation types" do
    slide_up = @component.send(:mobile_animation_classes, type: :slide_up)
    fade_in = @component.send(:mobile_animation_classes, type: :fade_in)
    slide_in_right = @component.send(:mobile_animation_classes, type: :slide_in_right)
    
    assert_equal "animate-[slideUp_0.3s_ease-out] sm:animate-none", slide_up
    assert_equal "animate-[fadeIn_0.3s_ease-in-out]", fade_in
    assert_equal "animate-[slideInRight_0.3s_ease-in-out]", slide_in_right
  end

  # Test mobile modal classes
  test "mobile_modal_classes provides full-screen mobile modal layout" do
    result = @component.send(:mobile_modal_classes)
    expected = "fixed inset-0 z-50 sm:flex sm:items-center sm:justify-center sm:p-4"
    assert_equal expected, result
  end

  # Test mobile modal content classes
  test "mobile_modal_content_classes provides responsive modal sizing" do
    result = @component.send(:mobile_modal_content_classes, size: :lg)
    
    assert_includes result, "relative w-full max-h-screen sm:max-h-[90vh]"
    assert_includes result, "sm:max-w-2xl"
    assert_includes result, "bg-white dark:bg-gray-800"
    assert_includes result, "sm:rounded-lg"
  end

  test "mobile_modal_content_classes handles different sizes" do
    sm_result = @component.send(:mobile_modal_content_classes, size: :sm)
    lg_result = @component.send(:mobile_modal_content_classes, size: :lg)
    xl_result = @component.send(:mobile_modal_content_classes, size: :xl)
    
    assert_includes sm_result, "sm:max-w-md"
    assert_includes lg_result, "sm:max-w-2xl"
    assert_includes xl_result, "sm:max-w-4xl"
  end

  # Test mobile button classes
  test "mobile_button_classes creates touch-friendly buttons" do
    result = @component.send(:mobile_button_classes, style: :primary, size: :md)
    
    assert_includes result, "inline-flex items-center justify-center"
    assert_includes result, "px-4 py-2.5 text-sm"
    assert_includes result, "bg-blue-600 text-white hover:bg-blue-700"
    assert_includes result, "min-h-[44px] min-w-[44px]" # touch target
  end

  test "mobile_button_classes handles different styles" do
    primary = @component.send(:mobile_button_classes, style: :primary)
    secondary = @component.send(:mobile_button_classes, style: :secondary)
    danger = @component.send(:mobile_button_classes, style: :danger)
    
    assert_includes primary, "bg-blue-600 text-white"
    assert_includes secondary, "bg-gray-200 text-gray-900"
    assert_includes danger, "bg-red-600 text-white"
  end

  test "mobile_button_classes handles different sizes" do
    sm_button = @component.send(:mobile_button_classes, size: :sm)
    lg_button = @component.send(:mobile_button_classes, size: :lg)
    
    assert_includes sm_button, "px-3 py-2 text-sm"
    assert_includes lg_button, "px-6 py-3 text-base"
  end

  # Test form-related classes
  test "mobile_form_classes provides appropriate spacing" do
    result = @component.send(:mobile_form_classes)
    expected = "space-y-4 sm:space-y-6"
    assert_equal expected, result
  end

  test "mobile_label_classes provides accessible label styling" do
    result = @component.send(:mobile_label_classes)
    expected = "block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
    assert_equal expected, result
  end

  test "mobile_help_text_classes provides subtle help text styling" do
    result = @component.send(:mobile_help_text_classes)
    expected = "mt-1 text-sm text-gray-500 dark:text-gray-400"
    assert_equal expected, result
  end

  test "mobile_error_classes provides error text styling" do
    result = @component.send(:mobile_error_classes)
    expected = "mt-1 text-sm text-red-600 dark:text-red-400"
    assert_equal expected, result
  end

  # Test mobile device detection
  # Note: mobile_device? requires rendering context, so we skip this test
  # It would require mocking the request object which is complex in this test context
end