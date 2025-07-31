namespace :cache do
  desc "Warm up application caches for better performance"
  task warm: :environment do
    puts "Starting cache warming..."
    
    # Warm up source information cache
    puts "Warming source caches..."
    Source.active.each do |source|
      Rails.cache.fetch("sources/#{source.id}/info", expires_in: 1.hour) do
        {
          name: source.name,
          source_type: source.source_type,
          active: source.active,
          status: source.status
        }
      end
    end
    
    # Warm up tags cache
    puts "Warming tags cache..."
    Rails.cache.fetch("tags/all/#{Post.maximum(:updated_at)&.to_i}", expires_in: 1.hour) do
      tags = []
      Post.where.not(tags: [nil, '']).find_each do |post|
        tags.concat(post.tags_array)
      end
      tags.uniq.sort
    end
    
    # Warm up subreddits cache
    puts "Warming subreddits cache..."
    Rails.cache.fetch("subreddits/all/#{Post.maximum(:updated_at)&.to_i}", expires_in: 1.hour) do
      subreddits = []
      Post.where.not(tags: [nil, '']).find_each do |post|
        post.tags_array.each do |tag|
          if tag.start_with?('subreddit:')
            subreddits << tag.sub('subreddit:', '')
          end
        end
      end
      subreddits.uniq.sort
    end
    
    # Warm up recent posts cache
    puts "Warming recent posts cache..."
    Post.includes(:source_record).recent.limit(100).each do |post|
      # Cache post fragments
      Rails.cache.fetch([post, "main_content", "v2"], expires_in: 30.minutes) do
        "cached_main_content"
      end
      
      if post.tags.present?
        Rails.cache.fetch([post, "tags", Digest::MD5.hexdigest(post.tags)], expires_in: 1.hour) do
          "cached_tags"
        end
      end
      
      # Cache source badge
      Rails.cache.fetch([post.source_record, post.source, "source_badge", "v1"], expires_in: 1.hour) do
        "cached_source_badge"
      end
    end
    
    # Warm up priority posts cache
    puts "Warming priority posts cache..."
    Post.includes(:source_record).by_priority.limit(50).each do |post|
      Rails.cache.fetch("posts/priority/#{post.id}", expires_in: 15.minutes) do
        {
          id: post.id,
          title: post.title,
          priority_score: post.priority_score,
          status: post.status
        }
      end
    end
    
    puts "Cache warming completed!"
  end
  
  desc "Clear all application caches"
  task clear: :environment do
    puts "Clearing all caches..."
    Rails.cache.clear
    puts "All caches cleared!"
  end
  
  desc "Show cache statistics"
  task stats: :environment do
    puts "Cache Statistics:"
    puts "=================="
    
    # Count cached fragments
    posts_cache_count = Rails.cache.redis.keys("*posts*").count rescue 0
    tags_cache_count = Rails.cache.redis.keys("*tags*").count rescue 0
    sources_cache_count = Rails.cache.redis.keys("*sources*").count rescue 0
    
    puts "Posts caches: #{posts_cache_count}"
    puts "Tags caches: #{tags_cache_count}"
    puts "Sources caches: #{sources_cache_count}"
    puts "Total cache keys: #{posts_cache_count + tags_cache_count + sources_cache_count}"
  end
end