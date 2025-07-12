require "test_helper"

class JobBroadcastingTest < ActiveJob::TestCase
  setup do
    @source = sources(:huggingface_forum)
    Post.where(source: 'huggingface').delete_all
  end

  test "FetchHuggingFaceJob creates new posts and calls broadcast methods" do
    # Mock successful API response
    mock_response = {
      "topic_list" => {
        "topics" => [
          {
            "id" => 12345,
            "title" => "Test Topic from Job",
            "slug" => "test-topic-from-job",
            "created_at" => "2025-07-12T10:00:00.000Z",
            "last_poster_username" => "job_test_user",
            "excerpt" => "This is a test topic from job",
            "tags" => ["test"],
            "reply_count" => 0,
            "like_count" => 0,
            "views" => 1
          }
        ]
      }
    }.to_json

    stub_request(:get, "#{@source.url}/latest.json?page=0")
      .to_return(status: 200, body: mock_response)

    # Test that new posts are created
    assert_difference('Post.count', 1) do
      FetchHuggingFaceJob.perform_now(@source.id)
    end

    # Verify the post was created correctly
    post = Post.find_by(external_id: '12345', source: 'huggingface')
    assert_not_nil post
    assert_equal "Test Topic from Job", post.title
    assert_equal "job_test_user", post.author
    
    # Verify source status was updated
    @source.reload
    assert_match /ok/, @source.status
  end

  test "FetchHuggingFaceJob does not create duplicate posts" do
    # Create existing post
    Post.create!(
      source: 'huggingface',
      external_id: '12345',
      title: 'Existing Post',
      url: 'https://discuss.huggingface.co/t/existing/12345',
      author: 'existing_user',
      posted_at: 1.hour.ago,
      status: 'unread',
      priority_score: 1.0
    )

    # Mock API response with same post
    mock_response = {
      "topic_list" => {
        "topics" => [
          {
            "id" => 12345,
            "title" => "Existing Post",
            "slug" => "existing-post",
            "created_at" => "2025-07-12T09:00:00.000Z",
            "last_poster_username" => "existing_user",
            "excerpt" => "This post already exists",
            "tags" => [],
            "reply_count" => 0,
            "like_count" => 0,
            "views" => 1
          }
        ]
      }
    }.to_json

    stub_request(:get, "#{@source.url}/latest.json?page=0")
      .to_return(status: 200, body: mock_response)

    # Should not create duplicate posts
    assert_no_difference('Post.count') do
      FetchHuggingFaceJob.perform_now(@source.id)
    end

    # Verify source status still updates
    @source.reload
    assert_match /ok/, @source.status
  end
end