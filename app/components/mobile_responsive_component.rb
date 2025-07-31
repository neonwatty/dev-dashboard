# frozen_string_literal: true

# Base class for mobile-responsive ViewComponents
# Provides utilities and patterns for building components that work seamlessly
# across mobile and desktop viewports
class MobileResponsiveComponent < ViewComponent::Base
  # Mobile breakpoint (matches Tailwind's 'sm' breakpoint)
  MOBILE_BREAKPOINT = 640

  private

  # Returns appropriate CSS classes for mobile vs desktop layout
  # 
  # @param mobile_classes [String] Classes to apply on mobile
  # @param desktop_classes [String] Classes to apply on desktop  
  # @param shared_classes [String] Classes to apply on both
  # @return [String] Combined CSS classes
  def responsive_classes(mobile_classes: "", desktop_classes: "", shared_classes: "")
    classes = []
    classes << shared_classes if shared_classes.present?
    classes << mobile_classes if mobile_classes.present?
    
    if desktop_classes.present?
      # Split desktop classes and prefix each with sm:
      desktop_class_array = desktop_classes.split(" ").map { |cls| "sm:#{cls}" }
      classes.concat(desktop_class_array)
    end
    
    classes.join(" ").strip
  end

  # Returns mobile-optimized padding classes
  # Uses smaller padding on mobile, larger on desktop
  def mobile_padding_classes
    "px-4 py-4 sm:px-6 sm:py-6 lg:px-8 lg:py-8"
  end

  # Returns mobile-optimized spacing classes  
  def mobile_spacing_classes
    "space-y-4 sm:space-y-6 lg:space-y-8"
  end

  # Returns touch-friendly target classes
  # Ensures minimum 44px touch targets on mobile, with proper spacing
  def touch_target_classes
    "min-h-[44px] min-w-[44px] touch-target flex items-center justify-center"
  end

  # Returns enhanced touch target classes with spacing
  def enhanced_touch_target_classes
    "min-h-[44px] min-w-[44px] touch-target touch-safe-spacing flex items-center justify-center"
  end

  # Returns classes for touch-safe horizontal layouts
  def touch_safe_horizontal_classes
    "flex items-center touch-safe-horizontal"
  end

  # Returns classes for touch-safe vertical layouts  
  def touch_safe_vertical_classes
    "flex flex-col touch-safe-vertical"
  end

  # Returns mobile-first text size classes
  # 
  # @param mobile_size [String] Mobile text size (text-sm, text-base, etc.)
  # @param desktop_size [String] Desktop text size
  # @return [String] Responsive text size classes
  def responsive_text_size(mobile_size:, desktop_size: nil)
    if desktop_size.present?
      "#{mobile_size} sm:#{desktop_size}"
    else
      mobile_size
    end
  end

  # Returns mobile-optimized input classes
  # Prevents zoom on iOS by using 16px font size
  def mobile_input_classes
    "min-h-[48px] text-base sm:text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
  end

  # Returns classes for mobile card layout
  # Stacks content vertically on mobile, horizontally on desktop
  def mobile_card_layout_classes
    "flex flex-col sm:flex-row sm:items-start sm:gap-4"
  end

  # Returns classes for hiding scrollbars while keeping functionality
  def hide_scrollbar_classes
    "scrollbar-none [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
  end

  # Returns safe area padding classes for devices with home indicators
  def safe_area_classes(direction: :bottom)
    case direction
    when :bottom
      "[padding-bottom:env(safe-area-inset-bottom,1rem)]"
    when :top  
      "[padding-top:env(safe-area-inset-top,0)]"
    when :both
      "[padding-bottom:env(safe-area-inset-bottom,1rem)] [padding-top:env(safe-area-inset-top,0)]"
    else
      ""
    end
  end

  # Returns CSS classes for line clamping text
  #
  # @param lines [Integer] Number of lines to clamp to
  # @param mobile_lines [Integer] Different line count for mobile
  # @return [String] Line clamp classes
  def line_clamp_classes(lines:, mobile_lines: nil)
    if mobile_lines.present?
      "line-clamp-#{mobile_lines} sm:line-clamp-#{lines}"
    else
      "line-clamp-#{lines}"
    end
  end

  # Returns classes for mobile-optimized grid layouts
  #
  # @param mobile_cols [Integer] Number of columns on mobile
  # @param desktop_cols [Integer] Number of columns on desktop
  # @return [String] Grid column classes
  def responsive_grid_classes(mobile_cols: 1, desktop_cols: 2)
    "grid grid-cols-#{mobile_cols} sm:grid-cols-#{desktop_cols} gap-4"
  end

  # Returns animation classes for mobile interactions
  def mobile_animation_classes(type: :slide_up)
    case type
    when :slide_up
      "animate-[slideUp_0.3s_ease-out] sm:animate-none"
    when :fade_in
      "animate-[fadeIn_0.3s_ease-in-out]"
    when :slide_in_right
      "animate-[slideInRight_0.3s_ease-in-out]"
    else
      ""
    end
  end

  # Returns modal classes based on viewport
  def mobile_modal_classes
    "fixed inset-0 z-50 sm:flex sm:items-center sm:justify-center sm:p-4"
  end

  # Returns container classes for modal content
  def mobile_modal_content_classes(size: :md)
    base_classes = "relative w-full max-h-screen sm:max-h-[90vh] flex flex-col bg-white dark:bg-gray-800 sm:rounded-lg shadow-xl transform transition-all"
    
    size_classes = case size
                   when :sm then "sm:max-w-md"
                   when :lg then "sm:max-w-2xl"
                   when :xl then "sm:max-w-4xl"
                   else "sm:max-w-lg"
                   end
    
    "#{base_classes} #{size_classes}"
  end

  # Helper to determine if current request is likely from mobile device
  # Note: This is a simple heuristic and should be used carefully
  def mobile_device?
    return false unless request&.user_agent
    
    user_agent = request.user_agent.downcase
    mobile_patterns = %w[mobile android iphone ipad ipod blackberry windows phone]
    mobile_patterns.any? { |pattern| user_agent.include?(pattern) }
  end

  # Returns appropriate button size classes for mobile vs desktop
  def mobile_button_classes(style: :primary, size: :md)
    base_classes = "inline-flex items-center justify-center rounded-lg font-medium transition-colors duration-200"
    
    # Touch-friendly sizing
    size_classes = case size
                   when :sm then "px-3 py-2 text-sm"
                   when :lg then "px-6 py-3 text-base"
                   else "px-4 py-2.5 text-sm"
                   end
    
    # Style variants
    style_classes = case style
                    when :primary
                      "bg-blue-600 text-white hover:bg-blue-700 dark:bg-blue-500 dark:hover:bg-blue-600"
                    when :secondary  
                      "bg-gray-200 text-gray-900 hover:bg-gray-300 dark:bg-gray-700 dark:text-gray-100 dark:hover:bg-gray-600"
                    when :danger
                      "bg-red-600 text-white hover:bg-red-700 dark:bg-red-500 dark:hover:bg-red-600"
                    else
                      "bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                    end
    
    # Add touch target requirements
    touch_classes = touch_target_classes
    
    [base_classes, size_classes, style_classes, touch_classes].join(" ")
  end

  # Returns classes for mobile-optimized form layouts
  def mobile_form_classes
    "space-y-4 sm:space-y-6"
  end

  # Returns label classes optimized for mobile
  def mobile_label_classes
    "block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
  end

  # Returns help text classes optimized for mobile
  def mobile_help_text_classes  
    "mt-1 text-sm text-gray-500 dark:text-gray-400"
  end

  # Returns error text classes optimized for mobile
  def mobile_error_classes
    "mt-1 text-sm text-red-600 dark:text-red-400"
  end
end