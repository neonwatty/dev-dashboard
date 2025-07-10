require "test_helper"

class JobExecutionWorkflowTest < ActionDispatch::IntegrationTest
  setup do
    @source = sources(:huggingface_forum)
    # Clear any existing posts to ensure clean test state
    Post.destroy_all
    @user = users(:one)
    sign_in_as(@user)
  end

  test "workflow: fetch posts from source and view them" do
    # Mock HuggingFace API response
    response_body = {
      "topic_list" => {
        "topics" => [
          {
            "id" => 777001,
            "title" => "Integration Test Topic",
            "slug" => "integration-test-topic",
            "created_at" => 1.hour.ago.iso8601,
            "last_poster_username" => "test_user",
            "excerpt" => "This is a test topic for integration testing",
            "tags" => ["test", "integration"],
            "reply_count" => 5,
            "like_count" => 10,
            "views" => 50
          }
        ]
      }
    }.to_json

    stub_request(:get, "#{@source.url}/latest.json")
      .to_return(status: 200, body: response_body, headers: { 'Content-Type' => 'application/json' })

    # Execute the job
    assert_difference("Post.count", 1) do
      FetchHuggingFaceJob.perform_now(@source.id)
    end

    # Verify source was updated
    @source.reload
    assert_equal "ok", @source.status
    assert_not_nil @source.last_fetched_at

    # Visit posts page
    get posts_path
    assert_response :success

    # Verify the fetched post appears
    assert_select "h2", "Integration Test Topic"
    assert_select "span", text: "test_user"
    assert_select "span", text: "unread"

    # Click on the post to mark as read
    post = Post.last
    patch mark_as_read_post_path(post)
    assert_redirected_to posts_path

    # Verify status changed
    post.reload
    assert_equal "read", post.status
  end

  test "workflow: handle job failures gracefully" do
    # Mock API failure
    stub_request(:get, "#{@source.url}/latest.json")
      .to_return(status: 500, body: "Internal Server Error")

    # Execute the job - should not create posts
    assert_no_difference("Post.count") do
      FetchHuggingFaceJob.perform_now(@source.id)
    end

    # Source should have error status
    @source.reload
    assert_includes @source.status, "error"

    # Visit sources page
    get sources_path
    assert_response :success

    # Should show error status
    assert_select "span.text-red-600", text: /error/
  end

  test "workflow: fetch from multiple sources concurrently" do
    # Create additional sources
    github_source = sources(:rails_github)
    pytorch_source = sources(:pytorch_forum)

    # Mock all API responses
    stub_request(:get, "#{@source.url}/latest.json")
      .to_return(status: 200, body: {
        "topic_list" => {
          "topics" => [{
            "id" => 777002,
            "title" => "HuggingFace Topic",
            "slug" => "hf-topic",
            "created_at" => Time.current.iso8601,
            "last_poster_username" => "hf_user",
            "excerpt" => "HF content",
            "tags" => [],
            "reply_count" => 0,
            "like_count" => 0,
            "views" => 1
          }]
        }
      }.to_json)

    stub_request(:get, /api\.github\.com\/repos\/rails\/rails\/issues/)
      .to_return(status: 200, body: [{
        "number" => 777003,
        "title" => "GitHub Issue",
        "html_url" => "https://github.com/rails/rails/issues/777003",
        "user" => {"login" => "gh_user"},
        "created_at" => Time.current.iso8601,
        "body" => "Issue content",
        "labels" => [],
        "comments" => 0,
        "reactions" => {"total_count" => 0},
        "pull_request" => nil
      }].to_json)

    stub_request(:get, "#{pytorch_source.url}/latest.json")
      .to_return(status: 200, body: {
        "topic_list" => {
          "topics" => [{
            "id" => 777004,
            "title" => "PyTorch Topic",
            "slug" => "pytorch-topic",
            "created_at" => Time.current.iso8601,
            "last_poster_username" => "pytorch_user",
            "excerpt" => "PyTorch content",
            "tags" => [],
            "reply_count" => 0,
            "like_count" => 0,
            "views" => 1
          }]
        }
      }.to_json)

    # Execute jobs
    assert_difference("Post.count", 3) do
      FetchHuggingFaceJob.perform_now(@source.id)
      FetchGithubIssuesJob.perform_now(github_source.id)
      FetchPytorchJob.perform_now(pytorch_source.id)
    end

    # Visit posts page
    get posts_path
    assert_response :success

    # All posts should be visible
    assert_select "h2", "HuggingFace Topic"
    assert_select "h2", "GitHub Issue"
    assert_select "h2", "PyTorch Topic"

    # Filter by source
    get posts_path(source: "huggingface")
    assert_response :success
    assert_select "h2", "HuggingFace Topic"
    assert_select "h2", text: "GitHub Issue", count: 0
    assert_select "h2", text: "PyTorch Topic", count: 0
  end

  test "workflow: prevent duplicate posts on repeated job runs" do
    # Mock API response
    response_body = {
      "topic_list" => {
        "topics" => [
          {
            "id" => 777005,
            "title" => "Duplicate Test Topic",
            "slug" => "duplicate-test",
            "created_at" => 1.hour.ago.iso8601,
            "last_poster_username" => "dup_user",
            "excerpt" => "Testing duplicate prevention",
            "tags" => [],
            "reply_count" => 1,
            "like_count" => 2,
            "views" => 10
          }
        ]
      }
    }.to_json

    stub_request(:get, "#{@source.url}/latest.json")
      .to_return(status: 200, body: response_body)

    # First run - should create post
    assert_difference("Post.count", 1) do
      FetchHuggingFaceJob.perform_now(@source.id)
    end

    first_post = Post.last
    original_title = first_post.title
    original_author = first_post.author

    # Modify the API response slightly
    modified_response = JSON.parse(response_body)
    modified_response["topic_list"]["topics"][0]["title"] = "Modified Title"
    modified_response["topic_list"]["topics"][0]["last_poster_username"] = "different_user"

    stub_request(:get, "#{@source.url}/latest.json")
      .to_return(status: 200, body: modified_response.to_json)

    # Second run - should NOT create duplicate
    assert_no_difference("Post.count") do
      FetchHuggingFaceJob.perform_now(@source.id)
    end

    # Original post should remain unchanged
    first_post.reload
    assert_equal original_title, first_post.title
    assert_equal original_author, first_post.author
  end

  test "workflow: RSS feed with keyword filtering" do
    rss_source = sources(:ruby_blog_rss)
    rss_source.update!(config: '{"keywords": ["rails", "ruby"], "max_items": 10}')

    # Mock RSS feed
    rss_content = <<~RSS
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Dev Blog</title>
          <item>
            <title>Rails 8 Performance Guide</title>
            <link>https://blog.example.com/rails-performance</link>
            <description>Learn about Rails 8 performance improvements</description>
            <pubDate>#{1.hour.ago.rfc2822}</pubDate>
          </item>
          <item>
            <title>JavaScript Framework Comparison</title>
            <link>https://blog.example.com/js-frameworks</link>
            <description>Comparing popular JavaScript frameworks</description>
            <pubDate>#{2.hours.ago.rfc2822}</pubDate>
          </item>
          <item>
            <title>Ruby Metaprogramming Tips</title>
            <link>https://blog.example.com/ruby-meta</link>
            <description>Advanced Ruby metaprogramming techniques</description>
            <pubDate>#{3.hours.ago.rfc2822}</pubDate>
          </item>
        </channel>
      </rss>
    RSS

    stub_request(:get, rss_source.url)
      .to_return(status: 200, body: rss_content)

    # Execute RSS job - should only create posts matching keywords
    assert_difference("Post.count", 2) do  # Rails and Ruby posts only
      FetchRssJob.perform_now(rss_source.id)
    end

    # Visit posts page
    get posts_path
    assert_response :success

    # Should see Rails and Ruby posts
    assert_select "h2", "Rails 8 Performance Guide"
    assert_select "h2", "Ruby Metaprogramming Tips"
    
    # Should NOT see JavaScript post
    assert_select "h2", text: "JavaScript Framework Comparison", count: 0
  end

  test "workflow: priority score affects post ordering" do
    # Create posts with different priority scores
    high_priority = Post.create!(
      source: "huggingface",
      external_id: "priority-1",
      title: "High Priority Post",
      url: "https://example.com/high",
      author: "author1",
      posted_at: 3.hours.ago,
      status: "unread",
      priority_score: 25.0
    )

    medium_priority = Post.create!(
      source: "github",
      external_id: "priority-2",
      title: "Medium Priority Post",
      url: "https://example.com/medium",
      author: "author2",
      posted_at: 1.hour.ago,  # More recent but lower priority
      status: "unread",
      priority_score: 10.0
    )

    low_priority = Post.create!(
      source: "rss",
      external_id: "priority-3",
      title: "Low Priority Post",
      url: "https://example.com/low",
      author: "author3",
      posted_at: 30.minutes.ago,  # Most recent but lowest priority
      status: "unread",
      priority_score: 2.0
    )

    # Visit posts page (default sort is by priority)
    get posts_path
    assert_response :success

    # Posts should be ordered by priority score (high to low)
    post_titles = css_select("h2").map(&:text).map(&:strip)
    expected_order = [
      "High Priority Post",
      "Medium Priority Post", 
      "Low Priority Post"
    ]
    
    assert_equal expected_order, post_titles
  end
end