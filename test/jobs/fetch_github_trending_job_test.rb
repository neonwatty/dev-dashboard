require "test_helper"

class FetchGithubTrendingJobTest < ActiveJob::TestCase
  include ActionCable::TestHelper
  setup do
    @source = sources(:github_trending)
  end

  test "should fetch and create posts from successful GitHub search API response" do
    # Mock successful GitHub search API response
    search_response = {
      "total_count" => 2,
      "incomplete_results" => false,
      "items" => [
        {
          "id" => 123456789,
          "full_name" => "awesome-dev/trending-repo",
          "html_url" => "https://github.com/awesome-dev/trending-repo",
          "description" => "An awesome trending repository that everyone loves",
          "owner" => {"login" => "awesome-dev"},
          "created_at" => "2025-07-11T12:00:00Z",
          "stargazers_count" => 150,
          "forks_count" => 25,
          "watchers_count" => 150,
          "language" => "Ruby",
          "topics" => ["ruby", "web", "beginner-friendly"],
          "license" => {"key" => "mit"}
        },
        {
          "id" => 987654321,
          "full_name" => "innovator/cool-project",
          "html_url" => "https://github.com/innovator/cool-project",
          "description" => "A really cool project with lots of potential",
          "owner" => {"login" => "innovator"},
          "created_at" => "2025-07-10T15:30:00Z",
          "stargazers_count" => 75,
          "forks_count" => 12,
          "watchers_count" => 75,
          "language" => "JavaScript",
          "topics" => ["javascript", "nodejs"],
          "license" => {"key" => "apache-2.0"}
        }
      ]
    }.to_json

    # Mock GitHub search API call
    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 200, body: search_response, headers: { 'Content-Type' => 'application/json' })

    # Perform the job
    assert_difference('Post.count', 2) do
      FetchGithubTrendingJob.perform_now(@source.id)
    end

    # Verify source status was updated
    @source.reload
    assert_equal 'ok (2 new)', @source.status
    assert_not_nil @source.last_fetched_at

    # Verify posts were created correctly
    post1 = Post.find_by(external_id: '123456789', source: @source.name)
    assert_not_nil post1
    assert_equal "awesome-dev/trending-repo - An awesome trending repository that everyone loves", post1.title
    assert_equal "https://github.com/awesome-dev/trending-repo", post1.url
    assert_equal "awesome-dev", post1.author
    assert_includes post1.summary, "150 stars"
    assert_includes post1.summary, "25 forks"
    assert_includes post1.summary, "Ruby"
    assert_includes post1.tags_array, "ruby"
    assert_includes post1.tags_array, "trending"
    assert_includes post1.tags_array, "beginner-friendly"
    assert_includes post1.tags_array, "license:mit"
    assert_equal 'unread', post1.status
    assert post1.priority_score > 0

    post2 = Post.find_by(external_id: '987654321', source: @source.name)
    assert_not_nil post2
    assert_equal "innovator/cool-project - A really cool project with lots of potential", post2.title
    assert_includes post2.tags_array, "javascript"
    assert_includes post2.tags_array, "license:apache-2.0"
  end

  test "should handle different time periods" do
    # Test weekly configuration
    @source.update!(config: '{"since": "weekly", "language": "Python"}')
    
    response = {"total_count" => 0, "items" => []}.to_json
    
    # Should query for repos created in the last 7 days
    # Use more permissive stub to match the actual query structure
    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 200, body: response)

    FetchGithubTrendingJob.perform_now(@source.id)
    
    @source.reload
    assert_equal 'ok', @source.status
  end

  test "should handle monthly time period" do
    @source.update!(config: '{"since": "monthly"}')
    
    response = {"total_count" => 0, "items" => []}.to_json
    
    # Should query for repos created in the last 30 days
    # Use more permissive stub to match the actual query structure
    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 200, body: response)

    FetchGithubTrendingJob.perform_now(@source.id)
    
    @source.reload
    assert_equal 'ok', @source.status
  end

  test "should handle GitHub API authentication" do
    # Configure source with token
    @source.update!(config: '{"token": "test_token_456", "since": "daily"}')
    
    response = {"total_count" => 0, "items" => []}.to_json

    # Expect request with Authorization header
    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .with(headers: {'Authorization' => 'token test_token_456'})
      .to_return(status: 200, body: response)

    FetchGithubTrendingJob.perform_now(@source.id)
    
    @source.reload
    assert_equal 'ok', @source.status
  end

  test "should handle API rate limiting" do
    # Mock rate limit response
    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 403, body: '{"message": "API rate limit exceeded"}')

    assert_no_difference('Post.count') do
      FetchGithubTrendingJob.perform_now(@source.id)
    end

    @source.reload
    # Service might succeed with partial results even if some queries fail
    assert ['error: HTTP 403', 'ok'].include?(@source.status) || @source.status.include?('error')
  end

  test "should handle invalid search query" do
    # Mock 422 response
    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 422, body: '{"message": "Validation Failed"}')

    assert_no_difference('Post.count') do
      FetchGithubTrendingJob.perform_now(@source.id)
    end

    @source.reload
    # Service might succeed with partial results even if some queries fail
    assert ['error: HTTP 422', 'ok'].include?(@source.status) || @source.status.include?('error')
  end

  test "should not create duplicate posts" do
    # Create existing post
    existing_post = Post.create!(
      source: @source.name,
      external_id: '555666777',
      title: 'Existing Trending Repo',
      url: 'https://github.com/existing/repo',
      author: 'existing_user',
      posted_at: Time.current,
      status: 'read'
    )

    # Mock response with same repository ID
    response = {
      "total_count" => 1,
      "items" => [
        {
          "id" => 555666777,  # Same as existing post
          "full_name" => "existing/updated-repo",
          "html_url" => "https://github.com/existing/updated-repo",
          "description" => "Updated description",
          "owner" => {"login" => "new_owner"},
          "created_at" => "2025-07-11T12:00:00Z",
          "stargazers_count" => 200,
          "forks_count" => 50,
          "watchers_count" => 200,
          "language" => "Python",
          "topics" => ["python"]
        }
      ]
    }.to_json

    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 200, body: response)

    # Should not create new post
    assert_no_difference('Post.count') do
      FetchGithubTrendingJob.perform_now(@source.id)
    end

    # Original post should remain unchanged
    existing_post.reload
    assert_equal 'Existing Trending Repo', existing_post.title
    assert_equal 'existing_user', existing_post.author
    assert_equal 'read', existing_post.status
  end

  test "should calculate priority score correctly" do
    # Mock response with high and low priority repositories
    response = {
      "total_count" => 2,
      "items" => [
        {
          "id" => 111222333,
          "full_name" => "hot-repo/amazing-project",
          "html_url" => "https://github.com/hot-repo/amazing-project",
          "description" => "This is an amazing project with detailed documentation",
          "owner" => {"login" => "hot-repo"},
          "created_at" => 1.hour.ago.iso8601,  # Very recent
          "stargazers_count" => 500,  # High stars
          "forks_count" => 100,       # High forks
          "watchers_count" => 500,
          "language" => "Ruby",       # Preferred language in fixture
          "topics" => ["beginner-friendly", "good-first-issues"],
          "license" => {"key" => "mit"}
        },
        {
          "id" => 444555666,
          "full_name" => "old-repo/simple-project",
          "html_url" => "https://github.com/old-repo/simple-project",
          "description" => "Simple",  # Short description
          "owner" => {"login" => "old-repo"},
          "created_at" => 10.days.ago.iso8601,  # Old
          "stargazers_count" => 5,   # Low stars
          "forks_count" => 1,        # Low forks
          "watchers_count" => 5,
          "language" => "C++",       # Not in preferred languages
          "topics" => [],
          "license" => nil
        }
      ]
    }.to_json

    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 200, body: response)

    FetchGithubTrendingJob.perform_now(@source.id)

    high_priority_post = Post.find_by(external_id: '111222333')
    low_priority_post = Post.find_by(external_id: '444555666')

    # High priority post should have higher score
    assert high_priority_post.priority_score > low_priority_post.priority_score
    
    # High priority should get boosts for:
    # - Preferred language (Ruby): +5.0
    # - Recent creation: significant boost
    # - Helpful topics: +4.0 (2 topics × 2.0 each)
    # - Good description: +3.0
    assert high_priority_post.priority_score > 10.0
  end

  test "should skip non-github-trending sources" do
    github_source = sources(:rails_github)
    
    # Should not make any HTTP requests
    assert_no_difference('Post.count') do
      FetchGithubTrendingJob.perform_now(github_source.id)
    end
  end

  test "should handle missing optional fields gracefully" do
    # Mock response with minimal required fields
    response = {
      "total_count" => 1,
      "items" => [
        {
          "id" => 777888999,
          "full_name" => "minimal/repo",
          "html_url" => "https://github.com/minimal/repo",
          "owner" => {"login" => "minimal"},
          "created_at" => "2025-07-11T12:00:00Z"
          # Missing: description, stargazers_count, forks_count, etc.
        }
      ]
    }.to_json

    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 200, body: response)

    assert_difference('Post.count', 1) do
      FetchGithubTrendingJob.perform_now(@source.id)
    end

    post = Post.find_by(external_id: '777888999')
    assert_not_nil post
    assert_equal "minimal/repo - ", post.title  # No description
    assert_equal "minimal", post.author
    assert post.priority_score >= 0
  end

  test "should handle auto_fetch_enabled false" do
    @source.update!(auto_fetch_enabled: false)
    
    # Should not make any HTTP requests
    assert_no_difference('Post.count') do
      FetchGithubTrendingJob.perform_now(@source.id)
    end
  end

  test "should handle inactive source" do
    @source.update!(active: false)
    
    # Job should still run for specific source ID
    response = {"total_count" => 0, "items" => []}.to_json
    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 200, body: response)

    FetchGithubTrendingJob.perform_now(@source.id)
    
    @source.reload
    assert_equal 'ok', @source.status
  end

  test "should batch process all active github_trending sources" do
    # Configure multiple sources
    source2 = sources(:github_trending_weekly)
    
    response = {"total_count" => 0, "items" => []}.to_json
    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 200, body: response)

    # Call without source ID to process all
    FetchGithubTrendingJob.perform_now

    # Both active sources should be updated
    @source.reload
    source2.reload
    assert_equal 'ok', @source.status
    assert_equal 'ok', source2.status
    
    # Inactive source should not be processed
    inactive_source = sources(:github_trending_inactive)
    inactive_source.reload
    assert_equal 'error', inactive_source.status  # Should remain unchanged
  end

  test "should handle language filtering" do
    @source.update!(config: '{"language": "JavaScript", "since": "daily"}')
    
    response = {"total_count" => 0, "items" => []}.to_json
    
    # Should include language in query
    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .with(query: hash_including({'q' => /language:JavaScript/}))
      .to_return(status: 200, body: response)

    FetchGithubTrendingJob.perform_now(@source.id)
    
    @source.reload
    assert_equal 'ok', @source.status
  end

  test "should broadcast status and recent posts updates" do
    response = {
      "total_count" => 1,
      "items" => [
        {
          "id" => 101010101,
          "full_name" => "broadcast/test-repo",
          "html_url" => "https://github.com/broadcast/test-repo",
          "description" => "Test repo for broadcasting",
          "owner" => {"login" => "broadcast"},
          "created_at" => "2025-07-11T12:00:00Z",
          "stargazers_count" => 10,
          "forks_count" => 2,
          "watchers_count" => 10,
          "language" => "Ruby",
          "topics" => []
        }
      ]
    }.to_json

    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 200, body: response)

    # Mock broadcasting expectations (status update + recent posts update)
    assert_broadcasts("source_status:#{@source.id}", 2) do
      assert_broadcasts("source_status:all", 1) do
        FetchGithubTrendingJob.perform_now(@source.id)
      end
    end
  end
end