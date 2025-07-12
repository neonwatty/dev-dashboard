require "test_helper"

class FetchHuggingFaceJobVcrTest < ActiveJob::TestCase
  setup do
    @source = sources(:huggingface_forum)
  end

  test "should fetch real posts from HuggingFace forum with VCR" do
    VCR.use_cassette("discourse/huggingface_latest", record: :new_episodes) do
      # Clear existing posts for clean test
      Post.where(source: 'huggingface').delete_all
      
      # Run the job with real API
      assert_difference("Post.count") do
        FetchHuggingFaceJob.perform_now(@source.id)
      end
      
      # Verify source was updated
      @source.reload
      assert_match /ok/, @source.status
      assert_not_nil @source.last_fetched_at
      
      # Verify real post data
      posts = Post.where(source: 'huggingface')
      assert posts.count > 0
      
      # Check first post has expected fields
      first_post = posts.first
      assert first_post.title.present?
      assert first_post.author.present?
      assert first_post.url.include?('discuss.huggingface.co')
      assert first_post.posted_at.present?
      assert first_post.priority_score > 0
    end
  end

  test "should handle API errors with VCR" do
    # This cassette would record a real error response
    VCR.use_cassette("discourse/huggingface_error", record: :new_episodes) do
      # Temporarily break the URL to force an error
      @source.update!(url: 'https://discuss.huggingface.co/nonexistent')
      
      assert_no_difference("Post.count") do
        FetchHuggingFaceJob.perform_now(@source.id)
      end
      
      @source.reload
      assert_match /error/, @source.status
    end
  end

  test "should fetch posts with specific date range" do
    # VCR can record different query parameters
    VCR.use_cassette("discourse/huggingface_filtered", 
                     match_requests_on: [:method, :uri, :query]) do
      # This would test pagination or date filtering when implemented
      service = DiscourseService.new(@source)
      topics = service.fetch_latest_topics(page: 1)
      
      assert topics.is_a?(Array)
      assert topics.count > 0
    end
  end
end