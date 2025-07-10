require 'net/http'
require 'json'

class FetchRedditJob < ApplicationJob
  queue_as :default

  def perform(source_id = nil)
    if source_id
      source = Source.find(source_id)
      fetch_from_source(source)
    else
      # Fetch from all active Reddit sources
      Source.where(source_type: 'reddit', active: true).find_each do |source|
        fetch_from_source(source)
      end
    end
  end

  private

  def fetch_from_source(source)
    Rails.logger.info "Fetching from Reddit source: #{source.name} (#{source.url})"
    
    begin
      # Update source status
      source.update_status_and_broadcast('refreshing...')
      
      # Parse configuration using the robust config_hash method
      config = source.config_hash
      
      # Extract subreddit from URL
      # URL format: https://www.reddit.com/r/MachineLearning or https://reddit.com/r/MachineLearning
      subreddit = extract_subreddit_from_url(source.url)
      
      if subreddit.blank?
        source.update_status_and_broadcast('error: invalid subreddit URL')
        return
      end
      
      # Fetch posts from Reddit JSON API
      posts_data = fetch_reddit_posts(subreddit, config)
      
      if posts_data.nil?
        source.update_status_and_broadcast('error: failed to fetch posts')
        return
      end
      
      # Process posts
      posts_created = 0
      posts_data.each do |post_data|
        next if post_data.dig('data', 'stickied') # Skip stickied posts
        # Skip posts that have no content (neither text nor external URL)
        next if post_data.dig('data', 'is_self') == false && 
               post_data.dig('data', 'url').blank? && 
               post_data.dig('data', 'selftext').blank?
        
        post_info = extract_post_info(post_data['data'], subreddit)
        next if post_info.nil?
        
        # Apply keyword filtering if configured
        if config['keywords'].present?
          keywords = config['keywords'].map(&:downcase)
          title_content = "#{post_info[:title]} #{post_info[:summary]}".downcase
          
          next unless keywords.any? { |keyword| title_content.include?(keyword) }
        end
        
        # Check if post already exists
        existing_post = Post.find_by(
          source: source.name,
          external_id: post_info[:external_id]
        )
        
        if existing_post
          # Update existing post
          existing_post.update!(
            title: post_info[:title],
            summary: post_info[:summary],
            url: post_info[:url],
            author: post_info[:author],
            posted_at: post_info[:posted_at],
            priority_score: post_info[:priority_score],
            tags: post_info[:tags]
          )
        else
          # Create new post
          Post.create!(
            source: source.name,
            external_id: post_info[:external_id],
            title: post_info[:title],
            summary: post_info[:summary],
            url: post_info[:url],
            author: post_info[:author],
            posted_at: post_info[:posted_at],
            priority_score: post_info[:priority_score],
            tags: post_info[:tags],
            status: 'unread'
          )
          posts_created += 1
        end
      end
      
      # Update source status
      source.update!(last_fetched_at: Time.current)
      status_message = posts_created > 0 ? "ok (#{posts_created} new)" : "ok"
      source.update_status_and_broadcast(status_message)
      
      Rails.logger.info "Successfully fetched #{posts_created} new posts from r/#{subreddit}"
      
    rescue => e
      Rails.logger.error "Error fetching from Reddit source #{source.name}: #{e.message}"
      source.update_status_and_broadcast("error: #{e.message}")
    end
  end

  def extract_subreddit_from_url(url)
    # Match patterns like:
    # https://www.reddit.com/r/MachineLearning
    # https://reddit.com/r/MachineLearning/
    # https://www.reddit.com/r/MachineLearning/hot
    match = url.match(%r{reddit\.com/r/([^/]+)})
    return match[1] if match
    
    nil
  end

  def fetch_reddit_posts(subreddit, config)
    # Reddit JSON API endpoint
    sort = config['sort'] || 'hot'  # hot, new, top
    limit = config['limit'] || 25
    
    url = "https://www.reddit.com/r/#{subreddit}/#{sort}.json?limit=#{limit}"
    
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(uri)
    request['User-Agent'] = 'DevDashboard/1.0'
    
    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      return data.dig('data', 'children') || []
    else
      Rails.logger.error "Reddit API error: #{response.code} - #{response.body}"
      return nil
    end
  end

  def extract_post_info(post_data, subreddit)
    return nil if post_data.nil?
    
    # Extract basic info
    title = post_data['title']
    content = post_data['selftext'] || post_data['url'] || ''
    author = post_data['author']
    external_id = post_data['id']
    created_utc = post_data['created_utc']
    
    return nil if title.blank? || external_id.blank?
    
    # Build post URL
    permalink = post_data['permalink']
    url = "https://www.reddit.com#{permalink}"
    
    # Posted timestamp
    posted_at = Time.at(created_utc.to_i).utc
    
    # Engagement data
    upvotes = post_data['ups'] || 0
    downvotes = post_data['downs'] || 0
    comments = post_data['num_comments'] || 0
    score = post_data['score'] || 0
    
    engagement_data = {
      upvotes: upvotes,
      downvotes: downvotes,
      comments: comments,
      score: score,
      upvote_ratio: post_data['upvote_ratio']
    }
    
    # Calculate priority score
    priority_score = calculate_priority_score(score, comments, posted_at)
    
    # Tags
    tags = [
      "subreddit:#{subreddit}",
      "reddit",
      post_data['link_flair_text']
    ].compact.reject(&:blank?)
    
    # Add content type tags
    if post_data['is_self']
      tags << 'text-post'
    elsif post_data['url']&.include?('youtube.com') || post_data['url']&.include?('youtu.be')
      tags << 'video'
    elsif post_data['url']&.match?(/\.(jpg|jpeg|png|gif|webp)$/i)
      tags << 'image'
    elsif post_data['url']&.match?(/github\.com/)
      tags << 'github'
    end
    
    {
      external_id: external_id,
      title: title,
      summary: content.length > 1000 ? content[0..1000] + '...' : content,
      url: url,
      author: author,
      posted_at: posted_at,
      priority_score: priority_score,
      tags: tags
    }
  end

  def calculate_priority_score(score, comments, posted_at)
    return 0 if score.nil? || comments.nil?
    
    # Base score from upvotes and comments
    base_score = (score || 0) * 0.1 + (comments || 0) * 0.5
    
    # Time decay factor (newer posts get slight boost)
    hours_old = (Time.current - posted_at) / 1.hour
    time_factor = 1.0 / (1.0 + hours_old / 24.0) # Decay over 24 hours
    
    # Minimum score of 1
    [(base_score * time_factor).round(2), 1.0].max
  end
end