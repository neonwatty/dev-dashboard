# frozen_string_literal: true

# Mobile-optimized modal component
# Provides full-screen modals on mobile and centered dialogs on desktop
class MobileModalComponent < MobileResponsiveComponent
  def initialize(
    id:,
    title:,
    size: :md,
    show_footer: false,
    backdrop_close: true,
    **options
  )
    @id = id
    @title = title
    @size = size
    @show_footer = show_footer
    @backdrop_close = backdrop_close
    @options = options
  end

  private

  attr_reader :id, :title, :size, :show_footer, :backdrop_close, :options

  def modal_wrapper_classes
    "fixed inset-0 z-50 overflow-y-auto hidden"
  end

  def backdrop_classes
    "fixed inset-0 bg-black bg-opacity-50 transition-opacity"
  end

  def modal_container_classes
    "flex min-h-screen items-end sm:items-center justify-center p-0 sm:p-4"
  end

  def modal_content_classes
    mobile_modal_content_classes(size: size) + " " + mobile_animation_classes(type: :slide_up)
  end

  def size_class
    case size
    when :sm then "sm:max-w-md"
    when :lg then "sm:max-w-2xl"
    when :xl then "sm:max-w-4xl"
    else "sm:max-w-lg"
    end
  end

  def header_classes
    "sticky top-0 flex items-center justify-between p-4 border-b border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 sm:rounded-t-lg z-10"
  end

  def title_classes
    "text-lg font-semibold text-gray-900 dark:text-gray-100"
  end

  def close_button_classes
    [
      "p-2 rounded-lg text-gray-400 hover:text-gray-600 dark:hover:text-gray-300",
      "hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors",
      touch_target_classes
    ].join(" ")
  end

  def content_classes
    "flex-1 overflow-y-auto p-4"
  end

  def footer_classes
    "sticky bottom-0 p-4 border-t border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 sm:rounded-b-lg z-10"
  end

  def backdrop_action
    backdrop_close ? "click->modal#close" : ""
  end

  def modal_data_attributes
    {
      controller: "modal",
      modal_backdrop_close_value: backdrop_close
    }
  end

  def aria_attributes
    {
      role: "dialog",
      aria_modal: "true",
      aria_labelledby: "#{id}-title"
    }
  end

  def title_id
    "#{id}-title"
  end

  def close_icon_svg
    <<~SVG.html_safe
      <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
      </svg>
    SVG
  end
end