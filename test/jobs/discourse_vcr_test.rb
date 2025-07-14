require "test_helper"

class DiscourseVcrTest < ActiveJob::TestCase
  setup do
    @huggingface_source = sources(:huggingface_forum)
    @pytorch_source = sources(:pytorch_forum)
    
    # Clean up any existing posts
    Post.where(source: ['huggingface', 'pytorch']).delete_all
  end

  test "should fetch real posts from HuggingFace forum" do
    VCR.use_cassette("discourse/huggingface_latest", 
                     record: :new_episodes,
                     re_record_interval: 7.days) do
      
      # We don't know exactly how many posts will be returned
      initial_count = Post.count
      FetchHuggingFaceJob.perform_now(@huggingface_source.id)
      
      assert Post.count > initial_count, "Should create new posts"
      posts_created = Post.count - initial_count
      puts "\n📊 Created #{posts_created} posts from HuggingFace forum"
      
      # Verify source was updated
      @huggingface_source.reload
      assert_match /ok/, @huggingface_source.status
      assert_not_nil @huggingface_source.last_fetched_at
      
      # Verify real post data
      posts = Post.where(source: 'huggingface').order(posted_at: :desc)
      assert posts.count > 0
      
      # Check first post has expected fields
      first_post = posts.first
      assert first_post.title.present?, "Post should have a title"
      assert first_post.author.present?, "Post should have an author"
      assert first_post.url.include?('discuss.huggingface.co'), "URL should point to HuggingFace forum"
      assert first_post.posted_at.present?, "Post should have a posted_at date"
      assert first_post.priority_score > 0, "Post should have a priority score"
      
      # Check for reasonable data
      assert first_post.title.length > 5, "Title should be meaningful"
      assert first_post.author != 'unknown', "Should extract real author"
    end
  end

  test "should fetch real posts from PyTorch forum" do
    VCR.use_cassette("discourse/pytorch_latest", 
                     record: :new_episodes,
                     re_record_interval: 7.days) do
      
      initial_count = Post.count
      FetchPytorchJob.perform_now(@pytorch_source.id)
      
      assert Post.count > initial_count, "Should create new posts"
      posts_created = Post.count - initial_count
      puts "\n📊 Created #{posts_created} posts from PyTorch forum"
      
      # Verify source was updated
      @pytorch_source.reload
      assert_match /ok/, @pytorch_source.status
      assert_not_nil @pytorch_source.last_fetched_at
      
      # Verify PyTorch-specific scoring
      posts = Post.where(source: 'pytorch')
      question_posts = posts.select { |p| p.title.include?('?') }
      
      if question_posts.any?
        # Questions should have higher priority scores
        question_post = question_posts.first
        non_question_post = posts.find { |p| !p.title.include?('?') }
        
        if non_question_post
          assert question_post.priority_score > non_question_post.priority_score,
                 "Questions should have higher priority in PyTorch forum"
        end
      end
    end
  end

  test "should handle pagination with VCR" do
    VCR.use_cassette("discourse/huggingface_paginated", 
                     record: :new_episodes) do
      
      service = DiscourseService.new(@huggingface_source)
      
      # Fetch first page
      page1_topics = service.fetch_latest_topics(page: 0)
      assert page1_topics.is_a?(Array)
      assert page1_topics.count > 0
      
      # Fetch second page if available
      page2_topics = service.fetch_latest_topics(page: 1)
      assert page2_topics.is_a?(Array)
      
      # Verify different content if second page has results
      if page2_topics.count > 0
        page1_ids = page1_topics.map { |t| t['id'] }
        page2_ids = page2_topics.map { |t| t['id'] }
        assert_empty (page1_ids & page2_ids), "Pages should have different topics"
      end
    end
  end

  test "should handle real API errors gracefully" do
    VCR.use_cassette("discourse/huggingface_error", 
                     record: :new_episodes) do
      
      # Temporarily use an invalid endpoint
      original_url = @huggingface_source.url
      @huggingface_source.update!(url: "#{original_url}/invalid_endpoint")
      
      assert_no_difference("Post.count") do
        FetchHuggingFaceJob.perform_now(@huggingface_source.id)
      end
      
      @huggingface_source.reload
      assert_match /error/, @huggingface_source.status
    end
  end

  test "should respect rate limits with VCR" do
    VCR.use_cassette("discourse/rate_limit_test", 
                     record: :new_episodes) do
      
      # Make multiple rapid requests
      3.times do |i|
        service = DiscourseService.new(@huggingface_source)
        topics = service.fetch_latest_topics(page: i)
        assert topics.is_a?(Array), "Request #{i+1} should succeed"
        
        # Small delay to be respectful even during recording
        sleep 0.5 if VCR.current_cassette.recording?
      end
    end
  end

  test "should extract all metadata fields from real responses" do
    VCR.use_cassette("discourse/metadata_extraction", 
                     record: :new_episodes) do
      
      service = DiscourseService.new(@huggingface_source)
      topics = service.fetch_latest_topics
      
      # Find a topic with rich metadata
      rich_topic = topics.find { |t| t['tags'].present? && t['excerpt'].present? }
      
      if rich_topic
        success = service.create_post_from_topic(rich_topic)
        assert success, "Should create post from rich topic"
        
        post = Post.find_by(external_id: rich_topic['id'].to_s, source: 'huggingface')
        assert_not_nil post
        
        # Verify metadata extraction
        assert_equal rich_topic['title'], post.title
        assert post.summary.present?, "Should extract excerpt as summary"
        assert post.tags_array.count > 0, "Should extract tags"
        assert_equal rich_topic['last_poster_username'], post.author
      end
    end
  end

  test "should handle topics with missing fields from real API" do
    VCR.use_cassette("discourse/missing_fields", 
                     record: :new_episodes) do
      
      service = DiscourseService.new(@pytorch_source)
      topics = service.fetch_latest_topics
      
      # Process all topics, including those with missing fields
      created_count = 0
      topics.each do |topic|
        if service.create_post_from_topic(topic)
          created_count += 1
          
          post = Post.find_by(external_id: topic['id'].to_s, source: 'pytorch')
          assert_not_nil post
          
          # Verify defaults for missing fields
          assert_equal 'unknown', post.author if topic['last_poster_username'].nil?
          assert_equal [], post.tags_array if topic['tags'].nil?
          assert post.url.present?, "Should always generate a URL"
        end
      end
      
      assert created_count > 0, "Should create at least some posts"
    end
  end

  test "should compare real API response times" do
    # This test helps understand API performance
    VCR.use_cassette("discourse/performance_test", 
                     record: :new_episodes) do
      
      start_time = Time.current
      service = DiscourseService.new(@huggingface_source)
      topics = service.fetch_latest_topics
      end_time = Time.current
      
      response_time = end_time - start_time
      
      # Log for informational purposes
      puts "\nAPI Response time: #{(response_time * 1000).round}ms for #{topics.count} topics"
      
      # Reasonable expectation for API response
      assert response_time < 5.0, "API should respond within 5 seconds"
      assert topics.count > 0, "Should fetch some topics"
    end
  end
end