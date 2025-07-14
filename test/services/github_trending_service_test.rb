require "test_helper"
require_relative "../../app/services/github_trending_service"

class GitHubTrendingServiceTest < ActiveSupport::TestCase
  setup do
    @source = sources(:github_trending)
    @service = GitHubTrendingService.new(@source)
  end

  test "should initialize with source" do
    assert_equal @source, @service.source
  end

  test "should fetch trending repositories with default options" do
    # Mock GitHub search API response
    search_response = {
      "total_count" => 1,
      "incomplete_results" => false,
      "items" => [
        {
          "id" => 123456789,
          "full_name" => "test-org/awesome-repo",
          "html_url" => "https://github.com/test-org/awesome-repo",
          "description" => "An awesome repository",
          "owner" => {"login" => "test-org"},
          "created_at" => "2025-07-11T12:00:00Z",
          "stargazers_count" => 100,
          "forks_count" => 20,
          "watchers_count" => 100,
          "language" => "Ruby",
          "topics" => ["ruby", "web"]
        }
      ]
    }.to_json

    # Default should be daily search
    expected_date = (Date.current - 1.day).strftime('%Y-%m-%d')
    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .with(query: hash_including({
        'q' => "created:>#{expected_date} stars:>1 language:Ruby",
        'sort' => 'stars',
        'order' => 'desc',
        'per_page' => '30'
      }))
      .to_return(status: 200, body: search_response, headers: { 'Content-Type' => 'application/json' })

    repositories = @service.fetch_trending_repositories
    
    assert_equal 1, repositories.length
    repo = repositories.first
    assert_equal 123456789, repo['id']
    assert_equal "test-org/awesome-repo", repo['full_name']
    assert_equal "Ruby", repo['language']
  end

  test "should fetch trending repositories with custom time period" do
    search_response = {"total_count" => 0, "items" => []}.to_json
    
    # Test weekly search
    expected_date = (Date.current - 7.days).strftime('%Y-%m-%d')
    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .with(query: hash_including({'q' => "created:>#{expected_date} stars:>1 language:Ruby"}))
      .to_return(status: 200, body: search_response)

    repositories = @service.fetch_trending_repositories(since: 'weekly')
    assert_equal 0, repositories.length
  end

  test "should fetch trending repositories with custom language" do
    search_response = {"total_count" => 0, "items" => []}.to_json
    
    expected_date = (Date.current - 1.day).strftime('%Y-%m-%d')
    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .with(query: hash_including({'q' => "created:>#{expected_date} stars:>1 language:Python"}))
      .to_return(status: 200, body: search_response)

    repositories = @service.fetch_trending_repositories(language: 'Python')
    assert_equal 0, repositories.length
  end

  test "should include authentication header when token provided" do
    @source.update!(config: '{"token": "github_token_123"}')
    @service = GitHubTrendingService.new(@source)
    
    search_response = {"total_count" => 0, "items" => []}.to_json
    
    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .with(headers: {
        'Authorization' => 'token github_token_123',
        'Accept' => 'application/vnd.github.v3+json',
        'User-Agent' => 'DevDashboard/1.0'
      })
      .to_return(status: 200, body: search_response)

    repositories = @service.fetch_trending_repositories
    assert_equal 0, repositories.length
  end

  test "should handle API rate limiting error" do
    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 403, body: '{"message": "API rate limit exceeded"}')

    assert_raises(RuntimeError) do
      result = @service.fetch_trending_repositories
    end
  end

  test "should handle invalid search query error" do
    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 422, body: '{"message": "Validation Failed"}')

    assert_raises(RuntimeError) do
      result = @service.fetch_trending_repositories
    end
  end

  test "should handle generic API errors" do
    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 500, body: '{"message": "Internal Server Error"}')

    assert_raises(RuntimeError) do
      result = @service.fetch_trending_repositories
    end
  end

  test "should create post from repository data" do
    repo_data = {
      'id' => 987654321,
      'full_name' => 'awesome/project',
      'html_url' => 'https://github.com/awesome/project',
      'description' => 'An awesome open source project',
      'owner' => {'login' => 'awesome'},
      'created_at' => '2025-07-11T10:00:00Z',
      'stargazers_count' => 200,
      'forks_count' => 40,
      'watchers_count' => 200,
      'language' => 'JavaScript',
      'topics' => ['javascript', 'frontend', 'beginner-friendly'],
      'license' => {'key' => 'mit'}
    }

    assert_difference('Post.count', 1) do
      result = @service.create_post_from_repository(repo_data)
      assert result, "Should return true for successful creation"
    end

    post = Post.find_by(external_id: '987654321', source: @source.name)
    assert_not_nil post
    assert_equal 'awesome/project - An awesome open source project', post.title
    assert_equal 'https://github.com/awesome/project', post.url
    assert_equal 'awesome', post.author
    assert_equal Time.parse('2025-07-11T10:00:00Z'), post.posted_at
    assert_equal 'unread', post.status
    
    # Check summary includes key metrics
    assert_includes post.summary, '⭐ 200 stars'
    assert_includes post.summary, '🍴 40 forks'
    assert_includes post.summary, '📝 JavaScript'
    
    # Check tags include expected values
    tags = post.tags_array
    assert_includes tags, 'javascript'
    assert_includes tags, 'frontend'
    assert_includes tags, 'beginner-friendly'
    assert_includes tags, 'trending'
    assert_includes tags, 'new-repo'  # Created recently
    assert_includes tags, 'popular'   # > 100 stars
    assert_includes tags, 'license:mit'
    
    assert post.priority_score > 0
  end

  test "should not create duplicate posts" do
    # Create existing post
    existing_post = Post.create!(
      source: @source.name,
      external_id: '111222333',
      title: 'Existing Repo',
      url: 'https://github.com/existing/repo',
      author: 'existing_user',
      posted_at: Time.current,
      status: 'read'
    )

    repo_data = {
      'id' => 111222333,  # Same ID as existing post
      'full_name' => 'existing/updated-repo',
      'html_url' => 'https://github.com/existing/updated-repo',
      'description' => 'Updated description',
      'owner' => {'login' => 'new_owner'},
      'created_at' => '2025-07-11T12:00:00Z'
    }

    assert_no_difference('Post.count') do
      result = @service.create_post_from_repository(repo_data)
      assert_not result, "Should return false for duplicate"
    end

    # Original post should remain unchanged
    existing_post.reload
    assert_equal 'Existing Repo', existing_post.title
    assert_equal 'existing_user', existing_post.author
    assert_equal 'read', existing_post.status
  end

  test "should handle missing optional fields in repository data" do
    minimal_repo = {
      'id' => 555666777,
      'full_name' => 'minimal/repo',
      'html_url' => 'https://github.com/minimal/repo',
      'owner' => {'login' => 'minimal'},
      'created_at' => '2025-07-11T12:00:00Z'
      # Missing: description, stargazers_count, forks_count, etc.
    }

    assert_difference('Post.count', 1) do
      result = @service.create_post_from_repository(minimal_repo)
      assert result
    end

    post = Post.find_by(external_id: '555666777')
    assert_not_nil post
    assert_equal 'minimal/repo - ', post.title  # Empty description
    assert_equal 'minimal', post.author
    
    # Should handle nil values gracefully
    assert post.priority_score >= 0
    assert_includes post.tags_array, 'trending'
  end

  test "should calculate priority score correctly" do
    # High priority repository
    high_priority_repo = {
      'id' => 999888777,
      'full_name' => 'hot/trending-repo',
      'html_url' => 'https://github.com/hot/trending-repo',
      'description' => 'This is a really detailed description that shows the project is well documented',
      'owner' => {'login' => 'hot'},
      'created_at' => 2.hours.ago.iso8601,  # Very recent
      'stargazers_count' => 500,
      'forks_count' => 100,
      'watchers_count' => 500,
      'language' => 'Ruby',  # Preferred language in fixture
      'topics' => ['beginner-friendly', 'good-first-issues', 'hacktoberfest'],
      'license' => {'key' => 'mit'}
    }

    @service.create_post_from_repository(high_priority_repo)
    high_priority_post = Post.find_by(external_id: '999888777')

    # Should get points for:
    # - Stars: 500 * 0.1 = 50
    # - Forks: 100 * 0.2 = 20  
    # - Watchers: 500 * 0.1 = 50
    # - Recent creation: ~8-10 points (within 7 days)
    # - Good description: 3 points
    # - Preferred language: 5 points
    # - Helpful topics: 6 points (3 topics * 2 each)
    expected_min_score = 50 + 20 + 50 + 3 + 5 + 6  # = 134 minimum
    assert high_priority_post.priority_score >= expected_min_score

    # Low priority repository
    low_priority_repo = {
      'id' => 111000111,
      'full_name' => 'old/simple-repo',
      'html_url' => 'https://github.com/old/simple-repo',
      'description' => 'Simple',  # Short description
      'owner' => {'login' => 'old'},
      'created_at' => 15.days.ago.iso8601,  # Old
      'stargazers_count' => 2,
      'forks_count' => 0,
      'watchers_count' => 2,
      'language' => 'C++',  # Not preferred
      'topics' => [],
      'license' => nil
    }

    @service.create_post_from_repository(low_priority_repo)
    low_priority_post = Post.find_by(external_id: '111000111')

    # Should have much lower score
    assert high_priority_post.priority_score > low_priority_post.priority_score
    assert low_priority_post.priority_score < 10  # Minimal score
  end

  test "should extract language from config" do
    @source.update!(config: '{"language": "Python"}')
    @service = GitHubTrendingService.new(@source)
    
    # Use reflection to test private method
    language = @service.send(:extract_language_from_config)
    assert_equal "Python", language
  end

  test "should extract first preferred language when no specific language set" do
    @source.update!(config: '{"preferred_languages": ["Go", "Rust", "Python"]}')
    @service = GitHubTrendingService.new(@source)
    
    language = @service.send(:extract_language_from_config)
    assert_equal "Go", language
  end

  test "should build repository summary correctly" do
    repo = {
      'description' => 'A great project',
      'stargazers_count' => 150,
      'forks_count' => 30,
      'language' => 'Ruby'
    }
    
    summary = @service.send(:build_repository_summary, repo)
    
    assert_includes summary, 'A great project'
    assert_includes summary, '⭐ 150 stars'
    assert_includes summary, '🍴 30 forks'
    assert_includes summary, '📝 Ruby'
    
    # Should be pipe-separated
    expected_parts = ['A great project', '⭐ 150 stars', '🍴 30 forks', '📝 Ruby']
    assert_equal expected_parts.join(' | '), summary
  end

  test "should extract repository tags correctly" do
    repo = {
      'language' => 'JavaScript',
      'topics' => ['frontend', 'react', 'web'],
      'created_at' => 3.days.ago.iso8601,  # Within 7 days = new-repo
      'stargazers_count' => 150,  # > 100 = popular
      'license' => {'key' => 'apache-2.0'}
    }
    
    tags_json = @service.send(:extract_repository_tags, repo)
    tags = JSON.parse(tags_json)
    
    assert_includes tags, 'JavaScript'  # Language
    assert_includes tags, 'frontend'    # Topics
    assert_includes tags, 'react'
    assert_includes tags, 'web'
    assert_includes tags, 'trending'    # Always added
    assert_includes tags, 'new-repo'    # Created < 7 days ago
    assert_includes tags, 'popular'     # > 100 stars
    assert_includes tags, 'license:apache-2.0'  # License
  end

  test "should handle repositories without optional fields in summary and tags" do
    minimal_repo = {
      'full_name' => 'minimal/repo',
      'stargazers_count' => 0,
      'forks_count' => 0
      # Missing: description, language, topics, license
    }
    
    summary = @service.send(:build_repository_summary, minimal_repo)
    # Should not include zero counts or missing fields
    assert_equal '', summary
    
    tags_json = @service.send(:extract_repository_tags, minimal_repo)
    tags = JSON.parse(tags_json)
    
    # Should still include basic tags
    assert_includes tags, 'trending'
    assert_not_includes tags, 'popular'  # 0 stars
    assert_not_includes tags, 'new-repo'  # No created_at
  end

  test "should handle network errors gracefully" do
    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_raise(Timeout::Error.new("Request timeout"))

    assert_raises(Timeout::Error) do
      @service.fetch_trending_repositories
    end
  end

  test "should use correct User-Agent header" do
    search_response = {"total_count" => 0, "items" => []}.to_json
    
    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .with(headers: {'User-Agent' => 'DevDashboard/1.0'})
      .to_return(status: 200, body: search_response)

    @service.fetch_trending_repositories
    
    # WebMock will verify the header was included
  end
end