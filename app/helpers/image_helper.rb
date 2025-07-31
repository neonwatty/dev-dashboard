# frozen_string_literal: true

module ImageHelper
  # Generate a lazy-loaded image tag with placeholder
  # 
  # @param src [String] The image source URL
  # @param options [Hash] HTML options for the image tag
  # @option options [String] :alt Alt text for the image
  # @option options [String] :placeholder_class CSS classes for placeholder
  # @option options [String] :loading_class CSS classes for loading state
  # @option options [Boolean] :eager_load Skip lazy loading and load immediately
  # @option options [String] :placeholder_content Custom placeholder content
  def lazy_image_tag(src, options = {})
    return image_tag(src, options) if options[:eager_load]

    # Extract lazy loading specific options
    placeholder_class = options.delete(:placeholder_class) || 'lazy-placeholder'
    loading_class = options.delete(:loading_class) || 'lazy-loading'
    placeholder_content = options.delete(:placeholder_content)
    
    # Add lazy loading classes to the image
    css_classes = Array(options[:class])
    css_classes << loading_class
    options[:class] = css_classes.join(' ')
    
    # Set data attributes for lazy loading
    options[:data] ||= {}
    options[:data][:src] = src
    options[:data][:alt] = options[:alt] || ''
    options[:data][:lazy_load_target] = 'image'
    
    # Remove src to prevent immediate loading
    options.delete(:src)
    
    # Create placeholder content
    placeholder_html = if placeholder_content
      content_tag(:div, placeholder_content, class: placeholder_class)
    else
      lazy_placeholder_content(placeholder_class)
    end
    
    # Create the image container
    content_tag(:div, 
      placeholder_html + tag(:img, options),
      data: { 
        lazy_load_target: 'placeholder',
        controller: 'lazy-load'
      },
      class: 'lazy-image-container'
    )
  end

  # Generate a lazy-loaded background image div
  #
  # @param src [String] The background image source URL
  # @param content [String] Content to display over the background
  # @param options [Hash] HTML options for the container div
  def lazy_background_image(src, content = '', options = {})
    return content_tag(:div, content, options.merge(style: "background-image: url(#{src})")) if options[:eager_load]

    # Extract lazy loading specific options
    placeholder_class = options.delete(:placeholder_class) || 'lazy-placeholder'
    loading_class = options.delete(:loading_class) || 'lazy-loading'
    
    # Add lazy loading classes
    css_classes = Array(options[:class])
    css_classes << loading_class
    options[:class] = css_classes.join(' ')
    
    # Set data attributes for lazy loading
    options[:data] ||= {}
    options[:data][:src] = src
    options[:data][:lazy_load_target] = 'image'
    options[:data][:controller] = 'lazy-load'
    
    # Create placeholder content
    placeholder_html = lazy_placeholder_content(placeholder_class)
    
    content_tag(:div, placeholder_html + content, options)
  end

  # Generate community icon with lazy loading
  # Specialized method for the landing page community icons
  #
  # @param platform [String] The platform name (github, reddit, etc.)
  # @param options [Hash] Options for customization
  # @option options [String] :icon_content The icon content (emoji, svg, etc.)
  # @option options [String] :title The display title
  # @option options [String] :subtitle The subtitle text
  # @option options [Boolean] :eager_load Skip lazy loading for critical icons
  def community_icon(platform, options = {})
    icon_content = options[:icon_content] || platform_icon_content(platform)
    title = options[:title] || platform.titleize
    subtitle = options[:subtitle] || platform_subtitle(platform)
    eager_load = options[:eager_load] || false
    
    container_classes = %w[flex flex-col items-center]
    card_classes = %w[bg-white rounded-lg shadow-md p-4 sm:p-6 w-full h-full flex flex-col items-center justify-center]
    
    # Create the community icon card
    content_tag(:div, class: container_classes.join(' ')) do
      content_tag(:div, class: card_classes.join(' ')) do
        icon_html = if icon_content.include?('<svg')
          # Handle SVG icons with lazy loading
          if eager_load
            raw(icon_content)
          else
            lazy_svg_icon(icon_content, class: 'h-10 w-10 mb-2', alt: "#{title} icon")
          end
        else
          # Handle emoji or text icons
          content_tag(:div, raw(icon_content), class: 'text-4xl mb-2')
        end
        
        icon_html +
        content_tag(:h4, title, class: 'font-semibold text-gray-900') +
        content_tag(:p, subtitle, class: 'text-sm text-gray-600 mt-1')
      end
    end
  end

  private

  # Generate default placeholder content for lazy loaded images
  def lazy_placeholder_content(css_class)
    content_tag(:div, '', class: "#{css_class} animate-pulse bg-gray-200 rounded")
  end

  # Generate lazy-loaded SVG content
  def lazy_svg_icon(svg_content, options = {})
    placeholder_class = options.delete(:placeholder_class) || 'lazy-placeholder'
    loading_class = options.delete(:loading_class) || 'lazy-loading'
    
    css_classes = Array(options[:class])
    css_classes << loading_class
    options[:class] = css_classes.join(' ')
    
    # Create a data URI for the SVG
    svg_data_uri = "data:image/svg+xml;base64,#{Base64.strict_encode64(svg_content)}"
    
    options[:data] ||= {}
    options[:data][:src] = svg_data_uri
    options[:data][:lazy_load_target] = 'image'
    
    placeholder_html = lazy_placeholder_content(placeholder_class)
    
    content_tag(:div,
      placeholder_html + tag(:img, options),
      data: { 
        lazy_load_target: 'placeholder',
        controller: 'lazy-load'
      },
      class: 'lazy-image-container'
    )
  end

  # Get platform-specific icon content
  def platform_icon_content(platform)
    case platform.to_s.downcase
    when 'huggingface'
      '🤗'
    when 'pytorch'
      '🔥'
    when 'github'
      '<svg class="h-10 w-10 mb-2" fill="currentColor" viewBox="0 0 24 24">
        <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
      </svg>'
    when 'reddit'
      '<svg class="h-10 w-10 mb-2 text-orange-500" fill="currentColor" viewBox="0 0 24 24">
        <path d="M14.238 15.348c.085.084.085.221 0 .306-.465.462-1.194.687-2.231.687l-.008-.002-.008.002c-1.036 0-1.766-.225-2.231-.688-.085-.084-.085-.221 0-.305.084-.084.222-.084.307 0 .379.377 1.008.561 1.924.561l.008.002.008-.002c.915 0 1.544-.184 1.924-.561.085-.084.223-.084.307 0zm-3.44-2.418c0-.507-.414-.919-.922-.919-.509 0-.923.412-.923.919 0 .506.414.918.923.918.508.001.922-.411.922-.918zm13.202-.93c0 6.627-5.373 12-12 12s-12-5.373-12-12 5.373-12 12-12 12 5.373 12 12zm-5-.129c0-.851-.695-1.543-1.55-1.543-.417 0-.795.167-1.074.435-1.056-.695-2.485-1.137-4.066-1.194l.865-2.724 2.343.549-.003.034c0 .696.569 1.262 1.268 1.262.699 0 1.267-.566 1.267-1.262s-.568-1.262-1.267-1.262c-.537 0-.994.335-1.179.804l-2.525-.592c-.11-.027-.223.037-.257.145l-.965 3.038c-1.656.02-3.155.466-4.258 1.181-.277-.255-.644-.415-1.05-.415-.854.001-1.549.693-1.549 1.544 0 .566.311 1.056.768 1.325-.03.164-.05.331-.05.5 0 2.281 2.805 4.137 6.253 4.137s6.253-1.856 6.253-4.137c0-.16-.017-.317-.044-.472.486-.261.82-.766.82-1.353zm-4.872.141c-.509 0-.922.412-.922.919 0 .506.414.918.922.918s.922-.412.922-.918c0-.507-.413-.919-.922-.919z"/>
      </svg>'
    when 'hackernews'
      '<div class="bg-orange-500 text-white font-bold text-2xl w-10 h-10 flex items-center justify-center mb-2">Y</div>'
    else
      '📊' # Default icon
    end
  end

  # Get platform-specific subtitle
  def platform_subtitle(platform)
    case platform.to_s.downcase
    when 'huggingface'
      'Forums'
    when 'pytorch'
      'Forums'
    when 'github'
      'Issues & Trending'
    when 'reddit'
      'Subreddits'
    when 'hackernews'
      'RSS Feeds'
    else
      'Community'
    end
  end
end