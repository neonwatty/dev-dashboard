class FetchRssJob < ApplicationJob
  queue_as :default

  def perform(source_id = nil)
    if source_id
      source = Source.find(source_id)
      fetch_from_source(source)
    else
      Source.active.rss.each do |source|
        fetch_from_source(source)
      end
    end
  end

  private

  def fetch_from_source(source)
    return unless source.source_type == 'rss'

    begin
      require 'feedjira'
      require 'net/http'
      require 'uri'

      # Parse RSS feed
      Rails.logger.info "Fetching RSS feed from #{source.url}"
      
      # Use Net::HTTP for better error handling
      uri = URI(source.url)
      
      # Handle redirects
      response = nil
      max_redirects = 5
      redirect_count = 0
      
      while redirect_count < max_redirects
        response = Net::HTTP.get_response(uri)
        
        case response
        when Net::HTTPSuccess
          # Success, continue processing
          break
        when Net::HTTPRedirection
          # Follow redirect
          redirect_url = response['location']
          Rails.logger.info "Following redirect to #{redirect_url}"
          uri = URI(redirect_url)
          redirect_count += 1
        else
          # Other HTTP error
          source.update_status_and_broadcast("error: HTTP #{response.code}")
          return
        end
      end
      
      if redirect_count >= max_redirects
        source.update_status_and_broadcast("error: Too many redirects")
        return
      end

      # Parse the feed
      feed = Feedjira.parse(response.body)
      
      if feed.nil?
        source.update_status_and_broadcast("error: Invalid RSS feed format")
        return
      end

      # Get configuration
      config = source.config_hash
      max_items = config['max_items'] || 20
      keywords = config['keywords'] || []
      
      # Process feed entries
      processed_count = 0
      feed.entries.first(max_items).each do |entry|
        # Skip if keywords specified and entry doesn't match
        if keywords.any? && !matches_keywords?(entry, keywords)
          next
        end
        
        if create_post_from_entry(entry, source)
          processed_count += 1
        end
      end

      source.update!(last_fetched_at: Time.current)
      status_message = processed_count > 0 ? "ok (#{processed_count} new)" : "ok"
      source.update_status_and_broadcast(status_message)
      
      Rails.logger.info "RSS feed #{source.name}: processed #{processed_count} items"

    rescue Feedjira::NoParserAvailable => e
      Rails.logger.error "RSS parsing error for #{source.name}: #{e.message}"
      source.update_status_and_broadcast("error: Unsupported feed format")
    rescue Timeout::Error => e
      Rails.logger.error "RSS timeout for #{source.name}: #{e.message}"
      source.update_status_and_broadcast("error: Request timeout")
    rescue => e
      Rails.logger.error "RSS error for #{source.name}: #{e.message}"
      Rails.logger.error "Full error: #{e.inspect}"
      source.update_status_and_broadcast("error: #{e.message}")
    end
  end

  def create_post_from_entry(entry, source)
    # Generate a unique external_id from the entry
    external_id = entry.entry_id || entry.url || Digest::MD5.hexdigest(entry.title + entry.url.to_s)
    
    # Check if post already exists
    existing_post = Post.find_by(source: source.name, external_id: external_id)
    return false if existing_post

    # Create new post
    Post.create!(
      source: source.name,
      external_id: external_id,
      title: clean_title(entry.title),
      url: entry.url,
      author: extract_author(entry),
      posted_at: entry.published || entry.updated || Time.current,
      summary: extract_summary(entry),
      tags: extract_tags(entry),
      status: 'unread',
      priority_score: calculate_priority_score(entry)
    )
    
    true
  rescue => e
    Rails.logger.error "Error creating post from RSS entry: #{e.message}"
    false
  end

  def matches_keywords?(entry, keywords)
    text = "#{entry.title || ''} #{entry.summary || ''}".downcase
    keywords.any? { |keyword| text.include?(keyword.downcase) }
  end

  def clean_title(title)
    return 'Untitled' if title.blank?
    
    # Remove HTML tags and clean up
    title.gsub(/<[^>]*>/, '').strip.truncate(200)
  end

  def extract_author(entry)
    # Try different author fields, some may not exist on all entry types
    author = 'Unknown'
    
    if entry.respond_to?(:author) && entry.author.present?
      author = entry.author
    elsif entry.respond_to?(:itunes_author) && entry.itunes_author.present?
      author = entry.itunes_author
    end
    
    # Clean up author name
    if author.is_a?(String)
      author.strip.truncate(100)
    else
      author.to_s.strip.truncate(100)
    end
  end

  def extract_summary(entry)
    summary = ''
    
    # Try different summary fields
    if entry.respond_to?(:summary) && entry.summary.present?
      summary = entry.summary
    elsif entry.respond_to?(:content) && entry.content.present?
      summary = entry.content
    elsif entry.respond_to?(:description) && entry.description.present?
      summary = entry.description
    end
    
    # Clean HTML tags and truncate
    if summary.present?
      cleaned = summary.gsub(/<[^>]*>/, '').strip
      cleaned.truncate(500)
    else
      ''
    end
  end

  def extract_tags(entry)
    tags = []
    
    # Extract categories
    if entry.respond_to?(:categories) && entry.categories.present?
      tags.concat(entry.categories.map(&:strip))
    end
    
    # Extract tags from other fields
    if entry.respond_to?(:itunes_keywords) && entry.itunes_keywords.present?
      tags.concat(entry.itunes_keywords.split(',').map(&:strip))
    end
    
    # Clean and limit tags
    tags = tags.compact.uniq.first(10)
    tags.to_json
  end

  def calculate_priority_score(entry)
    score = 0
    
    # Base score for recency
    if entry.published
      hours_old = (Time.current - entry.published) / 1.hour
      score += [10 - hours_old, 0].max * 0.5
    end
    
    # Developer-relevant keywords boost
    developer_keywords = [
      'api', 'framework', 'library', 'tutorial', 'guide', 'developer', 'programming',
      'code', 'software', 'development', 'javascript', 'python', 'ruby', 'rails',
      'react', 'vue', 'angular', 'nodejs', 'github', 'opensource', 'release'
    ]
    
    text = "#{entry.title || ''} #{entry.summary || ''}".downcase
    matches = developer_keywords.count { |keyword| text.include?(keyword) }
    score += matches * 0.5
    
    # Content quality indicators
    if (entry.summary || '').length > 100
      score += 1.0
    end
    
    # Boost for tutorial/guide content
    if text.include?('tutorial') || text.include?('guide') || text.include?('how to')
      score += 2.0
    end
    
    # Boost for release announcements
    if text.include?('release') || text.include?('version') || text.include?('update')
      score += 1.5
    end
    
    score
  end
end