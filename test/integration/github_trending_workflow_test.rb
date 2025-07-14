require "test_helper"

class GithubTrendingWorkflowTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "complete workflow: create GitHub Trending source and fetch posts" do
    # Step 1: Create a new GitHub Trending source
    assert_difference('Source.count', 1) do
      post sources_path, params: {
        source: {
          name: 'Daily JavaScript Trending',
          source_type: 'github_trending',
          active: true,
          auto_fetch_enabled: true,
          config: {
            since: 'daily',
            language: 'JavaScript',
            preferred_languages: ['JavaScript', 'TypeScript'],
            token: 'github_token_test'
          }.to_json
        }
      }
    end
    
    follow_redirect!
    assert_response :success
    
    source = Source.last
    assert_equal 'github_trending', source.source_type
    assert_equal 'Daily JavaScript Trending', source.name
    assert source.active?
    assert source.auto_fetch_enabled?
    assert_nil source.url  # GitHub Trending doesn't need URL
    
    config = source.config_hash
    assert_equal 'daily', config['since']
    assert_equal 'JavaScript', config['language']
    assert_equal ['JavaScript', 'TypeScript'], config['preferred_languages']
    assert_equal 'github_token_test', config['token']

    # Step 2: Mock GitHub API and fetch posts
    search_response = {
      "total_count" => 2,
      "items" => [
        {
          "id" => 123456789,
          "full_name" => "trending/awesome-js-lib",
          "html_url" => "https://github.com/trending/awesome-js-lib",
          "description" => "An awesome JavaScript library",
          "owner" => {"login" => "trending"},
          "created_at" => 6.hours.ago.iso8601,
          "stargazers_count" => 250,
          "forks_count" => 45,
          "watchers_count" => 250,
          "language" => "JavaScript",
          "topics" => ["javascript", "library", "beginner-friendly"],
          "license" => {"key" => "mit"}
        },
        {
          "id" => 987654321,
          "full_name" => "newdev/typescript-starter",
          "html_url" => "https://github.com/newdev/typescript-starter",
          "description" => "TypeScript project starter template",
          "owner" => {"login" => "newdev"},
          "created_at" => 12.hours.ago.iso8601,
          "stargazers_count" => 180,
          "forks_count" => 32,
          "watchers_count" => 180,
          "language" => "TypeScript",
          "topics" => ["typescript", "template", "starter"],
          "license" => {"key" => "apache-2.0"}
        }
      ]
    }.to_json

    # Mock the API call with proper parameters
    expected_date = (Date.current - 1.day).strftime('%Y-%m-%d')
    stub_request(:get, "https://api.github.com/search/repositories")
      .with(
        query: hash_including({
          'q' => "created:>#{expected_date} stars:>1 language:JavaScript",
          'sort' => 'stars',
          'order' => 'desc',
          'per_page' => '30'
        }),
        headers: {
          'Authorization' => 'token github_token_test',
          'Accept' => 'application/vnd.github.v3+json',
          'User-Agent' => 'DevDashboard/1.0'
        }
      )
      .to_return(status: 200, body: search_response, headers: { 'Content-Type' => 'application/json' })

    # Step 3: Trigger the job and verify posts are created
    assert_difference('Post.count', 2) do
      perform_enqueued_jobs do
        FetchGithubTrendingJob.perform_now(source.id)
      end
    end

    # Verify source status was updated
    source.reload
    assert_equal 'ok (2 new)', source.status
    assert_not_nil source.last_fetched_at

    # Step 4: Verify posts were created correctly
    js_post = Post.find_by(external_id: '123456789', source: 'github_trending')
    assert_not_nil js_post
    assert_equal 'trending/awesome-js-lib - An awesome JavaScript library', js_post.title
    assert_equal 'https://github.com/trending/awesome-js-lib', js_post.url
    assert_equal 'trending', js_post.author
    assert_equal 'unread', js_post.status
    assert_includes js_post.summary, '⭐ 250 stars'
    assert_includes js_post.summary, '🍴 45 forks'
    assert_includes js_post.summary, '📝 JavaScript'
    
    js_tags = js_post.tags_array
    assert_includes js_tags, 'javascript'
    assert_includes js_tags, 'library'
    assert_includes js_tags, 'beginner-friendly'
    assert_includes js_tags, 'trending'
    assert_includes js_tags, 'new-repo'
    assert_includes js_tags, 'popular'
    assert_includes js_tags, 'license:mit'

    ts_post = Post.find_by(external_id: '987654321', source: 'github_trending')
    assert_not_nil ts_post
    assert_equal 'newdev/typescript-starter - TypeScript project starter template', ts_post.title
    assert_includes ts_post.tags_array, 'typescript'

    # JavaScript post should have higher priority (preferred language)
    assert js_post.priority_score > ts_post.priority_score

    # Step 5: Navigate to posts page and verify filtering
    get posts_path
    assert_response :success
    assert_select 'h1', text: /Posts/
    
    # Verify both posts appear
    assert_select 'a', text: /trending\/awesome-js-lib/
    assert_select 'a', text: /newdev\/typescript-starter/

    # Step 6: Filter by source
    get posts_path, params: { source: 'github_trending' }
    assert_response :success
    assert_select 'a', text: /trending\/awesome-js-lib/
    assert_select 'a', text: /newdev\/typescript-starter/

    # Step 7: Filter by tag
    get posts_path, params: { tag: 'javascript' }
    assert_response :success
    assert_select 'a', text: /trending\/awesome-js-lib/
    # TypeScript post should not appear
    assert_select 'a', text: /newdev\/typescript-starter/, count: 0

    # Step 8: Search functionality
    get posts_path, params: { keyword: 'awesome' }
    assert_response :success
    assert_select 'a', text: /trending\/awesome-js-lib/
    assert_select 'a', text: /newdev\/typescript-starter/, count: 0

    # Step 9: Navigate to source page and verify recent posts
    get source_path(source)
    assert_response :success
    assert_select 'h1', text: /Daily JavaScript Trending/
    assert_select '.recent-posts', text: /trending\/awesome-js-lib/
    assert_select '.recent-posts', text: /newdev\/typescript-starter/
  end

  test "should handle GitHub Trending source without URL field" do
    # Verify URL field is not required for github_trending
    post sources_path, params: {
      source: {
        name: 'Test Trending Source',
        source_type: 'github_trending',
        active: true,
        config: '{"since": "weekly"}'
        # No URL provided
      }
    }
    
    follow_redirect!
    assert_response :success
    
    source = Source.last
    assert_equal 'github_trending', source.source_type
    assert_nil source.url
    assert source.valid?
  end

  test "should handle auto-fetch toggle for GitHub Trending sources" do
    source = sources(:github_trending)
    source.update!(auto_fetch_enabled: false)
    
    # Should not create any posts when auto_fetch_enabled is false
    assert_no_difference('Post.count') do
      perform_enqueued_jobs do
        FetchGithubTrendingJob.perform_now(source.id)
      end
    end
    
    # Enable auto-fetch
    source.update!(auto_fetch_enabled: true)
    
    search_response = {
      "total_count" => 1,
      "items" => [
        {
          "id" => 555444333,
          "full_name" => "test/auto-fetch-repo",
          "html_url" => "https://github.com/test/auto-fetch-repo",
          "description" => "Test repository",
          "owner" => {"login" => "test"},
          "created_at" => "2025-07-11T12:00:00Z",
          "stargazers_count" => 10,
          "forks_count" => 2
        }
      ]
    }.to_json

    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 200, body: search_response)

    # Should create posts when auto_fetch_enabled is true
    assert_difference('Post.count', 1) do
      perform_enqueued_jobs do
        FetchGithubTrendingJob.perform_now(source.id)
      end
    end
  end

  test "should handle GitHub API errors gracefully" do
    source = sources(:github_trending)
    
    # Mock rate limit error
    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 403, body: '{"message": "API rate limit exceeded"}')

    assert_no_difference('Post.count') do
      perform_enqueued_jobs do
        FetchGithubTrendingJob.perform_now(source.id)
      end
    end

    source.reload
    assert_includes source.status, 'error: HTTP 403'
    assert_includes source.status, 'Rate limit exceeded'
  end

  test "should filter GitHub Trending posts by different time periods" do
    # Create sources with different time periods
    daily_source = Source.create!(
      name: 'Daily Trending',
      source_type: 'github_trending',
      config: '{"since": "daily"}',
      active: true,
      auto_fetch_enabled: true
    )
    
    weekly_source = Source.create!(
      name: 'Weekly Trending',
      source_type: 'github_trending',
      config: '{"since": "weekly"}',
      active: true,
      auto_fetch_enabled: true
    )

    # Mock responses for different time periods
    daily_response = {
      "total_count" => 1,
      "items" => [
        {
          "id" => 111111111,
          "full_name" => "daily/trending-repo",
          "html_url" => "https://github.com/daily/trending-repo",
          "description" => "Daily trending repository",
          "owner" => {"login" => "daily"},
          "created_at" => 6.hours.ago.iso8601
        }
      ]
    }.to_json

    weekly_response = {
      "total_count" => 1,
      "items" => [
        {
          "id" => 222222222,
          "full_name" => "weekly/trending-repo",
          "html_url" => "https://github.com/weekly/trending-repo",
          "description" => "Weekly trending repository",
          "owner" => {"login" => "weekly"},
          "created_at" => 3.days.ago.iso8601
        }
      ]
    }.to_json

    # Mock daily API call
    daily_date = (Date.current - 1.day).strftime('%Y-%m-%d')
    stub_request(:get, "https://api.github.com/search/repositories")
      .with(query: hash_including({'q' => "created:>#{daily_date} stars:>1"}))
      .to_return(status: 200, body: daily_response)

    # Mock weekly API call
    weekly_date = (Date.current - 7.days).strftime('%Y-%m-%d')
    stub_request(:get, "https://api.github.com/search/repositories")
      .with(query: hash_including({'q' => "created:>#{weekly_date} stars:>1"}))
      .to_return(status: 200, body: weekly_response)

    # Execute jobs
    assert_difference('Post.count', 2) do
      perform_enqueued_jobs do
        FetchGithubTrendingJob.perform_now(daily_source.id)
        FetchGithubTrendingJob.perform_now(weekly_source.id)
      end
    end

    daily_post = Post.find_by(external_id: '111111111')
    weekly_post = Post.find_by(external_id: '222222222')
    
    assert_not_nil daily_post
    assert_not_nil weekly_post
    assert_equal 'daily/trending-repo - Daily trending repository', daily_post.title
    assert_equal 'weekly/trending-repo - Weekly trending repository', weekly_post.title
  end

  test "should batch process all active GitHub Trending sources" do
    # Ensure we have multiple active sources
    source1 = sources(:github_trending)
    source2 = sources(:github_trending_weekly)
    inactive_source = sources(:github_trending_inactive)

    search_response = {
      "total_count" => 1,
      "items" => [
        {
          "id" => 777888999,
          "full_name" => "batch/test-repo",
          "html_url" => "https://github.com/batch/test-repo",
          "description" => "Batch processing test",
          "owner" => {"login" => "batch"},
          "created_at" => "2025-07-11T12:00:00Z"
        }
      ]
    }.to_json

    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 200, body: search_response)

    # Execute batch job (no source ID)
    assert_difference('Post.count', 2) do  # Only active sources
      perform_enqueued_jobs do
        FetchGithubTrendingJob.perform_now  # No source ID = batch mode
      end
    end

    # Verify both active sources were updated
    source1.reload
    source2.reload
    inactive_source.reload
    
    assert_equal 'ok (1 new)', source1.status
    assert_equal 'ok (1 new)', source2.status
    assert_equal 'error', inactive_source.status  # Should remain unchanged
  end

  test "should handle language filtering correctly" do
    source = Source.create!(
      name: 'Python Trending',
      source_type: 'github_trending',
      config: '{"since": "daily", "language": "Python"}',
      active: true,
      auto_fetch_enabled: true
    )

    search_response = {"total_count" => 0, "items" => []}.to_json
    
    # Verify language is included in search query
    expected_date = (Date.current - 1.day).strftime('%Y-%m-%d')
    stub_request(:get, "https://api.github.com/search/repositories")
      .with(query: hash_including({'q' => "created:>#{expected_date} stars:>1 language:Python"}))
      .to_return(status: 200, body: search_response)

    perform_enqueued_jobs do
      FetchGithubTrendingJob.perform_now(source.id)
    end

    source.reload
    assert_equal 'ok', source.status
  end

  test "should calculate priority scores for preferred languages" do
    source = Source.create!(
      name: 'Multi-Language Trending',
      source_type: 'github_trending',
      config: '{"since": "daily", "preferred_languages": ["Ruby", "Go"]}',
      active: true,
      auto_fetch_enabled: true
    )

    search_response = {
      "total_count" => 2,
      "items" => [
        {
          "id" => 100200300,
          "full_name" => "ruby/preferred-repo",
          "html_url" => "https://github.com/ruby/preferred-repo",
          "description" => "Ruby repository (preferred)",
          "owner" => {"login" => "ruby"},
          "created_at" => "2025-07-11T12:00:00Z",
          "language" => "Ruby",  # Preferred language
          "stargazers_count" => 50
        },
        {
          "id" => 300200100,
          "full_name" => "python/other-repo",
          "html_url" => "https://github.com/python/other-repo",
          "description" => "Python repository (not preferred)",
          "owner" => {"login" => "python"},
          "created_at" => "2025-07-11T12:00:00Z",
          "language" => "Python",  # Not in preferred list
          "stargazers_count" => 50
        }
      ]
    }.to_json

    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 200, body: search_response)

    assert_difference('Post.count', 2) do
      perform_enqueued_jobs do
        FetchGithubTrendingJob.perform_now(source.id)
      end
    end

    ruby_post = Post.find_by(external_id: '100200300')
    python_post = Post.find_by(external_id: '300200100')

    # Ruby post should have higher priority (preferred language bonus)
    assert ruby_post.priority_score > python_post.priority_score
    # Ruby post should get +5.0 bonus for preferred language
    assert ruby_post.priority_score >= python_post.priority_score + 5.0
  end
end