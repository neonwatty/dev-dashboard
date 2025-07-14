module PostsHelper
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
  
  # Helper to normalize sources parameter to always be an array
  def normalize_sources_param(sources_param)
    return [] if sources_param.blank?
    sources_param.is_a?(Array) ? sources_param : [sources_param]
  end
  
  # Check if a source is selected in the current filters
  def source_selected?(source, sources_param)
    normalized_sources = normalize_sources_param(sources_param)
    normalized_sources.include?(source)
  end
end
