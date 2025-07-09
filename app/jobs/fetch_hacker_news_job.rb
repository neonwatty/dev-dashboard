class FetchHackerNewsJob < ApplicationJob
  queue_as :default

  BASE_URL = 'https://hacker-news.firebaseio.com/v0'
  
  def perform(source_id = nil)
    if source_id
      source = Source.find(source_id)
      fetch_from_source(source)
    else
      # For Hacker News, we'll create a default source if none exists
      source = find_or_create_hn_source
      fetch_from_source(source)
    end
  end

  private

  def find_or_create_hn_source
    Source.find_or_create_by(
      name: 'Hacker News',
      source_type: 'rss',
      url: 'https://news.ycombinator.com'
    ) do |source|
      source.active = true
      source.config = '{"story_types": ["top", "new"], "min_score": 10}'
    end
  end

  def fetch_from_source(source)
    begin
      require 'net/http'
      require 'json'

      # Get configuration
      config = source.config_hash
      story_types = config['story_types'] || ['top']
      min_score = config['min_score'] || 10
      max_items = config['max_items'] || 30
      keywords = config['keywords'] || []

      processed_count = 0
      
      story_types.each do |story_type|
        processed_count += fetch_stories_by_type(story_type, min_score, max_items / story_types.length, keywords)
      end

      source.update!(
        last_fetched_at: Time.current,
        status: "ok (#{processed_count} new items)"
      )
      
      Rails.logger.info "Hacker News: processed #{processed_count} items"

    rescue => e
      Rails.logger.error "Hacker News error: #{e.message}"
      Rails.logger.error "Full error: #{e.inspect}"
      source.update!(status: "error: #{e.message}")
    end
  end

  def fetch_stories_by_type(story_type, min_score, max_items, keywords)
    # Get story IDs
    endpoint = case story_type
                when 'top'
                  "#{BASE_URL}/topstories.json"
                when 'new'
                  "#{BASE_URL}/newstories.json"
                when 'ask'
                  "#{BASE_URL}/askstories.json"
                when 'show'
                  "#{BASE_URL}/showstories.json"
                else
                  "#{BASE_URL}/topstories.json"
                end

    story_ids = fetch_json(endpoint)
    return 0 if story_ids.blank?

    processed_count = 0
    story_ids.first(max_items * 2).each do |story_id|
      break if processed_count >= max_items
      
      story = fetch_story(story_id)
      next unless story
      
      # Skip if doesn't meet minimum score
      next if story['score'] && story['score'] < min_score
      
      # Skip if keywords specified and story doesn't match
      if keywords.any? && !matches_keywords?(story, keywords)
        next
      end
      
      if create_post_from_story(story, story_type)
        processed_count += 1
      end
    end

    processed_count
  end

  def fetch_json(url)
    uri = URI(url)
    response = Net::HTTP.get_response(uri)
    
    if response.code == '200'
      JSON.parse(response.body)
    else
      Rails.logger.error "HN API error: HTTP #{response.code}"
      raise "API returned HTTP #{response.code}"
    end
  rescue JSON::ParserError => e
    Rails.logger.error "HN JSON parse error: #{e.message}"
    raise "Invalid JSON response"
  rescue => e
    Rails.logger.error "HN API fetch error: #{e.message}"
    raise e
  end

  def fetch_story(story_id)
    story_data = fetch_json("#{BASE_URL}/item/#{story_id}.json")
    
    # Only process stories (not comments, jobs, etc.)
    if story_data && story_data['type'] == 'story'
      story_data
    else
      nil
    end
  end

  def matches_keywords?(story, keywords)
    text = "#{story['title'] || ''} #{story['text'] || ''}".downcase
    keywords.any? { |keyword| text.include?(keyword.downcase) }
  end

  def create_post_from_story(story, story_type)
    external_id = story['id'].to_s
    
    # Check if post already exists
    existing_post = Post.find_by(source: 'hackernews', external_id: external_id)
    return false if existing_post

    # Determine URL - use story URL or HN discussion page
    url = story['url'] || "https://news.ycombinator.com/item?id=#{story['id']}"
    
    # Create new post
    Post.create!(
      source: 'hackernews',
      external_id: external_id,
      title: story['title'],
      url: url,
      author: story['by'] || 'unknown',
      posted_at: Time.at(story['time']),
      summary: extract_summary(story),
      tags: extract_tags(story, story_type),
      status: 'unread',
      priority_score: calculate_priority_score(story, story_type)
    )
    
    true
  rescue => e
    Rails.logger.error "Error creating post from HN story: #{e.message}"
    false
  end

  def extract_summary(story)
    summary = story['text'] || ''
    
    # Clean HTML and truncate
    if summary.present?
      cleaned = summary.gsub(/<[^>]*>/, '').strip
      cleaned.truncate(300)
    else
      # For stories without text, create summary from title and score
      "#{story['title']} (#{story['score'] || 0} points, #{story['descendants'] || 0} comments)"
    end
  end

  def extract_tags(story, story_type)
    tags = []
    
    # Add story type as tag
    tags << story_type
    
    # Add tags based on content
    title_lower = (story['title'] || '').downcase
    
    # Programming languages
    languages = ['javascript', 'python', 'ruby', 'java', 'golang', 'rust', 'php', 'swift']
    languages.each do |lang|
      tags << lang if title_lower.include?(lang)
    end
    
    # Frameworks and tools
    frameworks = ['react', 'vue', 'angular', 'rails', 'django', 'express', 'spring']
    frameworks.each do |framework|
      tags << framework if title_lower.include?(framework)
    end
    
    # Content types
    tags << 'ask' if title_lower.start_with?('ask hn')
    tags << 'show' if title_lower.start_with?('show hn')
    tags << 'release' if title_lower.include?('release') || title_lower.include?('version')
    tags << 'tutorial' if title_lower.include?('tutorial') || title_lower.include?('guide')
    
    tags.uniq.to_json
  end

  def calculate_priority_score(story, story_type)
    score = 0
    
    # Base score from HN score
    score += (story['score'] || 0) * 0.1
    
    # Comment engagement
    score += (story['descendants'] || 0) * 0.05
    
    # Recency boost
    hours_old = (Time.current.to_i - story['time']) / 3600.0
    score += [10 - hours_old, 0].max * 0.3
    
    # Story type boosts
    case story_type
    when 'ask'
      score += 3.0  # Ask HN posts are valuable for developers
    when 'show'
      score += 2.5  # Show HN posts are interesting
    when 'top'
      score += 1.0  # Top stories are already curated
    end
    
    # Content type boosts
    title_lower = (story['title'] || '').downcase
    
    # Developer-relevant keywords
    developer_keywords = [
      'api', 'framework', 'library', 'tutorial', 'guide', 'developer', 'programming',
      'code', 'software', 'development', 'javascript', 'python', 'ruby', 'rails',
      'react', 'vue', 'angular', 'nodejs', 'github', 'opensource', 'release'
    ]
    
    matches = developer_keywords.count { |keyword| title_lower.include?(keyword) }
    score += matches * 0.8
    
    # Special content boosts
    score += 2.0 if title_lower.include?('tutorial') || title_lower.include?('guide')
    score += 1.5 if title_lower.include?('release') || title_lower.include?('version')
    score += 1.0 if title_lower.include?('opensource') || title_lower.include?('open source')
    
    score
  end
end