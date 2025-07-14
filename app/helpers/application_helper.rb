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
  
  def status_badge_class(status)
    case status
    when 'unread'
      'bg-blue-500'
    when 'read'
      'bg-green-500'
    when 'ignored'
      'bg-gray-500'
    when 'responded'
      'bg-purple-500'
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
      'bg-blue-100 text-blue-800'
    when 'read'
      'bg-green-100 text-green-800'
    when 'ignored'
      'bg-gray-100 text-gray-800'
    when 'responded'
      'bg-purple-100 text-purple-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end
end
