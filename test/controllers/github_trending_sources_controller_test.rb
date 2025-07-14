require "test_helper"

class GithubTrendingSourcesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
    @github_trending_source = sources(:github_trending)
  end

  test "should test GitHub Trending connection successfully" do
    # Mock successful GitHub API response
    search_response = {
      "total_count" => 2,
      "items" => [
        {
          "id" => 123456789,
          "full_name" => "test/awesome-repo",
          "html_url" => "https://github.com/test/awesome-repo",
          "description" => "An awesome repository",
          "owner" => {"login" => "test"},
          "created_at" => "2025-07-11T12:00:00Z",
          "stargazers_count" => 100,
          "forks_count" => 20
        },
        {
          "id" => 987654321,
          "full_name" => "another/cool-project",
          "html_url" => "https://github.com/another/cool-project",
          "description" => "A cool project",
          "owner" => {"login" => "another"},
          "created_at" => "2025-07-11T10:00:00Z",
          "stargazers_count" => 50,
          "forks_count" => 10
        }
      ]
    }.to_json

    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 200, body: search_response, headers: { 'Content-Type' => 'application/json' })

    post test_connection_source_path(@github_trending_source)
    
    follow_redirect!
    assert_response :success
    assert_match /GitHub Trending API connection successful.*Found 2 trending repositories/, flash[:notice]
    
    @github_trending_source.reload
    assert_equal 'ok', @github_trending_source.status
  end

  test "should handle GitHub Trending connection rate limit error" do
    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 403, body: '{"message": "API rate limit exceeded"}')

    post test_connection_source_path(@github_trending_source)
    
    assert_redirected_to source_path(@github_trending_source)
    follow_redirect!
    assert_response :success
    assert_not_nil flash[:alert]
    assert_match /Rate limit exceeded.*GitHub token/, flash[:alert]
    
    @github_trending_source.reload
    assert_includes @github_trending_source.status, 'error'
  end

  test "should handle GitHub Trending connection authentication error" do
    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 401, body: '{"message": "Bad credentials"}')

    post test_connection_source_path(@github_trending_source)
    
    follow_redirect!
    assert_response :success
    assert_match /Authentication failed.*GitHub token/, flash[:alert]
    
    @github_trending_source.reload
    assert_includes @github_trending_source.status, 'error'
  end

  test "should handle GitHub Trending connection invalid parameters error" do
    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 422, body: '{"message": "Validation Failed"}')

    post test_connection_source_path(@github_trending_source)
    
    follow_redirect!
    assert_response :success
    assert_match /Invalid search parameters.*configuration/, flash[:alert]
    
    @github_trending_source.reload
    assert_includes @github_trending_source.status, 'error'
  end

  test "should refresh GitHub Trending source successfully" do
    search_response = {
      "total_count" => 1,
      "items" => [
        {
          "id" => 555666777,
          "full_name" => "trending/refresh-test",
          "html_url" => "https://github.com/trending/refresh-test",
          "description" => "Test refresh functionality",
          "owner" => {"login" => "trending"},
          "created_at" => "2025-07-11T12:00:00Z",
          "stargazers_count" => 75,
          "forks_count" => 15
        }
      ]
    }.to_json

    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 200, body: search_response)

    # Test refresh action
    perform_enqueued_jobs do
      post refresh_source_path(@github_trending_source)
    end
    
    follow_redirect!
    assert_response :success
    assert_match /GitHub Trending refresh job queued/, flash[:notice]
    
    @github_trending_source.reload
    assert_match /ok/, @github_trending_source.status
    assert_not_nil @github_trending_source.last_fetched_at
    
    # Verify post was created
    new_post = Post.find_by(external_id: '555666777', source: @github_trending_source.name)
    assert_not_nil new_post
    assert_equal 'trending/refresh-test - Test refresh functionality', new_post.title
  end

  test "should handle GitHub Trending refresh with API error" do
    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 403, body: '{"message": "API rate limit exceeded"}')

    perform_enqueued_jobs do
      post refresh_source_path(@github_trending_source)
    end
    
    follow_redirect!
    assert_response :success
    assert_match /GitHub Trending refresh job queued/, flash[:notice]
    
    @github_trending_source.reload
    assert_includes @github_trending_source.status, 'error'
  end

  test "should not affect URL-based source connection tests" do
    # Test that regular GitHub sources still work normally
    github_source = sources(:rails_github)
    
    # Mock successful connection to the URL
    stub_request(:get, "https://github.com/rails/rails")
      .to_return(status: 200, body: "GitHub page content")

    post test_connection_source_path(github_source)
    
    follow_redirect!
    assert_response :success
    assert_match /Connection test successful/, flash[:notice]
    
    github_source.reload
    assert_equal 'ok', github_source.status
  end

  test "should broadcast status updates during GitHub Trending connection test" do
    search_response = {"total_count" => 0, "items" => []}.to_json

    stub_request(:get, /api\.github\.com\/search\/repositories/)
      .to_return(status: 200, body: search_response)

    assert_broadcasts("source_status:#{@github_trending_source.id}", 1) do
      assert_broadcasts("source_status:all", 1) do
        post test_connection_source_path(@github_trending_source)
      end
    end
  end
end