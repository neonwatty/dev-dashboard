class Post < ApplicationRecord
  enum :status, { unread: 'unread', read: 'read', ignored: 'ignored', responded: 'responded' }
  
  validates :source, presence: true
  validates :external_id, presence: true, uniqueness: { scope: :source }
  validates :title, presence: true
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :author, presence: true
  validates :posted_at, presence: true
  validates :status, presence: true
  
  scope :by_source, ->(source) { where(source: source) }
  scope :by_priority, -> { order(priority_score: :desc) }
  scope :recent, -> { order(posted_at: :desc) }
  
  def tags_array
    return [] if tags.blank?
    JSON.parse(tags)
  rescue JSON::ParserError
    []
  end
  
  def tags_array=(array)
    self.tags = array.to_json
  end
  
  # Find the corresponding source record
  def source_record
    @source_record ||= Source.find_by(name: source)
  end
  
  def source_type
    return source_record.source_type if source_record
    
    # Fallback mapping for legacy posts
    case source.downcase
    when 'github', 'github_issues'
      'github'
    when 'github_trending'
      'github_trending'
    when 'huggingface', 'pytorch'
      'discourse'
    when 'reddit'
      'reddit'
    when 'rss', 'hackernews'
      'rss'
    else
      'unknown'
    end
  end
  
  def source_name
    source_record&.name || source
  end
end
