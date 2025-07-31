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

  # Progressive image loading with LQIP and WebP support
  # 
  # @param src [String] The high-quality image source URL
  # @param options [Hash] HTML options and progressive loading options
  # @option options [String] :alt Alt text for the image
  # @option options [String] :lqip LQIP data URI (will be generated if not provided)
  # @option options [String] :webp WebP source URL
  # @option options [String] :sizes Responsive sizes attribute
  # @option options [String] :srcset Source set for responsive images
  # @option options [Boolean] :eager_load Skip progressive loading
  # @option options [Integer] :blur_amount Initial blur amount for LQIP (default: 10)
  # @option options [Integer] :transition_duration Transition duration in ms (default: 300)
  # @option options [Boolean] :enable_dominant_color Use dominant color background
  # @option options [String] :dominant_color Dominant color hex code
  def progressive_image_tag(src, options = {})
    return image_tag(src, options) if options[:eager_load]

    # Extract progressive loading specific options
    lqip = options.delete(:lqip)
    webp_src = options.delete(:webp) || generate_webp_url(src)
    sizes = options.delete(:sizes) || default_responsive_sizes
    srcset = options.delete(:srcset) || generate_responsive_srcset(src)
    blur_amount = options.delete(:blur_amount) || 10
    transition_duration = options.delete(:transition_duration) || 300
    enable_dominant_color = options.delete(:enable_dominant_color) { true }
    dominant_color = options.delete(:dominant_color)

    # Generate LQIP if not provided
    lqip ||= generate_lqip_for_url(src) if src.present?

    # Extract dominant color if enabled and not provided
    if enable_dominant_color && dominant_color.blank? && src.present?
      dominant_color = extract_dominant_color_for_url(src)
    end

    # Set up controller data attributes
    controller_data = {
      controller: 'progressive-image',
      progressive_image_lqip_value: lqip,
      progressive_image_webp_value: webp_src,
      progressive_image_jpeg_value: src,
      progressive_image_alt_value: options[:alt] || '',
      progressive_image_sizes_value: sizes,
      progressive_image_srcset_value: srcset,
      progressive_image_transition_duration_value: transition_duration,
      progressive_image_blur_amount_value: blur_amount,
      progressive_image_enable_dominant_color_value: enable_dominant_color,
      progressive_image_dominant_color_value: dominant_color
    }.compact

    # Merge with existing data attributes
    options[:data] = (options[:data] || {}).merge(controller_data)

    # Set up CSS classes
    css_classes = Array(options[:class])
    css_classes << 'progressive-image-container'
    options[:class] = css_classes.join(' ')

    # Create the container structure
    content_tag(:div, options) do
      # Placeholder div
      placeholder_html = content_tag(:div, '', 
        data: { progressive_image_target: 'placeholder' },
        class: 'progressive-placeholder absolute inset-0 bg-gray-200'
      )
      
      # High-quality image
      image_options = {
        data: { progressive_image_target: 'image' },
        class: 'progressive-image absolute inset-0 w-full h-full object-cover opacity-0',
        loading: 'lazy' # Fallback for browsers without JS
      }
      image_html = tag(:img, image_options)
      
      placeholder_html + image_html
    end
  end

  # Progressive image with responsive picture element
  # 
  # @param sources [Hash] Hash of image sources by format/size
  # @param fallback_src [String] Fallback image source
  # @param options [Hash] Options for progressive loading
  def progressive_picture_tag(sources, fallback_src, options = {})
    return picture_tag(sources, fallback_src, options) if options[:eager_load]

    # Extract progressive options
    lqip = options.delete(:lqip) || generate_lqip_for_url(fallback_src)
    transition_duration = options.delete(:transition_duration) || 300
    blur_amount = options.delete(:blur_amount) || 10

    # Set up controller data
    controller_data = {
      controller: 'progressive-image',
      progressive_image_lqip_value: lqip,
      progressive_image_transition_duration_value: transition_duration,  
      progressive_image_blur_amount_value: blur_amount
    }

    options[:data] = (options[:data] || {}).merge(controller_data)

    # Create progressive picture element
    content_tag(:div, options.merge(class: 'progressive-picture-container relative')) do
      # Placeholder
      placeholder_html = content_tag(:div, '',
        data: { progressive_image_target: 'placeholder' },
        class: 'progressive-placeholder absolute inset-0 bg-gray-200'
      )
      
      # Picture element
      picture_html = content_tag(:picture, 
        data: { progressive_image_target: 'picture' },
        class: 'progressive-picture absolute inset-0 w-full h-full opacity-0'
      ) do
        source_tags = sources.map do |format, src|
          tag(:source, srcset: src, type: "image/#{format}")
        end.join.html_safe
        
        fallback_img = tag(:img, 
          src: fallback_src,
          data: { progressive_image_target: 'image' },
          class: 'w-full h-full object-cover',
          alt: options[:alt] || ''
        )
        
        source_tags + fallback_img
      end
      
      placeholder_html + picture_html
    end
  end

  # Generate WebP URL from JPEG/PNG URL
  # @param url [String] Original image URL
  # @return [String] WebP URL
  def generate_webp_url(url)
    return nil unless url.present?
    
    # Simple URL transformation for WebP
    # In a real app, this would integrate with your CDN or image service
    url.gsub(/\.(jpe?g|png)$/i, '.webp')
  end

  # Generate responsive srcset for an image
  # @param base_url [String] Base image URL
  # @param sizes [Array] Array of sizes to generate
  # @return [String] Srcset string
  def generate_responsive_srcset(base_url, sizes = nil)
    return nil unless base_url.present?
    
    sizes ||= Rails.application.config.responsive_image_sizes || [320, 480, 768, 1024, 1200, 1920]
    
    srcset_parts = sizes.map do |size|
      responsive_url = generate_responsive_url(base_url, size)
      "#{responsive_url} #{size}w"
    end
    
    srcset_parts.join(', ')
  end

  # Generate responsive image URL for a specific size
  # @param base_url [String] Base image URL  
  # @param size [Integer] Width in pixels
  # @return [String] Responsive image URL
  def generate_responsive_url(base_url, size)
    # This is a placeholder implementation
    # In production, integrate with your CDN or image processing service
    # Examples: Cloudinary, ImageKit, or custom Active Storage variants
    
    base_name = File.basename(base_url, '.*')
    extension = File.extname(base_url)
    directory = File.dirname(base_url)
    
    "#{directory}/#{base_name}_#{size}w#{extension}"
  end

  # Default responsive sizes attribute
  # @return [String] Sizes attribute for responsive images
  def default_responsive_sizes
    "(max-width: 320px) 280px, (max-width: 480px) 440px, (max-width: 768px) 728px, (max-width: 1024px) 984px, (max-width: 1200px) 1160px, 1920px"
  end

  # Generate LQIP for external URL (cached)
  # @param url [String] Image URL
  # @return [String, nil] LQIP data URI or nil if generation fails
  def generate_lqip_for_url(url)
    return nil unless url.present?
    
    cache_key = "lqip/#{Digest::MD5.hexdigest(url)}"
    
    Rails.cache.fetch(cache_key, expires_in: Rails.application.config.image_processing_cache_duration) do
      begin
        ImageProcessingInstrumentation.instrument('lqip_generated', source: url) do
          # In production, you'd want to process this asynchronously
          # For now, we'll return a simple placeholder
          generate_simple_lqip_placeholder
        end
      rescue => e
        Rails.logger.warn "Failed to generate LQIP for #{url}: #{e.message}"
        nil
      end
    end
  end

  # Extract dominant color for external URL (cached)
  # @param url [String] Image URL
  # @return [String] Hex color code
  def extract_dominant_color_for_url(url)
    return '#f3f4f6' unless url.present?
    
    cache_key = "dominant_color/#{Digest::MD5.hexdigest(url)}"
    
    Rails.cache.fetch(cache_key, expires_in: Rails.application.config.image_processing_cache_duration) do
      begin
        # Simple color extraction based on URL or other heuristics
        # In production, this would analyze the actual image
        extract_color_from_context(url)
      rescue => e
        Rails.logger.warn "Failed to extract dominant color for #{url}: #{e.message}"
        '#f3f4f6'
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

  # Generate a simple LQIP placeholder
  # @return [String] Data URI for LQIP
  def generate_simple_lqip_placeholder
    # Create a simple 32x20 pixel gradient placeholder
    width, height = 32, 20
    
    svg = <<~SVG
      <svg width="#{width}" height="#{height}" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#e5e7eb;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#f3f4f6;stop-opacity:1" />
          </linearGradient>
        </defs>
        <rect width="100%" height="100%" fill="url(#grad)" />
        <circle cx="50%" cy="50%" r="3" fill="#d1d5db" opacity="0.5" />
      </svg>
    SVG
    
    "data:image/svg+xml;base64,#{Base64.strict_encode64(svg.strip)}"
  end

  # Extract color based on URL context or patterns
  # @param url [String] Image URL
  # @return [String] Hex color code
  def extract_color_from_context(url)
    # Simple heuristic-based color extraction
    # In production, you'd want actual image analysis
    
    case url.downcase
    when /github/
      '#24292e'
    when /reddit/
      '#ff4500'
    when /hugging.*face/
      '#ff6b00'
    when /pytorch/
      '#ee4c2c'
    when /hacker.*news/
      '#ff6600'
    else
      # Generate a subtle color based on URL hash
      hash = Digest::MD5.hexdigest(url)
      hue = hash[0..1].to_i(16) * 360 / 255
      "hsl(#{hue}, 20%, 85%)"
    end
  end
end