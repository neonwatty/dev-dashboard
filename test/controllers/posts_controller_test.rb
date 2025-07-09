require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get posts_url
    assert_response :success
  end

  test "should get show" do
    get post_url(posts(:huggingface_post))
    assert_response :success
  end

  test "should mark post as read" do
    post = posts(:huggingface_post)
    assert_equal 'unread', post.status
    
    patch mark_as_read_post_url(post)
    assert_redirected_to posts_url
    
    post.reload
    assert_equal 'read', post.status
  end

  test "should mark post as ignored" do
    post = posts(:huggingface_post)
    
    patch mark_as_ignored_post_url(post)
    assert_redirected_to posts_url
    
    post.reload
    assert_equal 'ignored', post.status
  end

  test "should mark post as responded" do
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
end
