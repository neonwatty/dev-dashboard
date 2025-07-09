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
end
