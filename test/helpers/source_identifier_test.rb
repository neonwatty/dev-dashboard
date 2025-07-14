require "test_helper"

class SourceIdentifierTest < ActiveSupport::TestCase
  include ApplicationHelper

  test "source_identifier_for handles all source types correctly" do
    # Test Discourse forums
    hf_source = Source.new(source_type: 'discourse', url: 'https://discuss.huggingface.co')
    assert_equal 'huggingface', source_identifier_for(hf_source)
    
    pytorch_source = Source.new(source_type: 'discourse', url: 'https://discuss.pytorch.org')
    assert_equal 'pytorch', source_identifier_for(pytorch_source)
    
    generic_discourse = Source.new(source_type: 'discourse', url: 'https://discourse.example.com')
    assert_equal 'discourse', source_identifier_for(generic_discourse)
    
    # Test GitHub
    github_source = Source.new(source_type: 'github', url: 'https://github.com/owner/repo')
    assert_equal 'github', source_identifier_for(github_source)
    
    # Test Reddit
    reddit_source = Source.new(source_type: 'reddit', url: 'https://reddit.com/r/programming')
    assert_equal 'reddit', source_identifier_for(reddit_source)
    
    # Test RSS feeds
    hn_source = Source.new(source_type: 'rss', url: 'https://news.ycombinator.com')
    assert_equal 'hackernews', source_identifier_for(hn_source)
    
    hn_named_source = Source.new(source_type: 'rss', url: 'https://example.com', name: 'Hacker News Feed')
    assert_equal 'hackernews', source_identifier_for(hn_named_source)
    
    generic_rss = Source.new(source_type: 'rss', url: 'https://example.com/feed.xml')
    assert_equal 'rss', source_identifier_for(generic_rss)
    
    # Test with valid source type but unknown URL
    generic_discourse = Source.new(source_type: 'discourse', url: 'https://example.com/discourse')
    assert_equal 'discourse', source_identifier_for(generic_discourse)
  end

  test "recent posts query returns correct posts for each source type" do
    # Clean up any existing posts
    Post.delete_all
    
    # Create posts for different sources
    Post.create!(source: 'huggingface', external_id: 'hf1', title: 'HF Post', url: 'https://test.com/1', author: 'user1', posted_at: 1.hour.ago, status: 'unread', priority_score: 1.0)
    Post.create!(source: 'pytorch', external_id: 'pt1', title: 'PyTorch Post', url: 'https://test.com/2', author: 'user2', posted_at: 2.hours.ago, status: 'unread', priority_score: 1.0)
    Post.create!(source: 'github', external_id: 'gh1', title: 'GitHub Post', url: 'https://test.com/3', author: 'user3', posted_at: 3.hours.ago, status: 'unread', priority_score: 1.0)

    # Test HuggingFace source
    hf_source = Source.new(source_type: 'discourse', url: 'https://discuss.huggingface.co')
    hf_posts = Post.where(source: source_identifier_for(hf_source))
    assert_equal 1, hf_posts.count
    assert_equal 'HF Post', hf_posts.first.title

    # Test PyTorch source
    pytorch_source = Source.new(source_type: 'discourse', url: 'https://discuss.pytorch.org') 
    pytorch_posts = Post.where(source: source_identifier_for(pytorch_source))
    assert_equal 1, pytorch_posts.count
    assert_equal 'PyTorch Post', pytorch_posts.first.title

    # Test GitHub source
    github_source = Source.new(source_type: 'github', url: 'https://github.com/test/repo')
    github_posts = Post.where(source: source_identifier_for(github_source))
    assert_equal 1, github_posts.count
    assert_equal 'GitHub Post', github_posts.first.title
  end

  test "posts are ordered by posted_at desc" do
    source_id = 'test_source'
    
    # Create posts with different timestamps
    old_post = Post.create!(source: source_id, external_id: 'old', title: 'Old Post', url: 'https://test.com/old', author: 'user', posted_at: 5.hours.ago, status: 'unread', priority_score: 1.0)
    new_post = Post.create!(source: source_id, external_id: 'new', title: 'New Post', url: 'https://test.com/new', author: 'user', posted_at: 1.hour.ago, status: 'unread', priority_score: 1.0)
    middle_post = Post.create!(source: source_id, external_id: 'middle', title: 'Middle Post', url: 'https://test.com/middle', author: 'user', posted_at: 3.hours.ago, status: 'unread', priority_score: 1.0)

    ordered_posts = Post.where(source: source_id).order(posted_at: :desc)
    
    assert_equal 'New Post', ordered_posts.first.title
    assert_equal 'Middle Post', ordered_posts.second.title  
    assert_equal 'Old Post', ordered_posts.third.title
  end

  test "limits posts to 10 recent items" do
    source_id = 'test_source'
    
    # Create 15 posts
    15.times do |i|
      Post.create!(
        source: source_id,
        external_id: "post_#{i}",
        title: "Post #{i}",
        url: "https://test.com/#{i}",
        author: 'user',
        posted_at: i.hours.ago,
        status: 'unread',
        priority_score: 1.0
      )
    end

    recent_posts = Post.where(source: source_id).order(posted_at: :desc).limit(10)
    assert_equal 10, recent_posts.count
    
    # Should get the most recent 10 (posted_at: 0, 1, 2, ..., 9 hours ago)
    assert_equal 'Post 0', recent_posts.first.title
    assert_equal 'Post 9', recent_posts.last.title
  end
end