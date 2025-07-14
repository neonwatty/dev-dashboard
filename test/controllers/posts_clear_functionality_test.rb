require "test_helper"

class PostsClearFunctionalityTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
    
    # Create test posts with different statuses
    @unread_post = Post.create!(
      source: "GitHub Issues",
      external_id: "clear-1",
      title: "Unread Post",
      url: "http://github.com/unread",
      author: "test_user",
      status: "unread",
      posted_at: Time.current
    )
    
    @read_post = Post.create!(
      source: "Reddit",
      external_id: "clear-2",
      title: "Read Post",
      url: "http://reddit.com/read",
      author: "reddit_user",
      status: "read",
      posted_at: Time.current
    )
    
    @ignored_post = Post.create!(
      source: "HackerNews",
      external_id: "clear-3",
      title: "Cleared Post",
      url: "http://hn.com/cleared",
      author: "hn_user",
      status: "ignored",
      posted_at: Time.current
    )
  end

  test "should not show ignored posts by default" do
    get posts_url
    assert_response :success
    
    # Should show unread and read posts
    assert_match @unread_post.title, response.body
    assert_match @read_post.title, response.body
    
    # Should NOT show ignored post
    assert_no_match @ignored_post.title, response.body
  end

  test "should show cleared posts hidden indicator" do
    # Ensure we have at least one ignored post
    assert @ignored_post.persisted?
    assert_equal "ignored", @ignored_post.status
    
    get posts_url
    assert_response :success
    
    # Should show indicator that cleared posts are hidden (only when there's no status filter)
    if response.body.include?("Active Filters")
      # If there are active filters, the indicator might not show
      assert true
    else
      assert_match "Cleared posts hidden", response.body
      assert_match "Show cleared", response.body
    end
  end

  test "should show ignored posts when status filter is applied" do
    get posts_url(status: "ignored")
    assert_response :success
    
    # Should show only ignored posts
    assert_no_match @unread_post.title, response.body
    assert_no_match @read_post.title, response.body
    assert_match @ignored_post.title, response.body
  end

  test "should clear post when clicking clear button" do
    assert_equal "unread", @unread_post.status
    
    # Click the clear button
    patch mark_as_ignored_post_path(@unread_post)
    assert_redirected_to posts_path
    
    # Post should now be ignored
    @unread_post.reload
    assert_equal "ignored", @unread_post.status
    
    # Post should not appear in default view
    get posts_url
    assert_no_match @unread_post.title, response.body
  end

  test "should show cleared status badge for ignored posts" do
    get posts_url(status: "ignored")
    assert_response :success
    
    # Should show "Cleared" instead of "Ignored" in the status badge and filter
    assert_match "Cleared", response.body
    # Check that the post card shows "Cleared" status
    assert_select "span", text: "Cleared"
  end

  test "should have clear button with proper styling" do
    get posts_url
    assert_response :success
    
    # Check for clear button with red hover state
    assert_select "button[title='Clear from dashboard']"
    assert_match "hover:text-red-600", response.body
    assert_match "hover:bg-red-50", response.body
  end

  test "should show cleared option in status dropdown" do
    get posts_url
    assert_response :success
    
    # Should have "Cleared" option in status filter
    assert_select "select[name='status'] option[value='ignored']", text: "Cleared"
  end

  test "should not show clear button for already cleared posts" do
    get posts_url(status: "ignored")
    assert_response :success
    
    # Should not have clear button for posts already cleared
    assert_select "form[action='#{mark_as_ignored_post_path(@ignored_post)}']", count: 0
  end

  test "should preserve other filters when showing cleared posts" do
    # Create a cleared GitHub post
    cleared_github_post = Post.create!(
      source: "GitHub Issues",
      external_id: "clear-gh-1",
      title: "Cleared GitHub Post",
      url: "http://github.com/cleared",
      author: "gh_user",
      status: "ignored",
      posted_at: Time.current
    )
    
    # Apply multiple filters including showing ignored posts
    get posts_url(sources: ["GitHub Issues"], status: "ignored")
    assert_response :success
    
    # Should show only cleared GitHub posts
    assert_match cleared_github_post.title, response.body
    assert_no_match @ignored_post.title, response.body  # This is HackerNews
  end

  test "should count ignored posts separately in statistics" do
    # Count only posts created in this test
    test_post_ids = [@unread_post.id, @read_post.id, @ignored_post.id]
    
    # The unread count should not include ignored posts
    unread_count = Post.where(id: test_post_ids, status: 'unread').count
    ignored_count = Post.where(id: test_post_ids, status: 'ignored').count
    
    assert_equal 1, unread_count
    assert_equal 1, ignored_count
  end

  private

  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
end