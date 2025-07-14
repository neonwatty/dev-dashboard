require "test_helper"

class FetchHackerNewsJobTest < ActiveJob::TestCase
  setup do
    @source = sources(:hacker_news)
  end

  test "should fetch and create posts from Hacker News API" do
    # Configure source to only fetch top stories
    @source.update!(config: '{"story_types": ["top"], "min_score": 10}')
    
    # Mock top stories endpoint
    story_ids = [33445566, 33445567]
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/topstories.json")
      .to_return(status: 200, body: story_ids.to_json, headers: { 'Content-Type' => 'application/json' })

    # Mock individual story endpoints
    story1 = {
      "id" => 33445566,
      "type" => "story",
      "title" => "Building a Better JavaScript Framework",
      "by" => "developer123",
      "time" => 1.hour.ago.to_i,
      "score" => 85,
      "descendants" => 42,
      "url" => "https://example.com/js-framework"
    }

    story2 = {
      "id" => 33445567,
      "type" => "story",
      "title" => "Ask HN: Best practices for API design?",
      "by" => "api_expert",
      "time" => 2.hours.ago.to_i,
      "score" => 156,
      "descendants" => 89,
      "text" => "Looking for advice on designing clean and maintainable APIs"
    }

    stub_request(:get, "https://hacker-news.firebaseio.com/v0/item/33445566.json")
      .to_return(status: 200, body: story1.to_json, headers: { 'Content-Type' => 'application/json' })

    stub_request(:get, "https://hacker-news.firebaseio.com/v0/item/33445567.json")
      .to_return(status: 200, body: story2.to_json, headers: { 'Content-Type' => 'application/json' })

    # Perform the job
    assert_difference('Post.count', 2) do
      FetchHackerNewsJob.perform_now(@source.id)
    end

    # Verify source status was updated
    @source.reload
    assert_includes @source.status, 'ok'
    assert_not_nil @source.last_fetched_at

    # Verify posts were created correctly
    post1 = Post.find_by(source: @source.name, external_id: '33445566')
    assert_not_nil post1
    assert_equal "Building a Better JavaScript Framework", post1.title
    assert_equal "https://example.com/js-framework", post1.url
    assert_equal "developer123", post1.author
    assert_includes post1.summary, "85 points"
    assert_includes post1.tags_array, "top"
    assert_includes post1.tags_array, "javascript"
    assert_equal 'unread', post1.status
    assert post1.priority_score > 0

    post2 = Post.find_by(source: @source.name, external_id: '33445567')
    assert_not_nil post2
    assert_equal "Ask HN: Best practices for API design?", post2.title
    assert_equal "https://news.ycombinator.com/item?id=33445567", post2.url  # No external URL
    assert_equal "api_expert", post2.author
    assert_includes post2.summary, "Looking for advice"
    assert_includes post2.tags_array, "top"
  end

  test "should not create duplicate posts" do
    # Create existing post
    existing_post = Post.create!(
      source: @source.name,
      external_id: '33445568',
      title: 'Existing HN Post',
      url: 'https://news.ycombinator.com/item?id=33445568',
      author: 'test_author',
      posted_at: Time.current,
      status: 'unread'
    )

    # Mock API with same story ID
    story_ids = [33445568]
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/topstories.json")
      .to_return(status: 200, body: story_ids.to_json)

    story = {
      "id" => 33445568,
      "type" => "story",
      "title" => "Different Title",
      "by" => "different_user",
      "time" => Time.current.to_i,
      "score" => 50,
      "descendants" => 10
    }

    stub_request(:get, "https://hacker-news.firebaseio.com/v0/item/33445568.json")
      .to_return(status: 200, body: story.to_json)

    # Should not create new post
    assert_no_difference('Post.count') do
      FetchHackerNewsJob.perform_now(@source.id)
    end

    # Original post should remain unchanged
    existing_post.reload
    assert_equal 'Existing HN Post', existing_post.title
    assert_equal 'test_author', existing_post.author
  end

  test "should filter stories by minimum score" do
    # Configure source with minimum score
    @source.update!(config: '{"story_types": ["top"], "min_score": 100}')

    story_ids = [33445569, 33445570]
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/topstories.json")
      .to_return(status: 200, body: story_ids.to_json)

    # High score story (should be included)
    high_score_story = {
      "id" => 33445569,
      "type" => "story",
      "title" => "High Score Story",
      "by" => "user1",
      "time" => Time.current.to_i,
      "score" => 150,
      "descendants" => 50
    }

    # Low score story (should be filtered out)
    low_score_story = {
      "id" => 33445570,
      "type" => "story",
      "title" => "Low Score Story",
      "by" => "user2",
      "time" => Time.current.to_i,
      "score" => 25,
      "descendants" => 5
    }

    stub_request(:get, "https://hacker-news.firebaseio.com/v0/item/33445569.json")
      .to_return(status: 200, body: high_score_story.to_json)

    stub_request(:get, "https://hacker-news.firebaseio.com/v0/item/33445570.json")
      .to_return(status: 200, body: low_score_story.to_json)

    # Should only create high score post
    assert_difference('Post.count', 1) do
      FetchHackerNewsJob.perform_now(@source.id)
    end

    high_post = Post.find_by(source: @source.name, external_id: '33445569')
    low_post = Post.find_by(source: @source.name, external_id: '33445570')

    assert_not_nil high_post
    assert_nil low_post
  end

  test "should filter stories by keywords when configured" do
    # Configure source with keyword filtering
    @source.update!(config: '{"keywords": ["javascript", "programming"], "min_score": 10}')

    story_ids = [33445571, 33445572]
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/topstories.json")
      .to_return(status: 200, body: story_ids.to_json)

    # Matching story
    matching_story = {
      "id" => 33445571,
      "type" => "story",
      "title" => "JavaScript Performance Tips",
      "by" => "js_dev",
      "time" => Time.current.to_i,
      "score" => 75
    }

    # Non-matching story
    non_matching_story = {
      "id" => 33445572,
      "type" => "story",
      "title" => "Design Patterns in Architecture",
      "by" => "architect",
      "time" => Time.current.to_i,
      "score" => 80
    }

    stub_request(:get, "https://hacker-news.firebaseio.com/v0/item/33445571.json")
      .to_return(status: 200, body: matching_story.to_json)

    stub_request(:get, "https://hacker-news.firebaseio.com/v0/item/33445572.json")
      .to_return(status: 200, body: non_matching_story.to_json)

    # Should only create matching post
    assert_difference('Post.count', 1) do
      FetchHackerNewsJob.perform_now(@source.id)
    end

    matching_post = Post.find_by(source: @source.name, external_id: '33445571')
    non_matching_post = Post.find_by(source: @source.name, external_id: '33445572')

    assert_not_nil matching_post
    assert_nil non_matching_post
  end

  test "should handle different story types" do
    # Configure source for Ask HN stories
    @source.update!(config: '{"story_types": ["ask"], "min_score": 10}')

    story_ids = [33445573]
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/askstories.json")
      .to_return(status: 200, body: story_ids.to_json)

    ask_story = {
      "id" => 33445573,
      "type" => "story",
      "title" => "Ask HN: What's your favorite programming language?",
      "by" => "curious_dev",
      "time" => Time.current.to_i,
      "score" => 45,
      "descendants" => 120,
      "text" => "I'm curious about what languages people prefer and why"
    }

    stub_request(:get, "https://hacker-news.firebaseio.com/v0/item/33445573.json")
      .to_return(status: 200, body: ask_story.to_json)

    assert_difference('Post.count', 1) do
      FetchHackerNewsJob.perform_now(@source.id)
    end

    post = Post.find_by(source: @source.name, external_id: '33445573')
    assert_not_nil post
    assert_includes post.tags_array, "ask"
    assert_includes post.tags_array, "ask"  # Should get ask tag from title pattern
    assert post.priority_score > 3.0  # Should get Ask HN boost
  end

  test "should handle API errors gracefully" do
    # Mock failed API response
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/topstories.json")
      .to_return(status: 500, body: 'Internal Server Error')

    # Should not create any posts
    assert_no_difference('Post.count') do
      FetchHackerNewsJob.perform_now(@source.id)
    end

    # Source status should reflect error
    @source.reload
    assert_includes @source.status, 'error:'
  end

  test "should handle network timeouts" do
    # Mock timeout
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/topstories.json")
      .to_timeout

    assert_no_difference('Post.count') do
      FetchHackerNewsJob.perform_now(@source.id)
    end

    @source.reload
    assert_includes @source.status, 'error:'
  end

  test "should skip non-story items" do
    story_ids = [33445574]
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/topstories.json")
      .to_return(status: 200, body: story_ids.to_json)

    # Mock non-story item (comment)
    comment = {
      "id" => 33445574,
      "type" => "comment",  # Not a story
      "text" => "This is a comment",
      "by" => "commenter",
      "time" => Time.current.to_i
    }

    stub_request(:get, "https://hacker-news.firebaseio.com/v0/item/33445574.json")
      .to_return(status: 200, body: comment.to_json)

    # Should not create any posts
    assert_no_difference('Post.count') do
      FetchHackerNewsJob.perform_now(@source.id)
    end
  end

  test "should calculate priority score correctly" do
    story_ids = [33445575, 33445576, 33445577]
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/topstories.json")
      .to_return(status: 200, body: story_ids.to_json)

    # High engagement, recent, developer-relevant
    high_priority_story = {
      "id" => 33445575,
      "type" => "story",
      "title" => "New React Framework Tutorial with TypeScript",
      "by" => "react_expert",
      "time" => 1.hour.ago.to_i,
      "score" => 250,
      "descendants" => 150
    }

    # Medium engagement, Ask HN
    medium_priority_story = {
      "id" => 33445576,
      "type" => "story",
      "title" => "Ask HN: How do you manage technical debt?",
      "by" => "tech_lead",
      "time" => 3.hours.ago.to_i,
      "score" => 89,
      "descendants" => 67
    }

    # Low engagement, old, non-developer topic
    low_priority_story = {
      "id" => 33445577,
      "type" => "story",
      "title" => "Random Business Story",
      "by" => "business_user",
      "time" => 1.day.ago.to_i,
      "score" => 15,
      "descendants" => 3
    }

    stub_request(:get, "https://hacker-news.firebaseio.com/v0/item/33445575.json")
      .to_return(status: 200, body: high_priority_story.to_json)

    stub_request(:get, "https://hacker-news.firebaseio.com/v0/item/33445576.json")
      .to_return(status: 200, body: medium_priority_story.to_json)

    stub_request(:get, "https://hacker-news.firebaseio.com/v0/item/33445577.json")
      .to_return(status: 200, body: low_priority_story.to_json)

    FetchHackerNewsJob.perform_now(@source.id)

    high_post = Post.find_by(source: @source.name, external_id: '33445575')
    medium_post = Post.find_by(source: @source.name, external_id: '33445576')
    low_post = Post.find_by(source: @source.name, external_id: '33445577')

    # Verify posts were created and have correct priority ordering
    assert_not_nil high_post
    assert_not_nil medium_post
    assert_not_nil low_post

    assert high_post.priority_score > medium_post.priority_score
    assert medium_post.priority_score > low_post.priority_score

    # High priority should get boosts for React, framework, tutorial, TypeScript
    assert high_post.priority_score > 20.0

    # Medium priority should get Ask HN boost
    assert medium_post.priority_score > 3.0
  end

  test "should handle missing optional fields gracefully" do
    story_ids = [33445578]
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/topstories.json")
      .to_return(status: 200, body: story_ids.to_json)

    # Story with minimal fields
    minimal_story = {
      "id" => 33445578,
      "type" => "story",
      "title" => "Minimal Story",
      "time" => Time.current.to_i
      # Missing: by, score, descendants, url, text
    }

    stub_request(:get, "https://hacker-news.firebaseio.com/v0/item/33445578.json")
      .to_return(status: 200, body: minimal_story.to_json)

    assert_difference('Post.count', 1) do
      FetchHackerNewsJob.perform_now(@source.id)
    end

    post = Post.find_by(source: @source.name, external_id: '33445578')
    assert_not_nil post
    assert_equal "Minimal Story", post.title
    assert_equal "https://news.ycombinator.com/item?id=33445578", post.url
    assert_equal "unknown", post.author
    assert_includes post.summary, "0 points"
    assert_includes post.summary, "0 comments"
    assert post.priority_score >= 0
  end

  test "should create default HN source when none provided" do
    # Remove existing HN source if it exists
    Source.where(name: 'Hacker News').destroy_all
    
    # Mock empty API response so job completes
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/topstories.json")
      .to_return(status: 200, body: [].to_json)
    
    # Call job without source_id
    assert_difference('Source.count', 1) do
      FetchHackerNewsJob.perform_now
    end

    hn_source = Source.find_by(name: 'Hacker News')
    assert_not_nil hn_source
    assert_equal 'rss', hn_source.source_type
    assert_equal 'https://news.ycombinator.com', hn_source.url
    assert hn_source.active
  end
end