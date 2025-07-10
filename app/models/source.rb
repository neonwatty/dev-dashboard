class Source < ApplicationRecord
  enum :source_type, { github: 'github', reddit: 'reddit', discourse: 'discourse', rss: 'rss' }
  
  validates :name, presence: true
  validates :source_type, presence: true
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :active, inclusion: { in: [true, false] }
  
  scope :active, -> { where(active: true) }
  scope :by_type, ->(type) { where(source_type: type) }
  
  def config_hash
    return {} if config.blank?
    
    # Clean up common config formatting issues
    cleaned_config = config.strip
    
    # Remove common prefixes that might be accidentally added
    cleaned_config = cleaned_config.sub(/^Config:\s*/, '')
    
    # Remove extra whitespace and newlines
    cleaned_config = cleaned_config.gsub(/\r\n|\r|\n/, '').strip
    
    JSON.parse(cleaned_config)
  rescue JSON::ParserError => e
    Rails.logger.warn "Invalid JSON config for source #{name}: #{e.message}. Config: #{config.inspect}"
    {}
  end
  
  def config_hash=(hash)
    self.config = hash.to_json
  end
  
  def connection_ok?
    status == 'ok'
  end
end
