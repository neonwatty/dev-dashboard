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

  test "should filter posts by keyword" do
    get posts_url, params: { keyword: 'ruby' }
    assert_response :success
  end

  test "should filter posts by status" do
    get posts_url, params: { status: 'read' }
    assert_response :success
  end

  test "should sort posts by most recent by default" do
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
    assert new_pos < old_pos, "New post should appear before old post"
  end

  test "should sort posts by priority when requested" do
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
    assert high_pos < low_pos, "High priority post should appear before low priority post"
  end

  test "should sort posts by recent when explicitly requested" do
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
    assert new_pos < old_pos, "New post should appear before old post when sorted by recent"
  end
end
