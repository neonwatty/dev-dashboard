module SourcesHelper
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
end
