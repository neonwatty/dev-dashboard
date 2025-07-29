# frozen_string_literal: true

# Mobile-responsive smart filters component
# Provides collapsible filter panels optimized for mobile and desktop use
class SmartFiltersComponent < MobileResponsiveComponent
  def initialize(params:, sources:, all_tags:, subreddits: [])
    @params = params
    @sources = sources
    @all_tags = all_tags
    @subreddits = subreddits
  end

  private

  attr_reader :params, :sources, :all_tags, :subreddits

  # Container classes for the entire filter panel
  def container_classes
    "bg-white dark:bg-gray-800 rounded-lg shadow-md mb-4 sm:mb-6"
  end

  # Classes for mobile toggle button
  def mobile_toggle_classes
    [
      "w-full flex items-center justify-between p-4 text-left",
      "focus:outline-none focus:ring-2 focus:ring-blue-500 rounded-lg",
      touch_target_classes
    ].join(" ")
  end

  # Classes for mobile toggle icon section
  def toggle_icon_section_classes
    "flex items-center gap-2"
  end

  def toggle_label_classes
    "font-medium text-gray-900 dark:text-gray-100"
  end

  def toggle_status_section_classes
    "flex items-center gap-2"
  end

  def active_count_classes
    "text-sm text-gray-500 dark:text-gray-400"
  end

  # Classes for chevron icon
  def chevron_classes
    "w-5 h-5 text-gray-400 transform transition-transform"
  end

  # Classes for filter panel container
  def filter_panel_classes
    "hidden md:block p-4 sm:p-6"
  end

  # Classes for quick filter section
  def quick_filter_section_classes
    "mb-4"
  end

  def quick_filter_heading_classes
    "text-sm font-medium text-gray-700 dark:text-gray-300 mb-3"
  end

  # Container for quick filter buttons
  def quick_filter_container_classes
    "flex flex-col gap-2 md:flex-row md:flex-wrap md:gap-2"
  end

  # Quick filter button classes
  def quick_filter_button_classes(active: false)
    base_classes = [
      "inline-flex items-center px-4 py-3 md:px-3 md:py-2 rounded-full",
      "text-sm font-medium transition-colors w-full md:w-auto",
      "justify-center md:justify-start",
      touch_target_classes
    ].join(" ")

    state_classes = if active
                      "bg-blue-600 text-white"
                    else
                      "bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600"
                    end

    "#{base_classes} #{state_classes}"
  end

  # Classes for filter count badges
  def filter_count_badge_classes
    "ml-2 bg-white dark:bg-gray-800 bg-opacity-20 text-xs px-2 py-0.5 rounded-full"
  end

  # Active filters section classes
  def active_filters_section_classes
    "mb-4 pt-4 border-t border-gray-200 dark:border-gray-700"
  end

  def active_filters_header_classes
    "flex items-center justify-between mb-2"
  end

  def active_filters_heading_classes
    "text-sm font-medium text-gray-700 dark:text-gray-300"
  end

  def clear_all_link_classes
    "text-xs text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300"
  end

  def active_filters_container_classes
    "flex flex-wrap gap-2"
  end

  # Active filter badge classes
  def active_filter_badge_classes(type: :normal)
    base_classes = "inline-flex items-center px-3 py-1.5 rounded-full text-xs font-medium"
    
    type_classes = case type
                   when :normal
                     "bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200"
                   when :info
                     "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400"
                   else
                     "bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200"
                   end

    "#{base_classes} #{type_classes}"
  end

  def remove_filter_button_classes
    "ml-2 hover:text-blue-600 dark:hover:text-blue-300 p-1"
  end

  # Sources filter section classes
  def sources_section_classes
    "mb-4 pt-4 border-t border-gray-200"
  end

  def sources_header_classes
    "flex items-center justify-between mb-3"
  end

  def sources_heading_classes
    "text-sm font-medium text-gray-700 dark:text-gray-300"
  end

  def sources_actions_classes
    "flex gap-2"
  end

  def sources_action_link_classes
    "text-xs text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300"
  end

  def sources_container_classes
    "flex flex-wrap gap-2 mb-3"
  end

  def source_label_classes
    "inline-flex items-center cursor-pointer"
  end

  def source_checkbox_classes
    "sr-only source-checkbox"
  end

  def source_badge_classes(selected: false)
    base_classes = "inline-flex items-center px-3 py-1.5 rounded-full text-sm font-medium transition-colors"
    
    state_classes = if selected
                      "bg-blue-600 text-white"
                    else
                      "bg-gray-100 text-gray-700 hover:bg-gray-200"
                    end

    "#{base_classes} #{state_classes}"
  end

  def source_icon_classes(source)
    "w-4 h-4 rounded mr-2 #{source_icon_bg_class(source)}"
  end

  def sources_submit_button_classes
    mobile_button_classes(style: :primary, size: :md) + " w-full sm:w-auto"
  end

  # Search and advanced section classes
  def search_section_classes
    "flex flex-col sm:flex-row items-stretch sm:items-center gap-3 sm:gap-4"
  end

  def search_form_classes
    "flex-1"
  end

  def search_input_container_classes
    "relative"
  end

  def search_input_classes
    [
      "w-full pl-10 pr-4 py-3 border border-gray-300 dark:border-gray-600",
      "dark:bg-gray-700 dark:text-white rounded-lg",
      "focus:outline-none focus:ring-2 focus:ring-blue-500",
      mobile_input_classes
    ].join(" ")
  end

  def search_icon_classes
    "absolute left-3 top-2.5 w-5 h-5 text-gray-400"
  end

  def advanced_toggle_button_classes
    [
      "inline-flex items-center justify-center px-4 py-3",
      "border border-gray-300 dark:border-gray-600 rounded-lg text-sm font-medium",
      "text-gray-700 dark:text-gray-200 bg-white dark:bg-gray-700",
      "hover:bg-gray-50 dark:hover:bg-gray-600",
      "focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500",
      "transition-colors",
      touch_target_classes
    ].join(" ")
  end

  # Advanced filters section classes
  def advanced_filters_section_classes
    "hidden mt-4 pt-4 border-t border-gray-200"
  end

  def advanced_filters_grid_classes
    responsive_grid_classes(mobile_cols: 1, desktop_cols: 2)
  end

  def advanced_filter_field_classes
    mobile_form_classes
  end

  def advanced_filter_label_classes
    mobile_label_classes
  end

  def advanced_filter_select_classes
    [
      "w-full px-3 py-3 border border-gray-300 dark:border-gray-600",
      "dark:bg-gray-700 dark:text-white rounded-md",
      "focus:outline-none focus:ring-2 focus:ring-blue-500",
      mobile_input_classes
    ].join(" ")
  end

  def advanced_submit_button_classes
    mobile_button_classes(style: :primary, size: :md) + " w-full md:w-auto"
  end

  def advanced_submit_container_classes
    "mt-4 flex justify-end"
  end

  # Helper methods
  def unread_count
    Post.where(status: 'unread').count
  end

  def normalize_sources_param(sources)
    return [] unless sources.present?
    sources.is_a?(Array) ? sources : [sources]
  end

  def source_selected?(source, selected_sources)
    normalize_sources_param(selected_sources).include?(source)
  end

  def source_icon_bg_class(source)
    case source.to_s.downcase
    when /github/
      'bg-gray-900 text-white'
    when /reddit/
      'bg-orange-500 text-white'
    when /rss/
      'bg-green-500 text-white'
    when /hacker.*news/i
      'bg-orange-600 text-white'
    else
      'bg-gray-500 text-white'
    end
  end

  def has_active_filters?
    %i[keyword sources source status tag min_priority after_date].any? { |key| params[key].present? }
  end

  def filter_icon_svg
    <<~SVG.html_safe
      <svg class="w-5 h-5 text-gray-600 dark:text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z"></path>
      </svg>
    SVG
  end

  def chevron_down_svg
    <<~SVG.html_safe
      <svg class="w-5 h-5 text-gray-400 transform transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
      </svg>
    SVG
  end

  def remove_icon_svg
    <<~SVG.html_safe
      <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
        <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"/>
      </svg>
    SVG
  end

  def search_icon_svg
    <<~SVG.html_safe
      <svg class="absolute left-3 top-2.5 w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
      </svg>
    SVG
  end

  def sliders_icon_svg
    <<~SVG.html_safe
      <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4"></path>
      </svg>
    SVG
  end

  # Quick filter helpers
  def unread_active?
    params[:status] == 'unread' && !params[:keyword]
  end

  def today_active?
    params[:posted_after].present?
  end

  def priority_active?
    params[:sort] == 'priority' && params[:min_priority]
  end

  def languages_active?
    params[:tag].present?
  end

  def github_sources_active?
    github_sources = sources.select { |s| s.downcase.include?('github') }
    normalize_sources_param(params[:sources]).any? { |s| github_sources.include?(s) }
  end
end