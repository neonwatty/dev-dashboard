module ApplicationHelper
  def status_color(status)
    case status
    when 'unread'
      'blue'
    when 'read'
      'green'
    when 'ignored'
      'gray'
    when 'responded'
      'purple'
    else
      'gray'
    end
  end

  def source_type_color(source_type)
    case source_type
    when 'discourse'
      'blue'
    when 'github'
      'gray'
    when 'reddit'
      'orange'
    when 'rss'
      'green'
    else
      'gray'
    end
  end

  def source_display_color(source_name)
    return 'blue' if source_name.nil? || source_name.empty?
    case source_name.downcase
    when 'huggingface'
      'yellow'
    when 'pytorch'
      'orange'
    when 'github'
      'gray'
    when 'reddit'
      'orange'
    when 'rss'
      'green'
    when 'hackernews'
      'orange'
    else
      'blue'
    end
  end
  
  def source_display_badge_class(source_name)
    color = source_display_color(source_name)
    case color
    when 'yellow'
      'bg-yellow-500'
    when 'orange'
      'bg-orange-500'
    when 'gray'
      'bg-gray-500'
    when 'green'
      'bg-green-500'
    when 'blue'
      'bg-blue-500'
    else
      'bg-blue-500'
    end
  end
  
  def source_type_badge_class(source_type)
    case source_type
    when 'discourse'
      'bg-blue-500'
    when 'github'
      'bg-gray-500'
    when 'reddit'
      'bg-orange-500'
    when 'rss'
      'bg-green-500'
    else
      'bg-gray-500'
    end
  end
  
  
  def source_identifier_for(source)
    case source.source_type
    when 'discourse'
      if source.url.include?('huggingface.co')
        'huggingface'
      elsif source.url.include?('pytorch.org')
        'pytorch'
      else
        'discourse'
      end
    when 'github'
      'github'
    when 'reddit'
      'reddit'
    when 'rss'
      if source.url.include?('news.ycombinator.com') || (source.name&.downcase&.include?('hacker news'))
        'hackernews'
      else
        'rss'
      end
    else
      source.source_type
    end
  end
  
  def source_icon_bg_class(source_name)
    case source_name.to_s.downcase
    when 'github', 'github_issues', 'github_trending'
      'bg-gray-900'
    when 'huggingface'
      'bg-yellow-500'
    when 'pytorch'
      'bg-orange-600'
    when 'reddit'
      'bg-orange-500'
    when 'hackernews'
      'bg-orange-600'
    when 'rss'
      'bg-green-600'
    else
      'bg-blue-600'
    end
  end
  
  def status_badge_class(status)
    case status
    when 'unread'
      'bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200'
    when 'read'
      'bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200'
    when 'ignored'
      'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-200'
    when 'responded'
      'bg-purple-100 dark:bg-purple-900 text-purple-800 dark:text-purple-200'
    else
      'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-200'
    end
  end

  # Mobile-responsive helper methods
  
  # Detects if the current request is likely from a mobile device
  def mobile_device?
    return false unless request&.user_agent
    
    user_agent = request.user_agent.downcase
    mobile_patterns = %w[mobile android iphone ipad ipod blackberry windows phone]
    mobile_patterns.any? { |pattern| user_agent.include?(pattern) }
  end

  # Returns responsive CSS classes for mobile vs desktop layouts
  def responsive_classes(mobile_classes: "", desktop_classes: "", shared_classes: "")
    classes = []
    classes << shared_classes if shared_classes.present?
    classes << mobile_classes if mobile_classes.present?
    classes << "sm:#{desktop_classes}" if desktop_classes.present?
    classes.join(" ").strip
  end

  # Returns mobile-optimized padding classes
  def mobile_padding_classes
    "px-4 py-4 sm:px-6 sm:py-6 lg:px-8 lg:py-8"
  end

  # Returns mobile-optimized spacing classes  
  def mobile_spacing_classes
    "space-y-4 sm:space-y-6 lg:space-y-8"
  end

  # Returns touch-friendly target classes
  def touch_target_classes
    "min-h-[44px] min-w-[44px] max-[768px]:min-h-[48px] max-[768px]:min-w-[48px] flex items-center justify-center"
  end

  # Returns mobile-first text size classes
  def responsive_text_size(mobile_size:, desktop_size: nil)
    if desktop_size.present?
      "#{mobile_size} sm:#{desktop_size}"
    else
      mobile_size
    end
  end

  # Returns mobile-optimized input classes
  def mobile_input_classes
    "min-h-[48px] text-base sm:text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
  end

  # Returns classes for mobile card layout
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
  def line_clamp_classes(lines:, mobile_lines: nil)
    if mobile_lines.present?
      "line-clamp-#{mobile_lines} sm:line-clamp-#{lines}"
    else
      "line-clamp-#{lines}"
    end
  end

  # Returns classes for mobile-optimized grid layouts
  def responsive_grid_classes(mobile_cols: 1, desktop_cols: 2)
    "grid grid-cols-#{mobile_cols} sm:grid-cols-#{desktop_cols} gap-4"
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

  # Helper method for the existing normalize_sources_param method
  def normalize_sources_param(sources)
    return [] unless sources.present?
    sources.is_a?(Array) ? sources : [sources]
  end

  # Helper method for checking if source is selected
  def source_selected?(source, selected_sources)
    normalize_sources_param(selected_sources).include?(source)
  end
end
