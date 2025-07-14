require 'discourse_api'
require_relative 'concerns/post_creation'

class DiscourseService
  include PostCreation
  
  attr_reader :source, :client

  def initialize(source)
    @source = source
    setup_client
  end

  def fetch_latest_topics(options = {})
    page = options[:page] || 0
    per_page = options[:per_page] || 30
    
    begin
      # For public forums, we can use the JSON endpoint directly
      if @source.config_hash['api_key'].blank?
        fetch_public_topics(page: page)
      else
        # Use authenticated API for private forums
        fetch_authenticated_topics(page: page)
      end
    rescue => e
      Rails.logger.error "Error fetching Discourse topics for #{@source.name}: #{e.message}"
      raise
    end
  end

  def fetch_topic_details(topic_id)
    begin
      if @source.config_hash['api_key'].blank?
        fetch_public_topic_details(topic_id)
      else
        @client.topic(topic_id)
      end
    rescue => e
      Rails.logger.error "Error fetching topic details for #{topic_id}: #{e.message}"
      nil
    end
  end

  def create_post_from_topic(topic_data)
    attributes = {
      title: topic_data['title'],
      url: build_topic_url(topic_data),
      author: extract_author(topic_data),
      posted_at: Time.parse(topic_data['created_at']),
      summary: extract_summary(topic_data),
      tags: extract_tags(topic_data),
      priority_score: calculate_priority_score(topic_data)
    }
    
    # Use the updated_at field for activity tracking if available
    if topic_data['last_posted_at']
      attributes[:posted_at] = Time.parse(topic_data['last_posted_at'])
    end
    
    result = find_or_update_post(@source.name, topic_data['id'].to_s, attributes)
    
    # Fetch additional details if it's a new or updated post
    if (result[:created] || result[:updated]) && @source.config_hash['fetch_full_content'] == true
      enhance_with_full_content(result[:post], topic_data['id'])
      result[:post].save!
    end
    
    # Return true only if a new post was created (for counting)
    result[:created]
  rescue => e
    Rails.logger.error "Error creating/updating post from topic #{topic_data['id']}: #{e.message}"
    false
  end

  private

  def setup_client
    if @source.config_hash['api_key'].present?
      @client = DiscourseApi::Client.new(@source.url)
      @client.api_key = @source.config_hash['api_key']
      @client.api_username = @source.config_hash['api_username'] || 'system'
    end
  end


  def fetch_public_topics(page: 0)
    require 'net/http'
    require 'json'
    
    uri = URI("#{@source.url}/latest.json?page=#{page}")
    response = Net::HTTP.get_response(uri)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      data['topic_list']['topics']
    else
      raise "HTTP Error: #{response.code}"
    end
  end

  def fetch_authenticated_topics(page: 0)
    @client.latest_topics(page: page)
  end

  def fetch_public_topic_details(topic_id)
    uri = URI("#{@source.url}/t/#{topic_id}.json")
    response = Net::HTTP.get_response(uri)
    
    if response.code == '200'
      JSON.parse(response.body)
    else
      nil
    end
  end

  def build_topic_url(topic)
    slug = topic['slug'] || "topic-#{topic['id']}"
    "#{@source.url}/t/#{slug}/#{topic['id']}"
  end

  def extract_author(topic)
    topic['last_poster_username'] || 
    topic.dig('posters', 0, 'user', 'username') || 
    'unknown'
  end

  def extract_summary(topic)
    summary = topic['excerpt'] || ''
    
    # Clean up the summary
    summary = summary.gsub(/\n+/, ' ').strip
    summary = summary.gsub(/\s+/, ' ')
    
    # Remove "View Post" links that Discourse adds
    summary = summary.gsub(/\s*View Post\s*$/, '')
    
    summary.presence
  end

  def extract_tags(topic)
    tags = topic['tags'] || []
    
    # Add category as a tag if present
    if topic['category_id'] && @source.config_hash['include_category_as_tag']
      category_name = fetch_category_name(topic['category_id'])
      tags << category_name if category_name
    end
    
    tags.to_json
  end

  def fetch_category_name(category_id)
    # This would require an additional API call or caching categories
    # For now, we'll skip this unless specifically needed
    nil
  end

  def calculate_priority_score(topic)
    score = 0.0
    
    # Base score from engagement metrics
    score += (topic['reply_count'] || 0) * 0.1
    score += (topic['like_count'] || 0) * 0.2
    score += (topic['views'] || 0) * 0.001
    
    # Boost recent posts
    hours_old = (Time.current - Time.parse(topic['created_at'])) / 1.hour
    recency_boost = [10 - hours_old, 0].max * 0.5
    score += recency_boost
    
    # Special handling for PyTorch: boost unanswered questions
    if @source.url.include?('pytorch.org') || @source.name.downcase.include?('pytorch')
      if topic['reply_count'] == 0 && topic['title'] =~ /\?/
        score += 5.0
      end
    end
    
    # Boost pinned topics slightly
    score += 2.0 if topic['pinned']
    
    # Boost topics with certain tags
    if topic['tags'].present?
      priority_tags = @source.config_hash['priority_tags'] || []
      matching_tags = topic['tags'] & priority_tags
      score += matching_tags.count * 1.0
    end
    
    score
  end

  def enhance_with_full_content(post, topic_id)
    topic_details = fetch_topic_details(topic_id)
    return unless topic_details
    
    # Get the first post content
    first_post = topic_details.dig('post_stream', 'posts', 0)
    if first_post
      # Store full content in summary if it's longer than excerpt
      full_content = first_post['cooked'] # HTML content
      clean_content = ActionView::Base.full_sanitizer.sanitize(full_content)
      
      if clean_content.length > (post.summary || '').length
        post.summary = clean_content.truncate(1000)
      end
    end
  end

end