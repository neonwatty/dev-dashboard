class FetchPytorchJob < ApplicationJob
  queue_as :default

  def perform(source_id = nil)
    if source_id
      source = Source.find(source_id)
      fetch_from_source(source)
    else
      Source.active.discourse.each do |source|
        fetch_from_source(source)
      end
    end
  end

  private

  def fetch_from_source(source)
    return unless source.url.include?('pytorch.org')

    begin
      # Use direct HTTP request to get latest topics
      require 'net/http'
      require 'json'
      
      uri = URI("#{source.url}/latest.json")
      response = Net::HTTP.get_response(uri)
      
      if response.code == '200'
        data = JSON.parse(response.body)
        topics = data['topic_list']['topics']
        
        new_posts_count = 0
        topics.each do |topic|
          if create_post_from_topic(topic, source)
            new_posts_count += 1
          end
        end
        
        source.update!(last_fetched_at: Time.current)
        status_message = new_posts_count > 0 ? "ok (#{new_posts_count} new)" : "ok"
        source.update_status_and_broadcast(status_message)
      else
        source.update_status_and_broadcast("error: HTTP #{response.code}")
      end
    rescue => e
      Rails.logger.error "Error fetching from #{source.name}: #{e.message}"
      Rails.logger.error "Full error: #{e.inspect}"
      source.update_status_and_broadcast("error: #{e.message}")
    end
  end

  def create_post_from_topic(topic, source)
    post = Post.find_or_initialize_by(
      source: 'pytorch',
      external_id: topic['id'].to_s
    )
    
    if post.new_record?
      post.title = topic['title']
      slug = topic['slug'] || "topic-#{topic['id']}"
      post.url = "#{source.url}/t/#{slug}/#{topic['id']}"
      post.author = topic['last_poster_username'] || 'unknown'
      post.posted_at = Time.parse(topic['created_at'])
      post.summary = topic['excerpt']
      post.tags = topic['tags'].to_json if topic['tags']
      post.status = 'unread'
      post.priority_score = calculate_priority_score(topic)
      post.save!
      return true
    end
    
    false
  end

  def calculate_priority_score(topic)
    score = 0
    score += (topic['reply_count'] || 0) * 0.1
    score += (topic['like_count'] || 0) * 0.2
    score += (topic['views'] || 0) * 0.001
    
    # Boost recent posts
    hours_old = (Time.current - Time.parse(topic['created_at'])) / 1.hour
    score += [10 - hours_old, 0].max * 0.5
    
    # Boost unanswered questions
    score += 2.0 if (topic['reply_count'] || 0) == 0
    
    score
  end
end
