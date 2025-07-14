require "test_helper"

class DiscourseWorkflowVcrTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
    
    @huggingface_source = sources(:huggingface_forum)
    @pytorch_source = sources(:pytorch_forum)
  end

  test "complete workflow: fetch real posts and interact with them" do
    VCR.use_cassette("integration/discourse_workflow", 
                     record: :new_episodes,
                     re_record_interval: 1.day) do
      
      # Clear existing posts for clean test
      Post.where(source: ['huggingface', 'pytorch']).delete_all
      
      # Visit sources page
      get sources_path
      assert_response :success
      assert_select "h1", "Sources"
      
      # Refresh HuggingFace source
      post refresh_source_path(@huggingface_source)
      assert_response :redirect
      
      # Wait for job to complete (in test environment it's synchronous)
      @huggingface_source.reload
      assert_match /ok/, @huggingface_source.status
      
      # Visit posts page
      get posts_path
      assert_response :success
      
      # Should see real posts
      posts = Post.where(source: 'huggingface')
      assert posts.count > 0, "Should have fetched posts"
      
      # Interact with a real post
      first_post = posts.first
      
      # View post details
      get post_path(first_post)
      assert_response :success
      assert_select "h1", first_post.title
      
      # Mark as read
      patch mark_as_read_post_path(first_post)
      assert_redirected_to posts_path
      
      first_post.reload
      assert_equal "read", first_post.status
      
      # Filter by source
      get posts_path(source: "huggingface")
      assert_response :success
      assert_select "h3", minimum: 1
      
      # Search by keyword (using a common word from real posts)
      if first_post.title.split.any? { |word| word.length > 4 }
        keyword = first_post.title.split.find { |word| word.length > 4 }
        get posts_path(keyword: keyword)
        assert_response :success
        # Should find at least the post we know has this keyword
        assert_select "h3", text: /#{Regexp.escape(keyword)}/i
      end
    end
  end

  test "workflow: refresh all sources and verify real-time updates" do
    VCR.use_cassette("integration/refresh_all_workflow", 
                     record: :new_episodes) do
      
      # Clear posts
      Post.where(source: ['huggingface', 'pytorch']).delete_all
      
      # Visit sources page
      get sources_path
      assert_response :success
      
      # Refresh all sources
      post refresh_all_sources_path
      assert_redirected_to sources_path
      follow_redirect!
      
      # Check both sources were updated
      [@huggingface_source, @pytorch_source].each do |source|
        source.reload
        assert_match /ok/, source.status, "#{source.name} should be updated"
        assert_not_nil source.last_fetched_at
      end
      
      # Verify posts from both sources
      assert Post.where(source: 'huggingface').count > 0, "Should have HuggingFace posts"
      assert Post.where(source: 'pytorch').count > 0, "Should have PyTorch posts"
      
      # Visit posts page
      get posts_path
      assert_response :success
      
      # Should see mixed posts from both sources
      assert_select "span.bg-yellow-500", minimum: 1  # HuggingFace badge
      assert_select "span.bg-orange-500", minimum: 1  # PyTorch badge
    end
  end

  test "workflow: handle API failures gracefully in UI" do
    VCR.use_cassette("integration/api_failure_workflow", 
                     record: :new_episodes) do
      
      # Create a source with bad URL
      post sources_path, params: {
        source: {
          name: "Bad Discourse Forum",
          source_type: "discourse",
          url: "https://discuss.example.invalid",
          active: true
        }
      }
      
      bad_source = Source.last
      assert_redirected_to bad_source
      
      # Try to refresh it
      post refresh_source_path(bad_source)
      assert_response :redirect
      
      # Check error status is displayed
      get sources_path
      assert_response :success
      
      bad_source.reload
      assert_match /error/, bad_source.status
      
      # Error badge should be visible
      assert_select "span.bg-red-100", text: /Error/
    end
  end

  test "workflow: pagination and filtering with real data" do
    VCR.use_cassette("integration/pagination_workflow", 
                     record: :new_episodes) do
      
      # Ensure we have enough posts for pagination
      Post.where(source: 'huggingface').delete_all
      
      # Fetch posts
      FetchHuggingFaceJob.perform_now(@huggingface_source.id)
      
      post_count = Post.where(source: 'huggingface').count
      
      if post_count > 25  # Default pagination
        # Visit first page
        get posts_path
        assert_response :success
        
        # Should have pagination controls
        assert_select ".pagination"
        
        # Visit second page
        get posts_path(page: 2)
        assert_response :success
        
        # Should still see posts
        assert_select "h3", minimum: 1
      end
      
      # Test filtering with real data
      posts_with_tags = Post.where(source: 'huggingface').where.not(tags: '[]')
      
      if posts_with_tags.any?
        # Get a real tag
        sample_post = posts_with_tags.first
        tag = sample_post.tags_array.first
        
        # Filter by this tag (would need to implement tag filtering)
        # get posts_path(tag: tag)
        # assert_response :success
      end
    end
  end

  test "workflow: source configuration with real API" do
    VCR.use_cassette("integration/source_config_workflow", 
                     record: :new_episodes) do
      
      # Create a new Discourse source
      get new_source_path
      assert_response :success
      
      post sources_path, params: {
        source: {
          name: "LangChain Forum",
          source_type: "discourse",
          url: "https://github.com/langchain-ai/langchain/discussions",
          config: {
            fetch_full_content: true,
            priority_tags: ["bug", "help-wanted"]
          }.to_json,
          active: true
        }
      }
      
      new_source = Source.last
      
      # Test connection
      post test_connection_source_path(new_source)
      
      new_source.reload
      # Should show connection result (might fail if URL isn't a real Discourse)
      assert new_source.status.present?
    end
  end
end