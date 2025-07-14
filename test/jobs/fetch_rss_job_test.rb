require "test_helper"

class FetchRssJobTest < ActiveJob::TestCase
  setup do
    @source = sources(:ruby_blog_rss)
  end

  test "should fetch and create posts from successful RSS feed" do
    # Mock successful RSS feed response
    rss_content = <<~RSS
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Ruby Weekly</title>
          <description>A weekly Ruby newsletter</description>
          <item>
            <title>Ruby 3.3 Released with New Features</title>
            <link>https://rubyweekly.com/issues/ruby-3-3-released</link>
            <description>Ruby 3.3 brings exciting new features for developers</description>
            <pubDate>Tue, 09 Jul 2025 12:00:00 +0000</pubDate>
            <author>ruby-team@example.com</author>
            <category>ruby</category>
            <category>release</category>
            <guid>ruby-3-3-release-001</guid>
          </item>
          <item>
            <title>Rails Performance Tips and Tricks</title>
            <link>https://rubyweekly.com/issues/rails-performance-tips</link>
            <description>Learn how to optimize your Rails applications for better performance</description>
            <pubDate>Mon, 08 Jul 2025 12:00:00 +0000</pubDate>
            <author>performance-expert@example.com</author>
            <category>rails</category>
            <category>tutorial</category>
            <guid>rails-performance-tips-002</guid>
          </item>
        </channel>
      </rss>
    RSS

    stub_request(:get, @source.url)
      .to_return(status: 200, body: rss_content, headers: { 'Content-Type' => 'application/rss+xml' })

    # Perform the job
    assert_difference('Post.count', 2) do
      FetchRssJob.perform_now(@source.id)
    end

    # Verify source status was updated
    @source.reload
    assert_includes @source.status, 'ok'
    assert_not_nil @source.last_fetched_at

    # Verify posts were created correctly
    post1 = Post.find_by(source: 'rss', title: 'Ruby 3.3 Released with New Features')
    assert_not_nil post1
    assert_equal "https://rubyweekly.com/issues/ruby-3-3-released", post1.url
    assert_includes post1.author, "ruby-team"
    assert_includes post1.summary, "Ruby 3.3 brings exciting"
    assert_includes post1.tags_array, "ruby"
    assert_includes post1.tags_array, "release"
    assert_equal 'unread', post1.status
    assert post1.priority_score > 0

    post2 = Post.find_by(source: 'rss', title: 'Rails Performance Tips and Tricks')
    assert_not_nil post2
    assert_includes post2.tags_array, "rails"
    assert_includes post2.tags_array, "tutorial"
  end

  test "should not create duplicate posts" do
    # Create an existing post with unique external_id
    unique_id = "test-rss-#{Time.current.to_i}-#{rand(1000)}"
    existing_post = Post.create!(
      source: 'rss',
      external_id: unique_id,
      title: 'Existing RSS Post',
      url: 'https://example.com/existing',
      author: 'test_author',
      posted_at: Time.current,
      status: 'unread'
    )

    # Mock RSS feed with same URL (which will generate same MD5 hash)
    rss_content = <<~RSS
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Test Feed</title>
          <item>
            <title>Different Title</title>
            <link>https://example.com/existing</link>
            <description>Different content</description>
            <pubDate>Tue, 09 Jul 2025 12:00:00 +0000</pubDate>
          </item>
        </channel>
      </rss>
    RSS

    stub_request(:get, @source.url)
      .to_return(status: 200, body: rss_content)

    # Should not create new post (duplicate based on URL)
    assert_no_difference('Post.count') do
      FetchRssJob.perform_now(@source.id)
    end
  end

  test "should handle HTTP errors gracefully" do
    # Mock failed HTTP response
    stub_request(:get, @source.url)
      .to_return(status: 404, body: 'Not Found')

    # Should not create any posts
    assert_no_difference('Post.count') do
      FetchRssJob.perform_now(@source.id)
    end

    # Source status should reflect error
    @source.reload
    assert_includes @source.status, 'error: HTTP 404'
  end

  test "should handle invalid RSS content" do
    # Mock invalid RSS response
    stub_request(:get, @source.url)
      .to_return(status: 200, body: 'This is not valid RSS content')

    assert_no_difference('Post.count') do
      FetchRssJob.perform_now(@source.id)
    end

    @source.reload
    assert_includes @source.status, 'error:'
  end

  test "should handle network timeouts" do
    # Mock timeout
    stub_request(:get, @source.url)
      .to_timeout

    assert_no_difference('Post.count') do
      FetchRssJob.perform_now(@source.id)
    end

    @source.reload
    assert_includes @source.status, 'error:'
  end

  test "should skip non-RSS sources" do
    github_source = sources(:rails_github)
    
    # Should not make any HTTP requests
    assert_no_difference('Post.count') do
      FetchRssJob.perform_now(github_source.id)
    end
  end

  test "should filter by keywords when configured" do
    # Configure source with keyword filtering
    @source.update!(config: '{"keywords": ["ruby", "rails"], "max_items": 20}')
    
    # Mock RSS feed with both matching and non-matching items
    timestamp = Time.current.to_i
    rss_content = <<~RSS
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Mixed Feed</title>
          <item>
            <title>Ruby Programming Tutorial</title>
            <link>https://example.com/ruby-tutorial-#{timestamp}</link>
            <description>Learn Ruby programming basics</description>
            <pubDate>Tue, 09 Jul 2025 12:00:00 +0000</pubDate>
          </item>
          <item>
            <title>JavaScript Framework Comparison</title>
            <link>https://example.com/js-comparison-#{timestamp}</link>
            <description>Comparing different JavaScript frameworks</description>
            <pubDate>Mon, 08 Jul 2025 12:00:00 +0000</pubDate>
          </item>
          <item>
            <title>Rails API Development</title>
            <link>https://example.com/rails-api-#{timestamp}</link>
            <description>Building APIs with Rails framework</description>
            <pubDate>Sun, 07 Jul 2025 12:00:00 +0000</pubDate>
          </item>
        </channel>
      </rss>
    RSS

    stub_request(:get, @source.url)
      .to_return(status: 200, body: rss_content)

    # Should only create posts that match keywords
    assert_difference('Post.count', 2) do  # Ruby and Rails posts, not JavaScript
      FetchRssJob.perform_now(@source.id)
    end

    # Verify only matching posts were created
    ruby_post = Post.find_by(source: 'rss', title: 'Ruby Programming Tutorial')
    rails_post = Post.find_by(source: 'rss', title: 'Rails API Development')
    js_post = Post.find_by(source: 'rss', title: 'JavaScript Framework Comparison')

    assert_not_nil ruby_post
    assert_not_nil rails_post
    assert_nil js_post  # Should be filtered out
  end

  test "should respect max_items configuration" do
    # Configure source with low max_items
    @source.update!(config: '{"max_items": 1}')
    
    # Mock RSS feed with multiple items
    timestamp = Time.current.to_i
    rss_content = <<~RSS
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Many Items Feed</title>
          <item>
            <title>First Item</title>
            <link>https://example.com/first-#{timestamp}</link>
            <description>First item description</description>
            <pubDate>Tue, 09 Jul 2025 12:00:00 +0000</pubDate>
          </item>
          <item>
            <title>Second Item</title>
            <link>https://example.com/second-#{timestamp}</link>
            <description>Second item description</description>
            <pubDate>Mon, 08 Jul 2025 12:00:00 +0000</pubDate>
          </item>
        </channel>
      </rss>
    RSS

    stub_request(:get, @source.url)
      .to_return(status: 200, body: rss_content)

    # Should only create 1 post due to max_items limit
    assert_difference('Post.count', 1) do
      FetchRssJob.perform_now(@source.id)
    end

    # Should have created the first item only
    first_post = Post.find_by(source: 'rss', title: 'First Item')
    second_post = Post.find_by(source: 'rss', title: 'Second Item')

    assert_not_nil first_post
    assert_nil second_post
  end

  test "should process all active RSS sources when no source_id provided" do
    # Create another RSS source  
    rss_source2 = Source.create!(
      name: 'Tech News RSS',
      source_type: 'rss',
      url: 'https://technews.example.com/rss',
      active: true,
      config: '{}'
    )

    # Mock responses for both sources
    timestamp = Time.current.to_i
    rss_content1 = <<~RSS
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Feed 1</title>
          <item>
            <title>RSS Test Item 1</title>
            <link>https://example.com/test1-#{timestamp}</link>
            <description>Test item 1</description>
            <pubDate>Tue, 09 Jul 2025 12:00:00 +0000</pubDate>
          </item>
        </channel>
      </rss>
    RSS

    rss_content2 = <<~RSS
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Feed 2</title>
          <item>
            <title>RSS Test Item 2</title>
            <link>https://technews.example.com/test2-#{timestamp}</link>
            <description>Test item 2</description>
            <pubDate>Tue, 09 Jul 2025 12:00:00 +0000</pubDate>
          </item>
        </channel>
      </rss>
    RSS

    stub_request(:get, @source.url)
      .to_return(status: 200, body: rss_content1)
    
    stub_request(:get, rss_source2.url)
      .to_return(status: 200, body: rss_content2)

    # Should process both RSS sources
    assert_difference('Post.count', 2) do
      FetchRssJob.perform_now
    end
  end

  test "should calculate priority score correctly" do
    # Mock RSS feed with varying content types
    rss_content = <<~RSS
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Priority Test Feed</title>
          <item>
            <title>Ruby Tutorial: Complete Guide for Developers</title>
            <link>https://example.com/ruby-tutorial</link>
            <description>This comprehensive tutorial covers all aspects of Ruby programming for software developers. Learn the fundamentals and advanced concepts.</description>
            <pubDate>#{1.hour.ago.rfc2822}</pubDate>
          </item>
          <item>
            <title>New Framework Release Version 2.0</title>
            <link>https://example.com/release</link>
            <description>Announcing the release of Framework 2.0 with new features</description>
            <pubDate>#{2.hours.ago.rfc2822}</pubDate>
          </item>
          <item>
            <title>Random Blog Post</title>
            <link>https://example.com/random</link>
            <description>Just a short post</description>
            <pubDate>#{1.week.ago.rfc2822}</pubDate>
          </item>
        </channel>
      </rss>
    RSS

    stub_request(:get, @source.url)
      .to_return(status: 200, body: rss_content)

    FetchRssJob.perform_now(@source.id)

    tutorial_post = Post.find_by(source: 'rss', title: 'Ruby Tutorial: Complete Guide for Developers')
    release_post = Post.find_by(source: 'rss', title: 'New Framework Release Version 2.0')
    random_post = Post.find_by(source: 'rss', title: 'Random Blog Post')

    assert_not_nil tutorial_post
    assert_not_nil release_post
    assert_not_nil random_post

    # Tutorial post should have highest score (tutorial keyword + developer keywords + long content + recent)
    assert tutorial_post.priority_score > release_post.priority_score
    assert release_post.priority_score > random_post.priority_score
    
    # Tutorial should get boost for tutorial keyword and developer keywords
    assert tutorial_post.priority_score > 2.0
    
    # Release should get boost for release keyword
    assert release_post.priority_score > 1.5
  end

  test "should handle missing optional fields gracefully" do
    # Mock RSS with minimal required fields
    rss_content = <<~RSS
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Minimal Feed</title>
          <item>
            <title>Minimal RSS Item</title>
            <link>https://example.com/minimal-#{Time.current.to_i}</link>
            <!-- Missing: description, author, pubDate, categories -->
          </item>
        </channel>
      </rss>
    RSS

    stub_request(:get, @source.url)
      .to_return(status: 200, body: rss_content)

    assert_difference('Post.count', 1) do
      FetchRssJob.perform_now(@source.id)
    end

    post = Post.find_by(source: 'rss', title: 'Minimal RSS Item')
    assert_not_nil post
    assert_includes post.url, "https://example.com/minimal"
    assert_equal "Unknown", post.author
    assert_equal "", post.summary
    assert_equal [], post.tags_array
    assert post.priority_score >= 0
  end
end