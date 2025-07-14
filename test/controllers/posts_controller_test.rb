require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end
  
  test "should get index" do
    get posts_url
    assert_response :success
  end

  test "should get show" do
    get post_url(posts(:huggingface_post))
    assert_response :success
  end

  test "should mark post as read" do
    sign_in_as(@user)
    post = posts(:huggingface_post)
    assert_equal 'unread', post.status
    
    patch mark_as_read_post_url(post)
    assert_redirected_to posts_url
    
    post.reload
    assert_equal 'read', post.status
  end

  test "should mark post as ignored" do
    sign_in_as(@user)
    post = posts(:huggingface_post)
    
    patch mark_as_ignored_post_url(post)
    assert_redirected_to posts_url
    
    post.reload
    assert_equal 'ignored', post.status
  end

  test "should mark post as responded" do
    sign_in_as(@user)
    post = posts(:huggingface_post)
    
    patch mark_as_responded_post_url(post)
    assert_redirected_to posts_url
    
    post.reload
    assert_equal 'responded', post.status
  end

  test "should filter posts by source" do
    get posts_url, params: { source: 'github' }
    assert_response :success
    
    # Should contain GitHub posts
    assert_includes @response.body, 'github'
  end

  test "should filter posts by multiple sources" do
    sign_in_as(@user)
    
    # Create posts with different sources
    github_post = Post.create!(
      source: 'GitHub Issues',
      external_id: 'multi_1',
      title: 'Multi GitHub Post',
      url: 'https://github.com/test/1',
      author: 'Test',
      posted_at: Time.current,
      status: 'unread'
    )
    
    hf_post = Post.create!(
      source: 'HuggingFace Forum',
      external_id: 'multi_2',
      title: 'Multi HF Post',
      url: 'https://huggingface.co/test/1',
      author: 'Test',
      posted_at: Time.current,
      status: 'unread'
    )
    
    reddit_post = Post.create!(
      source: 'Reddit',
      external_id: 'multi_3',
      title: 'Multi Reddit Post',
      url: 'https://reddit.com/test/1',
      author: 'Test',
      posted_at: Time.current,
      status: 'unread'
    )
    
    # Filter by multiple sources
    get posts_url, params: { sources: ['GitHub Issues', 'HuggingFace Forum'] }
    assert_response :success
    
    # Should include posts from selected sources
    assert_includes @response.body, 'Multi GitHub Post'
    assert_includes @response.body, 'Multi HF Post'
    
    # Should not include posts from non-selected sources
    assert_not_includes @response.body, 'Multi Reddit Post'
    
    # Clean up
    [github_post, hf_post, reddit_post].each(&:destroy)
  end

  test "should handle empty sources array" do
    sign_in_as(@user)
    
    get posts_url, params: { sources: [] }
    assert_response :success
    
    # Should show all posts when no sources selected
    # This tests the default behavior
  end

  test "should filter posts by keyword" do
    get posts_url, params: { keyword: 'ruby' }
    assert_response :success
  end

  test "should filter posts by status" do
    get posts_url, params: { status: 'read' }
    assert_response :success
  end

  test "should sort posts by most recent by default" do
    sign_in_as(@user)
    
    # Create posts with different dates
    old_post = Post.create!(
      source: 'test',
      external_id: 'old_1',
      title: 'Old Post',
      url: 'https://example.com/old',
      author: 'Test',
      posted_at: 2.days.ago,
      status: 'unread'
    )
    
    new_post = Post.create!(
      source: 'test',
      external_id: 'new_1',
      title: 'New Post',
      url: 'https://example.com/new',
      author: 'Test',
      posted_at: 1.hour.ago,
      status: 'unread'
    )
    
    get posts_url
    assert_response :success
    
    # New post should appear before old post in the response body
    new_pos = @response.body.index('New Post')
    old_pos = @response.body.index('Old Post')
    assert_not_nil new_pos, "New Post should be found in response"
    assert_not_nil old_pos, "Old Post should be found in response"
    assert new_pos < old_pos, "New post should appear before old post"
  end

  test "should sort posts by priority when requested" do
    sign_in_as(@user)
    
    # Create posts with different priority scores
    low_priority = Post.create!(
      source: 'test',
      external_id: 'low_1',
      title: 'Low Priority Post',
      url: 'https://example.com/low',
      author: 'Test',
      posted_at: 1.hour.ago,
      status: 'unread',
      priority_score: 1.0
    )
    
    high_priority = Post.create!(
      source: 'test',
      external_id: 'high_1',
      title: 'High Priority Post',
      url: 'https://example.com/high',
      author: 'Test',
      posted_at: 2.days.ago,
      status: 'unread',
      priority_score: 10.0
    )
    
    get posts_url, params: { sort: 'priority' }
    assert_response :success
    
    # High priority post should appear before low priority post
    high_pos = @response.body.index('High Priority Post')
    low_pos = @response.body.index('Low Priority Post')
    assert_not_nil high_pos, "High Priority Post should be found in response"
    assert_not_nil low_pos, "Low Priority Post should be found in response"
    assert high_pos < low_pos, "High priority post should appear before low priority post"
  end

  test "should sort posts by recent when explicitly requested" do
    sign_in_as(@user)
    
    old_post = Post.create!(
      source: 'test',
      external_id: 'old_2',
      title: 'Old Post 2',
      url: 'https://example.com/old2',
      author: 'Test',
      posted_at: 3.days.ago,
      status: 'unread'
    )
    
    new_post = Post.create!(
      source: 'test',
      external_id: 'new_2',
      title: 'New Post 2',
      url: 'https://example.com/new2',
      author: 'Test',
      posted_at: 30.minutes.ago,
      status: 'unread'
    )
    
    get posts_url, params: { sort: 'recent' }
    assert_response :success
    
    # New post should appear before old post
    new_pos = @response.body.index('New Post 2')
    old_pos = @response.body.index('Old Post 2')
    assert_not_nil new_pos, "New Post 2 should be found in response"
    assert_not_nil old_pos, "Old Post 2 should be found in response"
    assert new_pos < old_pos, "New post should appear before old post when sorted by recent"
  end

  test "should include all active sources in filter options even without posts" do
    sign_in_as(@user)
    
    # Create a new source with no posts
    new_source = Source.create!(
      name: 'test_source_no_posts',
      source_type: 'rss',
      url: 'https://example.com/feed',
      active: true,
      auto_fetch_enabled: false
    )
    
    get posts_url
    assert_response :success
    
    # Should include the new source in filter options even though it has no posts
    assert_includes @response.body, 'test_source_no_posts'
    
    # Clean up
    new_source.destroy
  end

  test "should filter posts correctly by actual source name" do
    sign_in_as(@user)
    
    # Create a test source
    test_source = Source.create!(
      name: 'Test Specific Source',
      source_type: 'rss',
      url: 'https://test.com/feed',
      active: true,
      auto_fetch_enabled: false
    )
    
    # Create posts with the actual source name (not hardcoded type)
    post1 = Post.create!(
      source: test_source.name,  # Using actual source name
      external_id: 'test_1',
      title: 'Test Post 1',
      url: 'https://test.com/1',
      author: 'Test Author',
      posted_at: Time.current,
      status: 'unread'
    )
    
    post2 = Post.create!(
      source: 'other_source',
      external_id: 'test_2', 
      title: 'Other Post',
      url: 'https://other.com/1',
      author: 'Other Author',
      posted_at: Time.current,
      status: 'unread'
    )
    
    # Filter by the specific source name
    get posts_url, params: { source: test_source.name }
    assert_response :success
    
    # Should only show posts from that specific source
    assert_includes @response.body, 'Test Post 1'
    assert_not_includes @response.body, 'Other Post'
    
    # Clean up
    [post1, post2, test_source].each(&:destroy)
  end
  
  private
  
  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
end
