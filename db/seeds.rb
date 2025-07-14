# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding development data..."

# Create a default user for development
user = User.find_or_create_by!(email_address: "dev@example.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
end
puts "✅ Created user: #{user.email_address}"

# Create Sources
sources_data = [
  {
    name: "HuggingFace Forum",
    source_type: "discourse",
    url: "https://discuss.huggingface.co",
    config: '{}',
    active: true,
    status: "ok"
  },
  {
    name: "PyTorch Forum", 
    source_type: "discourse",
    url: "https://discuss.pytorch.org",
    config: '{}',
    active: true,
    status: "ok"
  },
  {
    name: "Rails GitHub Issues",
    source_type: "github", 
    url: "https://github.com/rails/rails",
    config: '{"labels": ["bug", "enhancement"]}',
    active: true,
    status: "ok"
  },
  {
    name: "Ruby Weekly RSS",
    source_type: "rss",
    url: "https://rubyweekly.com/rss", 
    config: '{"keywords": ["ruby", "rails"], "max_items": 20}',
    active: true,
    status: "ok"
  },
  {
    name: "Hacker News",
    source_type: "rss",
    url: "https://news.ycombinator.com",
    config: '{"story_types": ["top", "new"], "min_score": 10}',
    active: true,
    status: "ok"
  },
  {
    name: "Machine Learning Reddit",
    source_type: "reddit",
    url: "https://www.reddit.com/r/MachineLearning", 
    config: '{"sort": "hot", "limit": 25, "keywords": ["paper", "research", "AI"]}',
    active: true,
    status: "ok"
  },
  {
    name: "Programming Reddit",
    source_type: "reddit",
    url: "https://www.reddit.com/r/programming",
    config: '{"sort": "hot", "limit": 20}',
    active: true,
    status: "ok"
  },
  {
    name: "Ruby Reddit",
    source_type: "reddit", 
    url: "https://www.reddit.com/r/ruby",
    config: '{"sort": "hot", "limit": 15, "keywords": ["rails", "gem"]}',
    active: true,
    status: "ok"
  }
]

sources_data.each do |source_attrs|
  source = Source.find_or_create_by!(url: source_attrs[:url]) do |s|
    s.name = source_attrs[:name]
    s.source_type = source_attrs[:source_type] 
    s.config = source_attrs[:config]
    s.active = source_attrs[:active]
    s.status = source_attrs[:status]
    s.last_fetched_at = rand(1..48).hours.ago
  end
  puts "✅ Created source: #{source.name} (#{source.source_type})"
end

# Create some sample posts for demonstration
sample_posts = [
  {
    source: "HuggingFace Forum",
    external_id: "demo_1",
    title: "New Transformer Architecture Released",
    summary: "Discussion about the latest transformer model improvements and benchmarks.",
    url: "https://discuss.huggingface.co/t/new-transformer/12345",
    author: "researcher_ai",
    posted_at: 2.hours.ago,
    priority_score: 8.5,
    tags: ["transformers", "AI", "research"],
    status: "unread"
  },
  {
    source: "PyTorch Forum",
    external_id: "demo_2", 
    title: "PyTorch 2.1 Performance Improvements",
    summary: "Overview of performance optimizations in the latest PyTorch release.",
    url: "https://discuss.pytorch.org/t/pytorch-performance/67890",
    author: "pytorch_dev",
    posted_at: 4.hours.ago,
    priority_score: 7.2,
    tags: ["pytorch", "performance", "optimization"],
    status: "unread"
  },
  {
    source: "Machine Learning Reddit",
    external_id: "demo_3",
    title: "[Research] Breakthrough in Computer Vision",
    summary: "New paper shows significant improvements in image classification accuracy.",
    url: "https://www.reddit.com/r/MachineLearning/comments/demo3/research_breakthrough/",
    author: "ml_researcher",
    posted_at: 6.hours.ago, 
    priority_score: 9.1,
    tags: ["subreddit:MachineLearning", "reddit", "computer-vision", "research"],
    status: "unread"
  },
  {
    source: "Programming Reddit",
    external_id: "demo_4",
    title: "Clean Code Principles Every Developer Should Know",
    summary: "Discussion about best practices for writing maintainable code.",
    url: "https://www.reddit.com/r/programming/comments/demo4/clean_code/",
    author: "senior_dev",
    posted_at: 8.hours.ago,
    priority_score: 6.8,
    tags: ["subreddit:programming", "reddit", "clean-code", "best-practices"],
    status: "read"
  },
  {
    source: "Rails GitHub Issues",
    external_id: "demo_5",
    title: "Rails 8.0 Beta Release Issues",
    summary: "Bug report and discussion about Rails 8.0 beta testing.",
    url: "https://github.com/rails/rails/issues/54321",
    author: "rails_contributor",
    posted_at: 12.hours.ago,
    priority_score: 7.9,
    tags: ["rails", "beta", "bug", "github"],
    status: "unread"
  },
  {
    source: "Ruby Reddit",
    external_id: "demo_6", 
    title: "Ruby 3.3 New Features Deep Dive",
    summary: "Comprehensive overview of new features and improvements in Ruby 3.3.",
    url: "https://www.reddit.com/r/ruby/comments/demo6/ruby33_features/",
    author: "ruby_expert",
    posted_at: 1.day.ago,
    priority_score: 5.4,
    tags: ["subreddit:ruby", "reddit", "ruby33", "features"],
    status: "ignored"
  },
  {
    source: "Hacker News",
    external_id: "demo_7",
    title: "The Future of Web Development",
    summary: "Industry experts discuss upcoming trends in web development technologies.",
    url: "https://news.ycombinator.com/item?id=demo7",
    author: "web_guru", 
    posted_at: 18.hours.ago,
    priority_score: 8.7,
    tags: ["web-development", "trends", "technology"],
    status: "responded"
  }
]

sample_posts.each do |post_attrs|
  post = Post.find_or_create_by!(external_id: post_attrs[:external_id]) do |p|
    post_attrs.each do |key, value|
      next if key == :tags
      p.send("#{key}=", value)
    end
    p.tags = post_attrs[:tags].join(', ')
  end
  puts "✅ Created post: #{post.title[0..50]}..."
end

puts "\n🎉 Seeding complete!"
puts "📊 Created:"
puts "   - #{User.count} user(s)"
puts "   - #{Source.count} source(s)" 
puts "   - #{Post.count} post(s)"
puts "\n🔐 Default login: dev@example.com / password123"
puts "🌐 Visit: http://localhost:3002"