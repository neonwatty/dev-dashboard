# Virtual List Component for optimized rendering of large post lists
# Provides server-side support for virtual scrolling with proper data attributes
class VirtualListComponent < MobileResponsiveComponent
  attr_reader :posts, :total_count, :page, :per_page, :has_more, :container_class, :options

  def initialize(posts:, total_count: nil, page: 1, per_page: 20, has_more: true, container_class: "", **options)
    @posts = posts
    @total_count = total_count || posts.respond_to?(:total_count) ? posts.total_count : posts.size
    @page = page
    @per_page = per_page
    @has_more = has_more
    @container_class = container_class
    @options = options
  end

  # Estimated height per post card in pixels
  # This should match the average height of rendered post cards
  def estimated_item_height
    options[:item_height] || 250
  end

  # Buffer size for virtual scrolling (items above/below viewport)
  def buffer_size
    options[:buffer_size] || 5
  end

  # Minimum number of items required to enable virtual scrolling
  def virtual_scroll_threshold
    options[:threshold] || 50
  end

  # Whether virtual scrolling should be enabled
  def enable_virtual_scrolling?
    total_count >= virtual_scroll_threshold
  end

  # Container CSS classes with virtual scrolling specific styles
  def container_css_classes
    base_classes = "virtual-list-container #{container_class}"
    
    if enable_virtual_scrolling?
      "#{base_classes} virtual-scroll-enabled"
    else
      "#{base_classes} virtual-scroll-disabled"
    end
  end

  # Data attributes for Stimulus controller
  def stimulus_data_attributes
    {
      controller: "virtual-scroll",
      virtual_scroll_item_height_value: estimated_item_height,
      virtual_scroll_buffer_size_value: buffer_size,
      virtual_scroll_threshold_value: virtual_scroll_threshold,
      virtual_scroll_total_items_value: total_count,
      virtual_scroll_page_value: page,
      virtual_scroll_has_more_value: has_more
    }
  end

  # Viewport container attributes
  def viewport_attributes
    if enable_virtual_scrolling?
      {
        data: { virtual_scroll_target: "viewport" },
        class: "virtual-scroll-viewport",
        role: "list",
        "aria-label" => "Posts list with #{total_count} items"
      }
    else
      {
        class: "posts-list-standard",
        role: "list",
        "aria-label" => "Posts list with #{total_count} items"
      }
    end
  end

  # Spacer attributes for virtual scrolling
  def spacer_attributes
    return {} unless enable_virtual_scrolling?
    
    {
      data: { virtual_scroll_target: "spacer" },
      class: "virtual-scroll-spacer",
      style: "height: #{estimated_total_height}px;"
    }
  end

  # Loading indicator attributes
  def loading_indicator_attributes
    {
      data: { virtual_scroll_target: "loadingIndicator" },
      class: "virtual-scroll-loading hidden",
      "aria-live" => "polite"
    }
  end

  # Estimated total height for all posts
  def estimated_total_height
    total_count * estimated_item_height
  end

  # Post card data attributes
  def post_data_attributes(post)
    {
      post_id: post.id,
      post_index: posts.find_index(post) || 0
    }
  end

  # Enhanced post card rendering with virtual scroll support
  def render_post_card(post)
    content_tag :div, 
                render("posts/post_card", post: post), 
                data: post_data_attributes(post),
                class: "virtual-list-item",
                id: "virtual_post_#{post.id}"
  end

  # Render posts with proper structure for virtual scrolling
  def render_posts
    if posts.any?
      posts.map { |post| render_post_card(post) }.join.html_safe
    else
      render_empty_state
    end
  end

  # Empty state content
  def render_empty_state
    content_tag :div, class: "virtual-list-empty-state" do
      render "posts/empty_state"
    end
  end

  # Performance metrics for development
  def performance_info
    return unless Rails.env.development?
    
    {
      total_posts: total_count,
      rendered_posts: posts.size,
      virtual_scrolling: enable_virtual_scrolling?,
      estimated_height: estimated_total_height,
      memory_saved: enable_virtual_scrolling? ? "~#{((total_count - posts.size) * 0.1).round(1)}MB" : "0MB"
    }
  end

  # Accessibility helpers
  def aria_label_for_container
    if enable_virtual_scrolling?
      "Virtual scrolling posts list with #{total_count} items. Use arrow keys to navigate."
    else
      "Posts list with #{total_count} items"
    end
  end

  # Screen reader announcement for virtual scrolling state
  def virtual_scroll_announcement
    return unless enable_virtual_scrolling?
    
    content_tag :div, 
                "Virtual scrolling enabled for better performance with #{total_count} posts.",
                class: "sr-only",
                "aria-live" => "polite"
  end

  # CSS for virtual scrolling layout
  def virtual_scroll_styles
    return unless enable_virtual_scrolling?
    
    <<~CSS
      .virtual-list-container {
        height: 100%;
        overflow-y: auto;
        position: relative;
      }
      
      .virtual-scroll-viewport {
        position: relative;
        will-change: transform;
      }
      
      .virtual-scroll-spacer {
        width: 100%;
        pointer-events: none;
      }
      
      .virtual-list-item {
        position: relative;
        contain: layout style paint;
      }
      
      .virtual-scroll-loading {
        display: flex;
        justify-content: center;
        padding: 20px;
        opacity: 0.7;
      }
      
      .virtual-scroll-loading.visible {
        display: flex;
      }
      
      /* Smooth scroll behavior */
      .virtual-list-container {
        scroll-behavior: smooth;
      }
      
      /* Focus styles for keyboard navigation */
      .virtual-list-container:focus {
        outline: 2px solid #3b82f6;
        outline-offset: 2px;
      }
      
      /* Reduce motion for users who prefer it */
      @media (prefers-reduced-motion: reduce) {
        .virtual-list-container {
          scroll-behavior: auto;
        }
        
        .virtual-scroll-viewport {
          transition: none;
        }
      }
    CSS
  end

  private

  # Helper to determine if posts collection supports total_count
  def supports_total_count?
    posts.respond_to?(:total_count)
  end

  # Safe way to get total count from various collection types
  def safe_total_count
    return total_count if total_count

    if posts.respond_to?(:total_count)
      posts.total_count
    elsif posts.respond_to?(:count)
      posts.count
    else
      posts.size
    end
  end
end