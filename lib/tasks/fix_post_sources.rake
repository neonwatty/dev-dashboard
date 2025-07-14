namespace :data do
  desc "Fix existing posts to use correct source names instead of hardcoded values"
  task fix_post_sources: :environment do
    puts "Starting post source migration..."
    
    updates = []
    
    # Fix Reddit posts
    reddit_sources = Source.where(source_type: 'reddit')
    reddit_posts = Post.where(source: 'reddit')
    
    puts "Found #{reddit_posts.count} Reddit posts with hardcoded source"
    puts "Available Reddit sources: #{reddit_sources.pluck(:name).join(', ')}"
    
    if reddit_sources.count == 1
      # Simple case: only one Reddit source
      source_name = reddit_sources.first.name
      updated = reddit_posts.update_all(source: source_name)
      updates << "Updated #{updated} Reddit posts to source: '#{source_name}'"
    else
      # Multiple Reddit sources - need to map by tags or other criteria
      reddit_posts.each do |post|
        # Try to match by subreddit tag
        subreddit_tag = post.tags_array.find { |tag| tag.start_with?('subreddit:') }
        if subreddit_tag
          subreddit_name = subreddit_tag.sub('subreddit:', '')
          matching_source = reddit_sources.find { |s| s.name.downcase.include?(subreddit_name.downcase) }
          if matching_source
            post.update!(source: matching_source.name)
            updates << "Updated Reddit post #{post.id} to source: '#{matching_source.name}' (matched subreddit: #{subreddit_name})"
          end
        end
      end
    end
    
    # Fix Discourse posts (HuggingFace and PyTorch)
    ['huggingface', 'pytorch'].each do |hardcoded_source|
      discourse_posts = Post.where(source: hardcoded_source)
      next if discourse_posts.empty?
      
      puts "Found #{discourse_posts.count} #{hardcoded_source} posts with hardcoded source"
      
      # Find matching source by URL pattern
      discourse_source = Source.discourse.find do |source|
        case hardcoded_source
        when 'huggingface'
          source.url.include?('huggingface.co')
        when 'pytorch'
          source.url.include?('pytorch.org')
        end
      end
      
      if discourse_source
        updated = discourse_posts.update_all(source: discourse_source.name)
        updates << "Updated #{updated} #{hardcoded_source} posts to source: '#{discourse_source.name}'"
      end
    end
    
    # Fix Hacker News posts
    hn_sources = Source.where(source_type: 'rss').where('url LIKE ? OR name LIKE ?', '%news.ycombinator.com%', '%hacker news%')
    hn_posts = Post.where(source: 'hackernews')
    
    puts "Found #{hn_posts.count} Hacker News posts with hardcoded source"
    
    if hn_sources.any?
      source_name = hn_sources.first.name
      updated = hn_posts.update_all(source: source_name)
      updates << "Updated #{updated} Hacker News posts to source: '#{source_name}'"
    end
    
    # Report results
    puts "\nMigration completed!"
    puts "Changes made:"
    updates.each { |update| puts "  - #{update}" }
    
    # Verify the fix
    puts "\nVerification:"
    puts "Source filter options now include:"
    Source.active.pluck(:name).each { |name| puts "  - #{name}" }
    
    puts "\nPosts with old hardcoded sources remaining:"
    old_sources = Post.where(source: ['reddit', 'hackernews', 'huggingface', 'pytorch']).group(:source).count
    if old_sources.any?
      old_sources.each { |source, count| puts "  - #{source}: #{count} posts" }
    else
      puts "  - None! All posts now use proper source names."
    end
  end
end