# frozen_string_literal: true

# Mobile-responsive button component
# Provides consistent, touch-friendly buttons with proper sizing and accessibility
class ButtonComponent < MobileResponsiveComponent
  def initialize(
    style: :primary,
    size: :md,
    type: :button,
    url: nil,
    method: nil,
    disabled: false,
    loading: false,
    icon: nil,
    icon_position: :left,
    full_width: false,
    **attributes
  )
    @style = style
    @size = size
    @type = type
    @url = url
    @method = method
    @disabled = disabled
    @loading = loading
    @icon = icon
    @icon_position = icon_position
    @full_width = full_width
    @attributes = attributes
  end

  private

  attr_reader :style, :size, :type, :url, :method, :disabled, :loading, :icon, :icon_position, :full_width, :attributes

  def button_classes
    classes = [mobile_button_classes(style: style, size: size)]
    classes << "w-full" if full_width
    classes << "opacity-50 cursor-not-allowed" if disabled || loading
    classes.join(" ")
  end

  def button_attributes
    attrs = {
      class: button_classes,
      disabled: disabled || loading
    }.merge(attributes)

    if url.present?
      attrs[:href] = url
      attrs[:data] ||= {}
      attrs[:data][:method] = method if method.present?
    else
      attrs[:type] = type
    end

    attrs
  end

  def icon_classes
    case size
    when :sm
      "w-4 h-4"
    when :lg
      "w-6 h-6"
    else
      "w-5 h-5"
    end
  end

  def icon_margin_classes
    if icon_position == :left
      content.present? ? "mr-2" : ""
    else
      content.present? ? "ml-2" : ""
    end
  end

  def loading_spinner_svg
    <<~SVG.html_safe
      <svg class="animate-spin #{icon_classes} #{icon_margin_classes}" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
    SVG
  end

  def render_icon
    return loading_spinner_svg if loading
    return "" unless icon.present?

    if icon.is_a?(String) && icon.include?('<svg')
      # Raw SVG string
      icon.gsub(/class="[^"]*"/, "class=\"#{icon_classes} #{icon_margin_classes}\"").html_safe
    elsif icon.is_a?(Symbol) || icon.is_a?(String)
      # Icon name - render predefined icons
      render_predefined_icon(icon)
    else
      ""
    end
  end

  def render_predefined_icon(icon_name)
    case icon_name.to_s
    when 'check', 'checkmark'
      <<~SVG.html_safe
        <svg class="#{icon_classes} #{icon_margin_classes}" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
        </svg>
      SVG
    when 'plus', 'add'
      <<~SVG.html_safe
        <svg class="#{icon_classes} #{icon_margin_classes}" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
        </svg>
      SVG
    when 'edit', 'pencil'
      <<~SVG.html_safe
        <svg class="#{icon_classes} #{icon_margin_classes}" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
        </svg>
      SVG
    when 'trash', 'delete'
      <<~SVG.html_safe
        <svg class="#{icon_classes} #{icon_margin_classes}" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
        </svg>
      SVG
    when 'save', 'download'
      <<~SVG.html_safe
        <svg class="#{icon_classes} #{icon_margin_classes}" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4"></path>
        </svg>
      SVG
    when 'close', 'x'
      <<~SVG.html_safe
        <svg class="#{icon_classes} #{icon_margin_classes}" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
        </svg>
      SVG
    when 'search'
      <<~SVG.html_safe
        <svg class="#{icon_classes} #{icon_margin_classes}" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
        </svg>
      SVG
    when 'arrow-right'
      <<~SVG.html_safe
        <svg class="#{icon_classes} #{icon_margin_classes}" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 8l4 4m0 0l-4 4m4-4H3"></path>
        </svg>
      SVG
    when 'arrow-left'
      <<~SVG.html_safe
        <svg class="#{icon_classes} #{icon_margin_classes}" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16l-4-4m0 0l4-4m-4 4h18"></path>
        </svg>
      SVG
    else
      ""
    end
  end

  def render_content
    content_parts = []
    
    if icon_position == :left
      content_parts << render_icon
      content_parts << content if content.present?
    else
      content_parts << content if content.present?
      content_parts << render_icon
    end
    
    content_parts.join.html_safe
  end

  def button_tag_name
    url.present? ? :a : :button
  end
end