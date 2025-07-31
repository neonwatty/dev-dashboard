require "test_helper"

class PostWorkflowTest < ActionDispatch::IntegrationTest
  setup do
    @source = sources(:one)
    @post = posts(:one)
    @user = users(:one)
    sign_in_as(@user)
  end

  test "complete workflow: view posts, filter, mark as read" do
    # Visit posts index
    get posts_path
    assert_response :success
    assert_select "h1", "Posts"
    
    # Verify post is displayed
    assert_select "h3", @post.title
    assert_select "span", text: "Unread"
    
    # Filter by source
    get posts_path(source: "one")
    assert_response :success
    assert_select "h3", @post.title
    
    # Filter by different source (should not show our huggingface post)
    get posts_path(source: "github")
    assert_response :success
    # Should show github posts from fixtures (github_issue and responded_post)
    assert_select ".space-y-4 h3", count: 2
    
    # Search by keyword
    get posts_path(keyword: @post.title.split.first)
    assert_response :success
    assert_select "h3", @post.title
    
    # Mark post as read
    patch mark_as_read_post_path(@post)
    assert_redirected_to posts_path
    follow_redirect!
    
    # Verify status changed
    @post.reload
    assert_equal "read", @post.status
    
    # Filter to show only unread posts
    get posts_path(status: "unread")
    assert_response :success
    assert_select "h3", text: @post.title, count: 0
    
    # Filter to show read posts
    get posts_path(status: "read")
    assert_response :success
    assert_select "h3", @post.title
  end

  test "workflow: mark multiple posts as read and ignored" do
    # Create additional posts
    unread_post1 = Post.create!(
      source: "huggingface",
      external_id: "workflow-test-1",
      title: "Test Post 1",
      url: "https://example.com/1",
      author: "tester",
      posted_at: 1.hour.ago,
      status: "unread"
    )
    
    unread_post2 = Post.create!(
      source: "github",
      external_id: "workflow-test-2",
      title: "Test Post 2",
      url: "https://example.com/2",
      author: "tester",
      posted_at: 2.hours.ago,
      status: "unread"
    )
    
    # Visit posts index
    get posts_path
    assert_response :success
    
    # Mark first post as read
    patch mark_as_read_post_path(unread_post1)
    assert_redirected_to posts_path
    
    unread_post1.reload
    assert_equal "read", unread_post1.status
    
    # Mark second post as ignored
    patch mark_as_ignored_post_path(unread_post2)
    assert_redirected_to posts_path
    
    unread_post2.reload
    assert_equal "ignored", unread_post2.status
    
    # Verify filtering works correctly
    get posts_path(status: "unread")
    assert_response :success
    # Should show only truly unread posts
    
    get posts_path(status: "ignored")
    assert_response :success
    assert_select "h3", "Test Post 2"
  end

  test "workflow: navigate from posts to sources and back" do
    # Start at posts
    get posts_path
    assert_response :success
    
    # Click on sources link (would be in navigation)
    get sources_path
    assert_response :success
    assert_select "h1", "Sources"
    
    # Verify sources are shown
    assert_select "a", @source.name
    
    # Click back to posts with specific source filter
    get posts_path(source: "one")
    assert_response :success
    
    # Should see posts from that source
    assert_select "h3", minimum: 1
  end

  test "workflow: handle invalid post operations gracefully" do
    # Try to access non-existent post
    get post_path(999999)
    assert_response :not_found
    
    # Try to mark non-existent post as read
    patch mark_as_read_post_path(999999)
    assert_response :not_found
    
    # Try invalid status filter
    get posts_path(status: "invalid_status")
    assert_response :success
    # Should still work, just show all posts
  end

  test "workflow: pagination navigation" do
    # Create many posts to trigger pagination
    35.times do |i|
      Post.create!(
        source: "huggingface",
        external_id: "pagination-test-#{i}",
        title: "Pagination Test Post #{i}",
        url: "https://example.com/page-#{i}",
        author: "tester",
        posted_at: i.hours.ago,
        status: "unread",
        priority_score: i
      )
    end
    
    # Visit first page
    get posts_path
    assert_response :success
    
    # Should have pagination controls (Kaminari pagination)
    assert_select ".pagination"
    
    # Navigate to page 2
    get posts_path(page: 2)
    assert_response :success
    
    # Should show different posts
    assert_select "h3", minimum: 1
  end

  test "workflow: combined filters and search" do
    # Create posts with specific attributes
    rails_post = Post.create!(
      source: "github",
      external_id: "filter-test-1",
      title: "Rails Security Update",
      url: "https://github.com/rails/rails/issues/1",
      author: "rails-bot",
      posted_at: 1.hour.ago,
      status: "unread",
      tags: '["rails", "security"]'
    )
    
    python_post = Post.create!(
      source: "pytorch",
      external_id: "filter-test-2",
      title: "PyTorch Performance Tips",
      url: "https://pytorch.org/tips",
      author: "pytorch-team",
      posted_at: 2.hours.ago,
      status: "read",
      tags: '["pytorch", "performance"]'
    )
    
    # Search for "rails" - should find rails post
    get posts_path(keyword: "rails")
    assert_response :success
    assert_select "h3", "Rails Security Update"
    assert_select "h3", text: "PyTorch Performance Tips", count: 0
    
    # Filter by github source and unread status
    get posts_path(source: "github", status: "unread")
    assert_response :success
    assert_select "h3", "Rails Security Update"
    
    # Filter by read status - should find pytorch post
    get posts_path(status: "read")
    assert_response :success
    assert_select "h3", "PyTorch Performance Tips"
    
    # Combine keyword and source filter
    get posts_path(keyword: "performance", source: "pytorch")
    assert_response :success
    assert_select "h3", "PyTorch Performance Tips"
  end
end