require "test_helper"

class FetchPytorchJobTest < ActiveJob::TestCase
  setup do
    @source = sources(:pytorch_forum)
  end

  test "should fetch and create posts from successful API response" do
    # Mock successful PyTorch forum API response
    response_body = {
      "topic_list" => {
        "topics" => [
          {
            "id" => 889001,
            "title" => "Understanding PyTorch tensors",
            "slug" => "understanding-pytorch-tensors",
            "created_at" => "2025-07-09T12:00:00.000Z",
            "last_poster_username" => "pytorch_expert",
            "excerpt" => "A deep dive into PyTorch tensor operations",
            "tags" => ["tensors", "tutorial"],
            "reply_count" => 8,
            "like_count" => 15,
            "views" => 250
          },
          {
            "id" => 889002,
            "title" => "CUDA memory optimization tips",
            "slug" => "cuda-memory-optimization-tips",
            "created_at" => "2025-07-09T11:00:00.000Z",
            "last_poster_username" => "gpu_researcher",
            "excerpt" => "How to optimize GPU memory usage in PyTorch",
            "tags" => ["cuda", "optimization"],
            "reply_count" => 12,
            "like_count" => 20,
            "views" => 400
          }
        ]
      }
    }.to_json

    stub_request(:get, "#{@source.url}/latest.json")
      .to_return(status: 200, body: response_body, headers: { 'Content-Type' => 'application/json' })

    # Perform the job
    assert_difference('Post.count', 2) do
      FetchPytorchJob.perform_now(@source.id)
    end

    # Verify source status was updated
    @source.reload
    assert_equal 'ok', @source.status
    assert_not_nil @source.last_fetched_at

    # Verify posts were created correctly
    post1 = Post.find_by(external_id: '889001', source: 'pytorch')
    assert_not_nil post1
    assert_equal "Understanding PyTorch tensors", post1.title
    assert_equal "#{@source.url}/t/understanding-pytorch-tensors/889001", post1.url
    assert_equal "pytorch_expert", post1.author
    assert_equal "A deep dive into PyTorch tensor operations", post1.summary
    assert_equal ["tensors", "tutorial"], post1.tags_array
    assert_equal 'unread', post1.status
    assert post1.priority_score > 0

    post2 = Post.find_by(external_id: '889002', source: 'pytorch')
    assert_not_nil post2
    assert_equal "CUDA memory optimization tips", post2.title
    assert_equal ["cuda", "optimization"], post2.tags_array
  end

  test "should not create duplicate posts" do
    # Create an existing post
    existing_post = Post.create!(
      source: 'pytorch',
      external_id: '889003',
      title: 'Existing PyTorch Post',
      url: 'https://example.com',
      author: 'test_author',
      posted_at: Time.current,
      status: 'unread'
    )

    # Mock API response with same external_id
    response_body = {
      "topic_list" => {
        "topics" => [
          {
            "id" => 889003,  # Same ID as existing post
            "title" => "Different Title",
            "slug" => "different-slug",
            "created_at" => "2025-07-09T12:00:00.000Z",
            "last_poster_username" => "different_author",
            "excerpt" => "Different content",
            "tags" => ["different"],
            "reply_count" => 1,
            "like_count" => 1,
            "views" => 10
          }
        ]
      }
    }.to_json

    stub_request(:get, "#{@source.url}/latest.json")
      .to_return(status: 200, body: response_body)

    # Should not create new post
    assert_no_difference('Post.count') do
      FetchPytorchJob.perform_now(@source.id)
    end

    # Original post should remain unchanged
    existing_post.reload
    assert_equal 'Existing PyTorch Post', existing_post.title
    assert_equal 'test_author', existing_post.author
  end

  test "should handle API errors gracefully" do
    # Mock failed API response
    stub_request(:get, "#{@source.url}/latest.json")
      .to_return(status: 500, body: 'Internal Server Error')

    # Should not create any posts
    assert_no_difference('Post.count') do
      FetchPytorchJob.perform_now(@source.id)
    end

    # Source status should reflect error
    @source.reload
    assert_includes @source.status, 'error: HTTP 500'
  end

  test "should handle network timeouts" do
    # Mock timeout
    stub_request(:get, "#{@source.url}/latest.json")
      .to_timeout

    assert_no_difference('Post.count') do
      FetchPytorchJob.perform_now(@source.id)
    end

    @source.reload
    assert_includes @source.status, 'error:'
  end

  test "should handle invalid JSON response" do
    # Mock invalid JSON response
    stub_request(:get, "#{@source.url}/latest.json")
      .to_return(status: 200, body: 'invalid json response')

    assert_no_difference('Post.count') do
      FetchPytorchJob.perform_now(@source.id)
    end

    @source.reload
    assert_includes @source.status, 'error:'
  end

  test "should skip non-PyTorch sources" do
    github_source = sources(:rails_github)
    
    # Should not make any HTTP requests
    assert_no_difference('Post.count') do
      FetchPytorchJob.perform_now(github_source.id)
    end
  end

  test "should process all active discourse sources when no source_id provided" do
    # Create another PyTorch source  
    pytorch_source2 = Source.create!(
      name: 'PyTorch Community',
      source_type: 'discourse',
      url: 'https://community.pytorch.org',  # Different URL
      active: true,
      config: '{}'
    )

    # Mock responses for both sources
    response_body = {
      "topic_list" => {
        "topics" => [{
          "id" => 889005,
          "title" => "Test PyTorch Topic 1",
          "slug" => "test-pytorch-topic",
          "created_at" => "2025-07-09T12:00:00.000Z",
          "last_poster_username" => "tester",
          "excerpt" => "Test excerpt",
          "tags" => [],
          "reply_count" => 0,
          "like_count" => 0,
          "views" => 1
        }]
      }
    }.to_json

    response_body2 = {
      "topic_list" => {
        "topics" => [{
          "id" => 889008,
          "title" => "Test PyTorch Topic 2",
          "slug" => "test-pytorch-topic-2",
          "created_at" => "2025-07-09T12:00:00.000Z",
          "last_poster_username" => "tester2",
          "excerpt" => "Test excerpt 2",
          "tags" => [],
          "reply_count" => 0,
          "like_count" => 0,
          "views" => 1
        }]
      }
    }.to_json

    stub_request(:get, "#{@source.url}/latest.json")
      .to_return(status: 200, body: response_body)
    
    stub_request(:get, "#{pytorch_source2.url}/latest.json")
      .to_return(status: 200, body: response_body2)

    # Should process both PyTorch sources
    assert_difference('Post.count', 2) do
      FetchPytorchJob.perform_now
    end
  end

  test "should calculate priority score correctly" do
    # Mock response with varying engagement metrics
    response_body = {
      "topic_list" => {
        "topics" => [
          {
            "id" => 889006,
            "title" => "High Priority PyTorch Question",
            "slug" => "high-priority-question",
            "created_at" => 1.hour.ago.iso8601,  # Recent
            "last_poster_username" => "expert",
            "excerpt" => "Urgent PyTorch question",
            "tags" => [],
            "reply_count" => 25,  # High engagement
            "like_count" => 40,   # High likes
            "views" => 800        # High views
          },
          {
            "id" => 889007,
            "title" => "Unanswered PyTorch Question",
            "slug" => "unanswered-question",
            "created_at" => 2.hours.ago.iso8601,  # Recent but unanswered
            "last_poster_username" => "newbie",
            "excerpt" => "Need help with PyTorch",
            "tags" => [],
            "reply_count" => 0,   # Unanswered - should get boost
            "like_count" => 2,
            "views" => 50
          },
          {
            "id" => 889008,
            "title" => "Old Low Priority Topic",
            "slug" => "old-low-priority",
            "created_at" => 1.week.ago.iso8601,  # Old
            "last_poster_username" => "user",
            "excerpt" => "Old topic",
            "tags" => [],
            "reply_count" => 1,   # Low engagement
            "like_count" => 0,    # No likes
            "views" => 5          # Low views
          }
        ]
      }
    }.to_json

    stub_request(:get, "#{@source.url}/latest.json")
      .to_return(status: 200, body: response_body)

    FetchPytorchJob.perform_now(@source.id)

    high_priority_post = Post.find_by(external_id: '889006')
    unanswered_post = Post.find_by(external_id: '889007')
    low_priority_post = Post.find_by(external_id: '889008')

    # High priority post should have highest score
    assert high_priority_post.priority_score > unanswered_post.priority_score
    assert unanswered_post.priority_score > low_priority_post.priority_score
    
    # Unanswered post should get 2.0 boost
    assert unanswered_post.priority_score > 2.0
  end

  test "should handle missing optional fields gracefully" do
    # Mock response with minimal required fields
    response_body = {
      "topic_list" => {
        "topics" => [{
          "id" => 889004,
          "title" => "Minimal PyTorch Topic",
          "created_at" => "2025-07-09T12:00:00.000Z"
          # Missing: slug, excerpt, tags, username, metrics
        }]
      }
    }.to_json

    stub_request(:get, "#{@source.url}/latest.json")
      .to_return(status: 200, body: response_body)

    assert_difference('Post.count', 1) do
      FetchPytorchJob.perform_now(@source.id)
    end

    post = Post.find_by(external_id: '889004')
    assert_not_nil post
    assert_equal "Minimal PyTorch Topic", post.title
    assert_equal "#{@source.url}/t/topic-889004/889004", post.url  # Fallback slug
    assert_equal "unknown", post.author  # Default value
    assert_equal [], post.tags_array     # Empty array
    assert post.priority_score >= 2.0   # Should get unanswered boost
  end
end