require "test_helper"

class FetchHuggingFaceJobTest < ActiveJob::TestCase
  setup do
    @source = sources(:huggingface_forum)
  end

  test "should fetch and create posts from successful API response" do
    # Mock successful HuggingFace API response
    response_body = {
      "topic_list" => {
        "topics" => [
          {
            "id" => 999001,
            "title" => "How to fine-tune BERT",
            "slug" => "how-to-fine-tune-bert",
            "created_at" => "2025-07-09T12:00:00.000Z",
            "last_poster_username" => "ml_expert",
            "excerpt" => "A comprehensive guide to fine-tuning BERT models",
            "tags" => ["bert", "fine-tuning"],
            "reply_count" => 5,
            "like_count" => 10,
            "views" => 100
          },
          {
            "id" => 999002,
            "title" => "Transformer architecture explained",
            "slug" => "transformer-architecture-explained",
            "created_at" => "2025-07-09T11:00:00.000Z",
            "last_poster_username" => "researcher",
            "excerpt" => "Deep dive into transformer architecture",
            "tags" => ["transformers", "architecture"],
            "reply_count" => 3,
            "like_count" => 8,
            "views" => 75
          }
        ]
      }
    }.to_json

    stub_request(:get, "#{@source.url}/latest.json?page=0")
      .to_return(status: 200, body: response_body, headers: { 'Content-Type' => 'application/json' })

    # Perform the job
    assert_difference('Post.count', 2) do
      FetchHuggingFaceJob.perform_now(@source.id)
    end

    # Verify source status was updated
    @source.reload
    assert_equal 'ok (2 new)', @source.status
    assert_not_nil @source.last_fetched_at

    # Verify posts were created correctly
    post1 = Post.find_by(external_id: '999001', source: @source.name)
    assert_not_nil post1
    assert_equal "How to fine-tune BERT", post1.title
    assert_equal "#{@source.url}/t/how-to-fine-tune-bert/999001", post1.url
    assert_equal "ml_expert", post1.author
    assert_equal "A comprehensive guide to fine-tuning BERT models", post1.summary
    assert_equal ["bert", "fine-tuning"], post1.tags_array
    assert_equal 'unread', post1.status
    assert post1.priority_score > 0

    post2 = Post.find_by(external_id: '999002', source: @source.name)
    assert_not_nil post2
    assert_equal "Transformer architecture explained", post2.title
  end

  test "should not create duplicate posts" do
    # Create an existing post
    existing_post = Post.create!(
      source: @source.name,
      external_id: '999003',
      title: 'Existing Post',
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
            "id" => 999003,  # Same ID as existing post
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

    stub_request(:get, "#{@source.url}/latest.json?page=0")
      .to_return(status: 200, body: response_body)

    # Should not create new post
    assert_no_difference('Post.count') do
      FetchHuggingFaceJob.perform_now(@source.id)
    end

    # Original post should remain unchanged
    existing_post.reload
    assert_equal 'Existing Post', existing_post.title
    assert_equal 'test_author', existing_post.author
  end

  test "should handle API errors gracefully" do
    # Mock failed API response
    stub_request(:get, "#{@source.url}/latest.json?page=0")
      .to_return(status: 500, body: 'Internal Server Error')

    # Should not create any posts
    assert_no_difference('Post.count') do
      FetchHuggingFaceJob.perform_now(@source.id)
    end

    # Source status should reflect error
    @source.reload
    assert_includes @source.status, 'error: HTTP Error: 500'
  end

  test "should handle network timeouts" do
    # Mock timeout
    stub_request(:get, "#{@source.url}/latest.json?page=0")
      .to_timeout

    assert_no_difference('Post.count') do
      FetchHuggingFaceJob.perform_now(@source.id)
    end

    @source.reload
    assert_includes @source.status, 'error:'
  end

  test "should handle invalid JSON response" do
    # Mock invalid JSON response
    stub_request(:get, "#{@source.url}/latest.json?page=0")
      .to_return(status: 200, body: 'invalid json response')

    assert_no_difference('Post.count') do
      FetchHuggingFaceJob.perform_now(@source.id)
    end

    @source.reload
    assert_includes @source.status, 'error:'
  end

  test "should skip non-HuggingFace sources" do
    github_source = sources(:rails_github)
    
    # Should not make any HTTP requests
    assert_no_difference('Post.count') do
      FetchHuggingFaceJob.perform_now(github_source.id)
    end
  end

  test "should process all active discourse sources when no source_id provided" do
    # Create another HuggingFace source  
    hf_source2 = Source.create!(
      name: 'HF Community',
      source_type: 'discourse',
      url: 'https://community.huggingface.co',  # Different URL
      active: true,
      config: '{}'
    )

    # Mock responses for both sources
    response_body = {
      "topic_list" => {
        "topics" => [{
          "id" => 999005,
          "title" => "Test Topic 1",
          "slug" => "test-topic",
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
          "id" => 999008,
          "title" => "Test Topic 2",
          "slug" => "test-topic-2",
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

    stub_request(:get, "#{@source.url}/latest.json?page=0")
      .to_return(status: 200, body: response_body)
    
    stub_request(:get, "#{hf_source2.url}/latest.json?page=0")
      .to_return(status: 200, body: response_body2)

    # Should process both HuggingFace sources
    assert_difference('Post.count', 2) do
      FetchHuggingFaceJob.perform_now
    end
  end

  test "should calculate priority score correctly" do
    # Mock response with varying engagement metrics
    response_body = {
      "topic_list" => {
        "topics" => [
          {
            "id" => 999006,
            "title" => "High Priority Topic",
            "slug" => "high-priority",
            "created_at" => 1.hour.ago.iso8601,  # Recent
            "last_poster_username" => "expert",
            "excerpt" => "Important topic",
            "tags" => [],
            "reply_count" => 20,  # High engagement
            "like_count" => 50,   # High likes
            "views" => 1000       # High views
          },
          {
            "id" => 999007,
            "title" => "Low Priority Topic",
            "slug" => "low-priority",
            "created_at" => 1.week.ago.iso8601,  # Old
            "last_poster_username" => "user",
            "excerpt" => "Old topic",
            "tags" => [],
            "reply_count" => 0,   # No engagement
            "like_count" => 0,    # No likes
            "views" => 5          # Low views
          }
        ]
      }
    }.to_json

    stub_request(:get, "#{@source.url}/latest.json?page=0")
      .to_return(status: 200, body: response_body)

    FetchHuggingFaceJob.perform_now(@source.id)

    high_priority_post = Post.find_by(external_id: '999006')
    low_priority_post = Post.find_by(external_id: '999007')

    # High priority post should have higher score
    assert high_priority_post.priority_score > low_priority_post.priority_score
  end

  test "should handle missing optional fields gracefully" do
    # Mock response with minimal required fields
    response_body = {
      "topic_list" => {
        "topics" => [{
          "id" => 999004,
          "title" => "Minimal Topic",
          "slug" => "minimal-topic",
          "created_at" => "2025-07-09T12:00:00.000Z"
          # Missing: excerpt, tags, username, metrics
        }]
      }
    }.to_json

    stub_request(:get, "#{@source.url}/latest.json?page=0")
      .to_return(status: 200, body: response_body)

    assert_difference('Post.count', 1) do
      FetchHuggingFaceJob.perform_now(@source.id)
    end

    post = Post.find_by(external_id: '999004')
    assert_not_nil post
    assert_equal "Minimal Topic", post.title
    assert_equal "unknown", post.author  # Default value
    assert_equal [], post.tags_array     # Empty array
  end
end
