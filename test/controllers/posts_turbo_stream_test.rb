require "test_helper"

class PostsTurboStreamTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
    
    @post = Post.create!(
      source: "GitHub Issues",
      external_id: "turbo-1",
      title: "Turbo Stream Test Post",
      url: "http://github.com/turbo",
      author: "turbo_user",
      status: "unread",
      posted_at: Time.current
    )
  end

  test "mark_as_ignored should respond with turbo stream" do
    initial_count = Post.where.not(status: 'ignored').count
    
    patch mark_as_ignored_post_path(@post), headers: { 
      'Accept' => 'text/vnd.turbo-stream.html, text/html' 
    }
    
    assert_response :success
    assert_equal 'text/vnd.turbo-stream.html; charset=utf-8', response.content_type
    
    # Check that response contains turbo-stream elements
    assert_match %r{<turbo-stream action="remove" target="post_#{@post.id}">}, response.body
    assert_match %r{<turbo-stream action="update" target="post-count">}, response.body
    assert_match "Posts: #{initial_count - 1}", response.body
    
    # Verify post status was updated
    @post.reload
    assert_equal "ignored", @post.status
  end

  test "mark_as_read should respond with turbo stream" do
    patch mark_as_read_post_path(@post), headers: { 
      'Accept' => 'text/vnd.turbo-stream.html, text/html' 
    }
    
    assert_response :success
    assert_equal 'text/vnd.turbo-stream.html; charset=utf-8', response.content_type
    
    # Check turbo stream updates status badge
    assert_match %r{<turbo-stream action="replace" target="post_#{@post.id}_status">}, response.body
    assert_match 'bg-green-100 text-green-800', response.body
    assert_match 'Read', response.body
    
    # Check turbo stream updates entire card
    assert_match %r{<turbo-stream action="update" target="post_#{@post.id}_card">}, response.body
    
    @post.reload
    assert_equal "read", @post.status
  end

  test "mark_as_responded should respond with turbo stream" do
    patch mark_as_responded_post_path(@post), headers: { 
      'Accept' => 'text/vnd.turbo-stream.html, text/html' 
    }
    
    assert_response :success
    assert_equal 'text/vnd.turbo-stream.html; charset=utf-8', response.content_type
    
    # Check turbo stream updates status badge
    assert_match %r{<turbo-stream action="replace" target="post_#{@post.id}_status">}, response.body
    assert_match 'bg-blue-100 text-blue-800', response.body
    assert_match 'Responded', response.body
    
    @post.reload
    assert_equal "responded", @post.status
  end

  test "mark_as_ignored should include notification in turbo stream" do
    patch mark_as_ignored_post_path(@post), headers: { 
      'Accept' => 'text/vnd.turbo-stream.html, text/html' 
    }
    
    # Check for notification turbo stream
    assert_match %r{<turbo-stream action="prepend" target="notifications">}, response.body
    assert_match 'Post cleared from dashboard', response.body
    assert_match 'data-controller="notification"', response.body
    assert_match 'data-notification-delay-value="3000"', response.body
  end

  test "should handle missing post gracefully" do
    patch mark_as_read_post_path(id: 999999), headers: { 
      'Accept' => 'text/vnd.turbo-stream.html, text/html' 
    }
    
    assert_response :not_found
  end

  test "mark_as_read should not show read button after update" do
    patch mark_as_read_post_path(@post), headers: { 
      'Accept' => 'text/vnd.turbo-stream.html, text/html' 
    }
    
    # The re-rendered card should not include a read button
    assert_no_match 'data-action="click->post-actions#markAsRead"', response.body
  end

  test "mark_as_ignored removes post from default view" do
    get posts_path
    assert_select "#post_#{@post.id}"
    
    patch mark_as_ignored_post_path(@post), headers: { 
      'Accept' => 'text/vnd.turbo-stream.html, text/html' 
    }
    
    get posts_path
    assert_select "#post_#{@post.id}", false, "Ignored post should not appear in default view"
  end

  test "all actions should require authentication" do
    sign_out
    
    # Test mark_as_read
    patch mark_as_read_post_path(@post), headers: { 
      'Accept' => 'text/vnd.turbo-stream.html, text/html' 
    }
    assert_redirected_to new_session_path
    
    # Test mark_as_ignored
    patch mark_as_ignored_post_path(@post), headers: { 
      'Accept' => 'text/vnd.turbo-stream.html, text/html' 
    }
    assert_redirected_to new_session_path
    
    # Test mark_as_responded
    patch mark_as_responded_post_path(@post), headers: { 
      'Accept' => 'text/vnd.turbo-stream.html, text/html' 
    }
    assert_redirected_to new_session_path
  end

  private

  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
  
  def sign_out
    delete session_url
  end
end