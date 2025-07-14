require "test_helper"

class GithubWorkflowTest < ActionDispatch::IntegrationTest
  setup do
    @github_source = sources(:rails_github)
    @user = users(:one)
    sign_in_as(@user)
    
    # Clean up existing posts
    Post.where(source: 'github').delete_all
  end

  test "should refresh GitHub source and show recent posts" do
    # Remove label filtering for this test
    @github_source.update!(config: '{}')
    
    # Mock successful GitHub API response
    issues_response = [
      {
        "number" => 12345,
        "title" => "Integration Test Issue",
        "html_url" => "https://github.com/rails/rails/issues/12345",
        "user" => {"login" => "test_contributor"},
        "created_at" => "2025-07-12T10:00:00Z",
        "updated_at" => "2025-07-12T10:00:00Z",
        "body" => "This is a test issue for integration testing",
        "labels" => [
          {"name" => "enhancement"},
          {"name" => "good first issue"}
        ],
        "comments" => 3,
        "reactions" => {"total_count" => 5},
        "pull_request" => nil
      }
    ].to_json

    # Mock GitHub API call - be very specific about the URL pattern
    stub_request(:get, "https://api.github.com/repos/rails/rails/issues")
      .with(query: hash_including({'state' => 'open', 'per_page' => '30', 'page' => '1', 'sort' => 'updated', 'direction' => 'desc'}))
      .to_return(status: 200, body: issues_response, headers: { 'Content-Type' => 'application/json' })

    # Trigger refresh via controller and execute jobs immediately
    perform_enqueued_jobs do
      post refresh_source_path(@github_source)
      assert_response :redirect
    end
    
    # Verify the post was created
    assert_equal 1, Post.where(source: 'github').count

    # Verify the post was created
    post = Post.find_by(external_id: '12345', source: 'github')
    assert_not_nil post
    assert_equal "Integration Test Issue", post.title
    assert_equal "test_contributor", post.author

    # Verify source status was updated
    @github_source.reload
    assert_match /ok/, @github_source.status

    # Visit the source show page and verify recent posts are displayed
    get source_path(@github_source)
    assert_response :success

    # Check that recent posts section shows our test issue
    assert_select 'h2', text: 'Recent Posts from This Source'
    assert_select 'h3 a[href*="github.com/rails/rails/issues/12345"]', text: 'Integration Test Issue'
    assert_select 'p', text: /by test_contributor.*ago/
  end

  test "should handle auto-fetch toggle for GitHub sources" do
    # Disable auto-fetch
    @github_source.update!(auto_fetch_enabled: false)

    # Mock GitHub API call (should not be made)
    stub_request(:get, /api\.github\.com\/repos\/rails\/rails\/issues/)
      .to_return(status: 200, body: '[]')

    # Try to refresh - should be skipped due to auto_fetch_enabled: false
    assert_no_difference('Post.count') do
      post refresh_source_path(@github_source)
      assert_response :redirect
    end

    # Enable auto-fetch
    @github_source.update!(auto_fetch_enabled: true)

    # Mock successful response
    issues_response = [
      {
        "number" => 54321,
        "title" => "Auto-fetch Test Issue",
        "html_url" => "https://github.com/rails/rails/issues/54321",
        "user" => {"login" => "auto_fetch_user"},
        "created_at" => "2025-07-12T11:00:00Z",
        "updated_at" => "2025-07-12T11:00:00Z",
        "body" => "Test issue for auto-fetch functionality",
        "labels" => [],
        "comments" => 0,
        "reactions" => {"total_count" => 0},
        "pull_request" => nil
      }
    ].to_json

    stub_request(:get, /api\.github\.com\/repos\/rails\/rails\/issues/)
      .to_return(status: 200, body: issues_response)

    # Now refresh should work
    assert_difference('Post.count', 1) do
      post refresh_source_path(@github_source)
      assert_response :redirect
    end

    # Verify the post was created
    post = Post.find_by(external_id: '54321', source: 'github')
    assert_not_nil post
    assert_equal "Auto-fetch Test Issue", post.title
  end

  test "should show GitHub configuration options in source form" do
    get edit_source_path(@github_source)
    assert_response :success

    # Check that GitHub-specific fields are present
    assert_select 'label[for="github_token"]', text: 'Personal Access Token'
    assert_select 'input[name="github_token"]'
    
    assert_select 'label[for="github_labels"]', text: 'Filter by Labels (comma-separated)'
    assert_select 'input[name="github_labels"]'
    
    # Check that auto-fetch toggle is present
    assert_select 'label[for="source_auto_fetch_enabled"]', text: 'Auto-fetch latest posts'
    assert_select 'input[name="source[auto_fetch_enabled]"]'
  end

  test "should handle GitHub API errors gracefully" do
    # Mock rate limit error
    stub_request(:get, /api\.github\.com\/repos\/rails\/rails\/issues/)
      .to_return(status: 403, body: '{"message": "API rate limit exceeded"}')

    assert_no_difference('Post.count') do
      post refresh_source_path(@github_source)
      assert_response :redirect
    end

    @github_source.reload
    assert_match /error/, @github_source.status
    assert_includes @github_source.status, 'HTTP 403'

    # Visit source show page and verify error is displayed
    get source_path(@github_source)
    assert_response :success
    # The status badge should show the error state
  end

  test "should filter GitHub issues by configured labels" do
    # Configure source with specific labels
    @github_source.update!(config: '{"labels": ["help wanted", "good first issue"]}')

    # Mock response that should match the label filter
    issues_response = [
      {
        "number" => 98765,
        "title" => "Filtered Issue",
        "html_url" => "https://github.com/rails/rails/issues/98765",
        "user" => {"login" => "filtered_user"},
        "created_at" => "2025-07-12T12:00:00Z",
        "updated_at" => "2025-07-12T12:00:00Z",
        "body" => "This issue has the help wanted label",
        "labels" => [{"name" => "help wanted"}],
        "comments" => 0,
        "reactions" => {"total_count" => 0},
        "pull_request" => nil
      }
    ].to_json

    # Expect request with labels parameter
    stub_request(:get, /api\.github\.com\/repos\/rails\/rails\/issues/)
      .with(query: hash_including({'labels' => 'help wanted,good first issue'}))
      .to_return(status: 200, body: issues_response)

    assert_difference('Post.count', 1) do
      post refresh_source_path(@github_source)
      assert_response :redirect
    end

    # Verify the filtered post was created
    post = Post.find_by(external_id: '98765', source: 'github')
    assert_not_nil post
    assert_equal "Filtered Issue", post.title
    assert_includes post.tags_array, 'help wanted'
  end
end