namespace :reddit do
  desc "Update all Reddit posts to use 'reddit' as source instead of source names"
  task update_sources: :environment do
    puts "Starting Reddit source update..."
    
    # Find all Reddit-related sources
    reddit_sources = Source.where(source_type: 'reddit')
    
    if reddit_sources.empty?
      puts "No Reddit sources found."
      return
    end
    
    puts "Found #{reddit_sources.count} Reddit sources:"
    reddit_sources.each do |source|
      puts "  - #{source.name}"
    end
    
    # Count posts to update
    total_posts = 0
    reddit_sources.each do |source|
      count = Post.where(source: source.name).count
      total_posts += count
      puts "    Posts with source '#{source.name}': #{count}"
    end
    
    if total_posts == 0
      puts "\nNo posts to update."
      return
    end
    
    puts "\nTotal posts to update: #{total_posts}"
    print "Proceed with update? (y/n): "
    
    # In production, you might want to remove this confirmation
    # or run with RAILS_ENV=production rails reddit:update_sources CONFIRM=yes
    confirm = ENV['CONFIRM'] || STDIN.gets.chomp
    
    unless confirm.downcase == 'y' || confirm.downcase == 'yes'
      puts "Update cancelled."
      return
    end
    
    # Update posts
    updated_count = 0
    reddit_sources.each do |source|
      posts = Post.where(source: source.name)
      if posts.any?
        puts "\nUpdating #{posts.count} posts from '#{source.name}' to 'reddit'..."
        posts.update_all(source: 'reddit')
        updated_count += posts.count
      end
    end
    
    # Also update any other Reddit-like sources
    reddit_like_sources = Post.where("source LIKE '%reddit%' OR source LIKE '%Reddit%'")
                             .where.not(source: 'reddit')
                             .distinct
                             .pluck(:source)
    
    if reddit_like_sources.any?
      puts "\nFound additional Reddit-like sources:"
      reddit_like_sources.each do |source_name|
        count = Post.where(source: source_name).count
        puts "  - '#{source_name}': #{count} posts"
        Post.where(source: source_name).update_all(source: 'reddit')
        updated_count += count
      end
    end
    
    puts "\n✅ Update complete! Updated #{updated_count} posts to use 'reddit' as source."
    
    # Show summary
    puts "\nFinal summary:"
    puts "- Posts with source 'reddit': #{Post.where(source: 'reddit').count}"
    puts "- Unique sources remaining: #{Post.distinct.pluck(:source).sort.join(', ')}"
  end
  
  desc "Show current Reddit post sources"
  task show_sources: :environment do
    puts "Current Reddit-related post sources:"
    
    # Find all sources that might be Reddit-related
    reddit_like = Post.where("source LIKE '%reddit%' OR source LIKE '%Reddit%'")
                      .group(:source)
                      .count
                      
    if reddit_like.empty?
      puts "No Reddit-related posts found."
      return
    end
    
    reddit_like.each do |source, count|
      puts "  - '#{source}': #{count} posts"
    end
    
    puts "\nTotal: #{reddit_like.values.sum} posts across #{reddit_like.keys.count} different source values"
  end
end