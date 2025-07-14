require "test_helper"

class PostsStimulusTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
    
    @post = Post.create!(
      source: "GitHub Issues",
      external_id: "stimulus-1",
      title: "Stimulus Test Post",
      url: "http://github.com/stimulus",
      author: "stimulus_user",
      status: "unread",
      posted_at: Time.current
    )
  end

  test "should respond to JSON for mark_as_read" do
    patch mark_as_read_post_path(@post), headers: { 'Accept' => 'application/json' }
    assert_response :ok
    
    @post.reload
    assert_equal "read", @post.status
  end

  test "should respond to JSON for mark_as_ignored" do
    patch mark_as_ignored_post_path(@post), headers: { 'Accept' => 'application/json' }
    assert_response :ok
    
    @post.reload
    assert_equal "ignored", @post.status
  end

  test "should respond to JSON for mark_as_responded" do
    patch mark_as_responded_post_path(@post), headers: { 'Accept' => 'application/json' }
    assert_response :ok
    
    @post.reload
    assert_equal "responded", @post.status
  end

  test "should include Stimulus controller in post card" do
    get posts_url
    assert_response :success
    
    # Should have the Stimulus controller and target attributes
    assert_select "div[data-controller='post-actions']"
    assert_select "div[data-post-actions-target='card']"
  end

  test "should include data attributes for action buttons" do
    get posts_url
    assert_response :success
    
    # Should have Stimulus action attributes on buttons
    assert_select "button[data-action*='post-actions#clear']"
    assert_select "button[data-action*='post-actions#markAsRead']"
    assert_select "button[data-action*='post-actions#markAsResponded']"
    
    # Should have URL data attributes (method is handled by fetch in JS)
    assert_select "button[data-url]", minimum: 3
  end

  test "should include status badge data attribute" do
    get posts_url
    assert_response :success
    
    # Should have data attribute on status badge and unique ID
    assert_select "span[data-status-badge]"
    assert_select "span[id^='post_'][id$='_status']"
  end

  test "should include post count id in navigation" do
    get posts_url
    assert_response :success
    
    # Should have id on post count in navigation for Turbo Stream updates
    assert_select "span#post-count"
  end

  test "should use button elements instead of forms" do
    get posts_url
    assert_response :success
    
    # Should use button elements with type="button" instead of form submissions
    assert_select "button[type='button']", minimum: 3
    
    # Should NOT have action type attributes (removed from new implementation)
    # Buttons are identified by their data-action attribute instead
  end

  private

  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
end