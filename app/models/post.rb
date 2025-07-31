class Post < ApplicationRecord
  enum :status, { unread: 'unread', read: 'read', ignored: 'ignored', responded: 'responded' }
  
  validates :source, presence: true
  validates :external_id, presence: true, uniqueness: { scope: :source }
  validates :title, presence: true
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :author, presence: true
  validates :posted_at, presence: true
  validates :status, presence: true
  
  # Cache invalidation callbacks
  after_update :clear_post_caches
  after_destroy :clear_post_caches
  
  scope :by_source, ->(source) { where(source: source) }
  scope :by_priority, -> { order(priority_score: :desc) }
  scope :recent, -> { order(posted_at: :desc) }
  scope :expired_for_user, ->(user) { where("posted_at < ?", user.settings.post_retention_days.days.ago) }
  scope :not_expired_for_user, ->(user) { where("posted_at >= ?", user.settings.post_retention_days.days.ago) }
  
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
  
  def expired_for?(user)
    return false unless user
    posted_at < user.settings.post_retention_days.days.ago
  end
  
  def days_until_expiry_for(user)
    return nil unless user
    days_old = (Time.current - posted_at) / 1.day
    user.settings.post_retention_days - days_old.to_i
  end
  
  private
  
  def clear_post_caches
    # Clear caches when posts are updated
    Rails.cache.delete_matched("posts/*")
    Rails.cache.delete_matched("tags/*")
    Rails.cache.delete_matched("subreddits/*")
    # Clear fragment caches related to this post
    ActionController::Base.new.expire_fragment([self, Current.user&.id, "post_card", "v2"])
    ActionController::Base.new.expire_fragment([self, "main_content", "v2"])
    ActionController::Base.new.expire_fragment([source_record, source, "source_badge", "v1"])
    ActionController::Base.new.expire_fragment([self, "tags", Digest::MD5.hexdigest(tags)]) if tags.present?
  end
end
