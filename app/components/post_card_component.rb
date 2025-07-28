# frozen_string_literal: true

# Mobile-responsive post card component
# Displays posts with optimized layouts for mobile and desktop viewports
class PostCardComponent < MobileResponsiveComponent
  def initialize(post:, current_user: nil)
    @post = post
    @current_user = current_user
  end

  private

  attr_reader :post, :current_user

  def card_classes
    [
      "bg-white dark:bg-gray-800 rounded-lg shadow-sm hover:shadow-md",
      "transition-all duration-200 border border-gray-100 dark:border-gray-700",
      mobile_padding_classes
    ].join(" ")
  end

  def layout_classes
    mobile_card_layout_classes
  end

  def source_section_classes
    "flex items-center gap-3 mb-3 sm:mb-0 sm:flex-col sm:w-20"
  end

  def source_icon_classes
    "w-10 h-10 sm:w-12 sm:h-12 rounded-lg flex items-center justify-center #{source_icon_bg_class} sm:mx-auto"
  end

  def source_info_classes
    "flex-1 sm:text-center sm:mt-2"
  end

  def source_type_classes
    responsive_text_size(mobile_size: "text-sm", desktop_size: "text-xs") +
    " font-semibold text-gray-900 dark:text-gray-100 capitalize leading-tight"
  end

  def source_name_classes
    responsive_text_size(mobile_size: "text-sm", desktop_size: "text-xs") +
    " text-gray-500 dark:text-gray-400 truncate"
  end

  def mobile_status_badge_classes
    "sm:hidden"
  end

  def desktop_status_badge_classes
    "hidden sm:flex flex-col items-end gap-2"
  end

  def title_classes
    responsive_text_size(mobile_size: "text-base", desktop_size: "text-lg") +
    " font-semibold text-gray-900 dark:text-gray-100 mb-1 leading-tight"
  end

  def title_link_classes
    "hover:text-blue-600 dark:hover:text-blue-400 transition-colors"
  end

  def meta_classes
    "text-sm text-gray-500 dark:text-gray-400 mb-2"
  end

  def summary_classes
    "text-sm text-gray-600 dark:text-gray-300 mb-3 leading-relaxed " +
    line_clamp_classes(lines: 3, mobile_lines: 2)
  end

  def tags_container_classes
    "flex gap-2 overflow-x-auto pb-2 -mx-4 px-4 sm:mx-0 sm:px-0 sm:flex-wrap sm:pb-0 mb-3 " +
    hide_scrollbar_classes
  end

  def tag_classes
    "inline-flex shrink-0 items-center px-2.5 py-0.5 rounded-md text-xs font-medium " +
    "bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 " +
    "hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
  end

  def actions_section_classes
    "flex items-center justify-between mt-4 pt-4 border-t border-gray-200 dark:border-gray-700"
  end

  def action_buttons_container_classes
    "flex gap-2 w-full sm:w-auto justify-center sm:justify-start"
  end

  def action_button_classes(type = :default)
    base_classes = [
      "flex items-center gap-1.5 px-4 py-2.5 sm:px-3 sm:py-2",
      "text-sm font-medium rounded-lg transition-colors",
      touch_target_classes
    ].join(" ")

    type_classes = case type
                   when :read
                     "text-gray-600 dark:text-gray-400 hover:text-green-600 dark:hover:text-green-400 hover:bg-green-50 dark:hover:bg-green-900/50"
                   when :clear
                     "text-gray-600 dark:text-gray-400 hover:text-red-600 dark:hover:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/50"
                   when :respond
                     "text-gray-600 dark:text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 hover:bg-blue-50 dark:hover:bg-blue-900/50"
                   else
                     "text-gray-600 dark:text-gray-400"
                   end

    "#{base_classes} #{type_classes}"
  end

  def action_icon_classes
    "w-5 h-5 sm:w-4 sm:h-4"
  end

  def action_label_classes
    "sm:hidden"
  end

  def status_badge_class
    case post.status
    when 'read'
      'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
    when 'responded'
      'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200'
    when 'ignored'
      'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200'
    else
      'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200'
    end
  end

  def source_icon_bg_class
    # This should match the existing helper logic from the original partial
    case post.source_type
    when 'github'
      'bg-gray-900 text-white'
    when 'reddit'
      'bg-orange-500 text-white'
    when 'rss'
      'bg-green-500 text-white'
    when 'hacker_news'
      'bg-orange-600 text-white'
    else
      'bg-gray-500 text-white'
    end
  end

  def truncated_source_name
    post.source_name.truncate(30)
  end

  def truncated_summary
    return unless post.summary.present?
    ActionView::Base.full_sanitizer.sanitize(post.summary).truncate(150)
  end

  def display_tags
    post.tags_array.first(5)
  end

  def remaining_tags_count
    [post.tags_array.size - 5, 0].max
  end

  def authenticated?
    current_user.present?
  end

  def time_ago_text
    "#{time_ago_in_words(post.posted_at)} ago"
  end

  def formatted_posted_at
    post.posted_at.strftime('%B %d, %Y at %I:%M %p')
  end

  def show_priority_score?
    post.priority_score && post.priority_score > 5
  end

  def rounded_priority_score
    post.priority_score.round(1)
  end

  def status_display_text
    post.status == 'ignored' ? 'Cleared' : post.status.titleize
  end
end