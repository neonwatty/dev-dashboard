require "test_helper"

class FetchGithubIssuesJobTest < ActiveJob::TestCase
  setup do
    @source = sources(:rails_github)
  end

  test "should fetch and create posts from successful GitHub API response" do
    # Mock successful GitHub API response
    issues_response = [
      {
        "number" => 55001,
        "title" => "Add support for custom validators",
        "html_url" => "https://github.com/rails/rails/issues/55001",
        "user" => {"login" => "developer1"},
        "created_at" => "2025-07-09T12:00:00Z",
        "body" => "It would be great to have support for custom validators in Rails.",
        "labels" => [
          {"name" => "enhancement"},
          {"name" => "good first issue"}
        ],
        "comments" => 5,
        "reactions" => {
          "total_count" => 10,
          "+1" => 8,
          "-1" => 0,
          "laugh" => 1,
          "hooray" => 1,
          "confused" => 0,
          "heart" => 0,
          "rocket" => 0,
          "eyes" => 0
        },
        "pull_request" => nil  # This is an issue, not a PR
      },
      {
        "number" => 55002,
        "title" => "Fix memory leak in Active Record",
        "html_url" => "https://github.com/rails/rails/issues/55002", 
        "user" => {"login" => "developer2"},
        "created_at" => "2025-07-09T11:00:00Z",
        "body" => "Memory leak occurs when using certain AR features.",
        "labels" => [
          {"name" => "bug"},
          {"name" => "activerecord"}
        ],
        "comments" => 3,
        "reactions" => {
          "total_count" => 6,
          "+1" => 6
        },
        "pull_request" => nil
      }
    ].to_json

    # Mock GitHub API call
    stub_request(:get, /api\.github\.com\/repos\/rails\/rails\/issues/)
      .to_return(status: 200, body: issues_response, headers: { 'Content-Type' => 'application/json' })

    # Perform the job
    assert_difference('Post.count', 2) do
      FetchGithubIssuesJob.perform_now(@source.id)
    end

    # Verify source status was updated
    @source.reload
    assert_equal 'ok', @source.status
    assert_not_nil @source.last_fetched_at

    # Verify posts were created correctly
    post1 = Post.find_by(external_id: '55001', source: 'github')
    assert_not_nil post1
    assert_equal "Add support for custom validators", post1.title
    assert_equal "https://github.com/rails/rails/issues/55001", post1.url
    assert_equal "developer1", post1.author
    assert_includes post1.summary, "custom validators"
    assert_equal ["enhancement", "good first issue"], post1.tags_array
    assert_equal 'unread', post1.status
    assert post1.priority_score > 0

    post2 = Post.find_by(external_id: '55002', source: 'github')
    assert_not_nil post2
    assert_equal "Fix memory leak in Active Record", post2.title
    assert_equal ["bug", "activerecord"], post2.tags_array
  end

  test "should filter out pull requests" do
    # Mock API response with both issues and PRs
    response = [
      {
        "number" => 55003,
        "title" => "Regular Issue",
        "html_url" => "https://github.com/rails/rails/issues/55003",
        "user" => {"login" => "user1"},
        "created_at" => "2025-07-09T12:00:00Z",
        "updated_at" => "2025-07-09T12:00:00Z",
        "body" => "This is a regular issue",
        "labels" => [],
        "comments" => 0,
        "reactions" => {"total_count" => 0},
        "pull_request" => nil  # Issue
      },
      {
        "number" => 55004,
        "title" => "Pull Request",
        "html_url" => "https://github.com/rails/rails/pull/55004",
        "user" => {"login" => "user2"},
        "created_at" => "2025-07-09T12:00:00Z",
        "updated_at" => "2025-07-09T12:00:00Z", 
        "body" => "This is a pull request",
        "labels" => [],
        "comments" => 0,
        "reactions" => {"total_count" => 0},
        "pull_request" => {"url" => "https://api.github.com/repos/rails/rails/pulls/55004"}  # PR
      }
    ].to_json

    stub_request(:get, /api\.github\.com\/repos\/rails\/rails\/issues/)
      .to_return(status: 200, body: response)

    # Should only create post for the issue, not the PR
    assert_difference('Post.count', 1) do
      FetchGithubIssuesJob.perform_now(@source.id)
    end

    # Verify only the issue was created
    issue_post = Post.find_by(external_id: '55003', source: 'github')
    assert_not_nil issue_post
    assert_equal "Regular Issue", issue_post.title

    # Verify PR was not created
    pr_post = Post.find_by(external_id: '55004', source: 'github')
    assert_nil pr_post
  end

  test "should handle label filtering" do
    # Configure source with label filtering
    @source.update!(config: '{"labels": ["help wanted", "good first issue"]}')
    
    response = [
      {
        "number" => 55005,
        "title" => "Issue with help wanted label",
        "html_url" => "https://github.com/rails/rails/issues/55005",
        "user" => {"login" => "user1"},
        "created_at" => "2025-07-09T12:00:00Z",
        "updated_at" => "2025-07-09T12:00:00Z",
        "body" => "This has help wanted label",
        "labels" => [{"name" => "help wanted"}],
        "comments" => 0,
        "reactions" => {"total_count" => 0},
        "pull_request" => nil
      }
    ].to_json

    # Expect filtered request with labels parameter
    stub_request(:get, /api\.github\.com\/repos\/rails\/rails\/issues/)
      .with(query: hash_including({'labels' => 'help wanted,good first issue'}))
      .to_return(status: 200, body: response)

    assert_difference('Post.count', 1) do
      FetchGithubIssuesJob.perform_now(@source.id)
    end
  end

  test "should handle GitHub API authentication" do
    # Configure source with token
    @source.update!(config: '{"token": "test_token_123"}')
    
    response = [].to_json  # Empty response

    # Expect request with Authorization header
    stub_request(:get, /api\.github\.com\/repos\/rails\/rails\/issues/)
      .with(headers: {'Authorization' => 'token test_token_123'})
      .to_return(status: 200, body: response)

    FetchGithubIssuesJob.perform_now(@source.id)
    
    @source.reload
    assert_equal 'ok', @source.status
  end

  test "should handle API rate limiting" do
    # Mock rate limit response
    stub_request(:get, /api\.github\.com\/repos\/rails\/rails\/issues/)
      .to_return(status: 403, body: '{"message": "API rate limit exceeded"}')

    assert_no_difference('Post.count') do
      FetchGithubIssuesJob.perform_now(@source.id)
    end

    @source.reload
    assert_includes @source.status, 'error: HTTP 403'
  end

  test "should handle repository not found" do
    # Mock 404 response
    stub_request(:get, /api\.github\.com\/repos\/rails\/rails\/issues/)
      .to_return(status: 404, body: '{"message": "Not Found"}')

    assert_no_difference('Post.count') do
      FetchGithubIssuesJob.perform_now(@source.id)
    end

    @source.reload
    assert_includes @source.status, 'error: HTTP 404'
    assert_includes @source.status, 'Repository not found'
  end

  test "should handle malformed repository URL" do
    # Create source with invalid GitHub URL
    bad_source = Source.create!(
      name: 'Bad GitHub Source',
      source_type: 'github',
      url: 'https://github.com/invalid-url-format',
      active: true,
      config: '{}'
    )

    # Should not make any HTTP requests and not create posts
    assert_no_difference('Post.count') do
      FetchGithubIssuesJob.perform_now(bad_source.id)
    end
  end

  test "should not create duplicate posts" do
    # Create existing post
    existing_post = Post.create!(
      source: 'github',
      external_id: '55006',
      title: 'Existing Issue',
      url: 'https://github.com/rails/rails/issues/55006',
      author: 'existing_user',
      posted_at: Time.current,
      status: 'read'
    )

    # Mock response with same issue number
    response = [
      {
        "number" => 55006,  # Same as existing post
        "title" => "Updated Title",
        "html_url" => "https://github.com/rails/rails/issues/55006",
        "user" => {"login" => "new_user"},
        "created_at" => "2025-07-09T12:00:00Z",
        "updated_at" => "2025-07-09T12:00:00Z",
        "body" => "Updated content",
        "labels" => [],
        "comments" => 0,
        "reactions" => {"total_count" => 0},
        "pull_request" => nil
      }
    ].to_json

    stub_request(:get, /api\.github\.com\/repos\/rails\/rails\/issues/)
      .to_return(status: 200, body: response)

    # Should not create new post
    assert_no_difference('Post.count') do
      FetchGithubIssuesJob.perform_now(@source.id)
    end

    # Original post should remain unchanged
    existing_post.reload
    assert_equal 'Existing Issue', existing_post.title
    assert_equal 'existing_user', existing_post.author
    assert_equal 'read', existing_post.status
  end

  test "should calculate priority score correctly" do
    # Mock response with high and low priority issues
    response = [
      {
        "number" => 55007,
        "title" => "High priority issue with good first issue label",
        "html_url" => "https://github.com/rails/rails/issues/55007",
        "user" => {"login" => "contributor"},
        "created_at" => 1.hour.ago.iso8601,  # Recent
        "body" => "This is important and beginner friendly",
        "labels" => [
          {"name" => "good first issue"},
          {"name" => "help wanted"}
        ],
        "comments" => 15,  # High engagement
        "reactions" => {"total_count" => 25},
        "pull_request" => nil
      },
      {
        "number" => 55008,
        "title" => "Low priority old issue",
        "html_url" => "https://github.com/rails/rails/issues/55008",
        "user" => {"login" => "someone"},
        "created_at" => 1.month.ago.iso8601,  # Old
        "body" => "This is old and not important",
        "labels" => [],
        "comments" => 1,  # Low engagement
        "reactions" => {"total_count" => 2},
        "pull_request" => nil
      }
    ].to_json

    stub_request(:get, /api\.github\.com\/repos\/rails\/rails\/issues/)
      .to_return(status: 200, body: response)

    FetchGithubIssuesJob.perform_now(@source.id)

    high_priority_post = Post.find_by(external_id: '55007')
    low_priority_post = Post.find_by(external_id: '55008')

    # High priority post should have higher score
    assert high_priority_post.priority_score > low_priority_post.priority_score
    
    # High priority should have boost for good first issue
    assert high_priority_post.priority_score > 5.0  # Should get 5.0 boost for helpful labels
  end

  test "should skip non-GitHub sources" do
    discourse_source = sources(:huggingface_forum)
    
    # Should not make any HTTP requests
    assert_no_difference('Post.count') do
      FetchGithubIssuesJob.perform_now(discourse_source.id)
    end
  end

  test "should handle missing optional fields gracefully" do
    # Mock response with minimal required fields
    response = [
      {
        "number" => 55009,
        "title" => "Minimal Issue",
        "html_url" => "https://github.com/rails/rails/issues/55009",
        "user" => {"login" => "minimal_user"},
        "created_at" => "2025-07-09T12:00:00Z",
        "updated_at" => "2025-07-09T12:00:00Z"
        # Missing: body, labels, comments, reactions
      }
    ].to_json

    stub_request(:get, /api\.github\.com\/repos\/rails\/rails\/issues/)
      .to_return(status: 200, body: response)

    assert_difference('Post.count', 1) do
      FetchGithubIssuesJob.perform_now(@source.id)
    end

    post = Post.find_by(external_id: '55009')
    assert_not_nil post
    assert_equal "Minimal Issue", post.title
    assert_equal "minimal_user", post.author
    assert_equal [], post.tags_array
    assert post.priority_score >= 0
  end
end