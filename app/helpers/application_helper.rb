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
    case source_name
    when 'huggingface'
      'yellow'
    when 'pytorch'
      'orange'
    when 'github'
      'gray'
    when 'rss'
      'green'
    when 'hackernews'
      'orange'
    else
      'blue'
    end
  end
end
