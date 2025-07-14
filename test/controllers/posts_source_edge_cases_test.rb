require "test_helper"

class PostsSourceEdgeCasesTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
    
    # Create test data
    @post1 = Post.create!(
      source: "GitHub Issues",
      external_id: "edge-1",
      title: "Edge Case Post 1",
      url: "http://github.com/edge1",
      author: "edge_user",
      status: "unread",
      posted_at: Time.current
    )
    
    @post2 = Post.create!(
      source: "Special Source & Name",
      external_id: "edge-2",
      title: "Edge Case Post 2",
      url: "http://example.com/edge2",
      author: "special_user",
      status: "unread",
      posted_at: Time.current
    )
  end

  test "should handle malformed sources parameter gracefully" do
    # String instead of array
    get posts_url(sources: "GitHub Issues")
    assert_response :success
    
    # Should treat single string as array
    assert_match @post1.title, response.body
    assert_no_match @post2.title, response.body
  end

  test "should handle non-existent source names" do
    get posts_url(sources: ["NonExistentSource", "GitHub Issues"])
    assert_response :success
    
    # Should show GitHub Issues posts, ignore non-existent source
    assert_match @post1.title, response.body
    assert_no_match @post2.title, response.body
  end

  test "should handle duplicate sources in array" do
    get posts_url(sources: ["GitHub Issues", "GitHub Issues", "GitHub Issues"])
    assert_response :success
    
    # Should work correctly even with duplicates
    assert_match @post1.title, response.body
    assert_no_match @post2.title, response.body
  end

  test "should handle mixing legacy and new source parameters" do
    # Both source and sources[] parameters
    get posts_url(source: "Special Source & Name", sources: ["GitHub Issues"])
    assert_response :success
    
    # Should prefer sources[] array parameter
    assert_match @post1.title, response.body
    assert_no_match @post2.title, response.body
  end

  test "should handle special characters in source names" do
    get posts_url(sources: ["Special Source & Name"])
    assert_response :success
    
    # Should correctly filter by source with special characters
    assert_no_match @post1.title, response.body
    assert_match @post2.title, response.body
  end

  test "should handle XSS attempts in source parameter" do
    malicious_source = "<script>alert('XSS')</script>"
    
    # Create post with malicious source name (should be escaped in DB)
    malicious_post = Post.create!(
      source: malicious_source,
      external_id: "xss-1",
      title: "XSS Test Post",
      url: "http://example.com/xss",
      author: "xss_user",
      status: "unread",
      posted_at: Time.current
    )
    
    get posts_url(sources: [malicious_source])
    assert_response :success
    
    # Should not execute script
    assert_no_match "<script>alert('XSS')</script>", response.body
    assert_match "XSS Test Post", response.body
  end

  test "should handle very long source arrays" do
    # Create array with 100 sources
    many_sources = (1..100).map { |i| "Source#{i}" }
    many_sources << "GitHub Issues" # Add one real source
    
    get posts_url(sources: many_sources)
    assert_response :success
    
    # Should still work with large arrays
    assert_match @post1.title, response.body
  end

  test "should preserve source filters across pagination" do
    # Create Source record
    Source.create!(name: "GitHub Issues", source_type: "github", url: "http://github.com", active: true)
    
    # Create many posts to trigger pagination
    25.times do |i|
      Post.create!(
        source: "GitHub Issues",
        external_id: "page-#{i}",
        title: "Paginated Post #{i}",
        url: "http://github.com/page#{i}",
        author: "page_user",
        status: "unread",
        posted_at: i.hours.ago
      )
    end
    
    # Go to page 2 with source filter
    get posts_url(sources: ["GitHub Issues"], page: 2)
    assert_response :success
    
    # Should maintain source filter on page 2 - check that the checkbox exists and the filter badge is shown
    assert_select "input[type='checkbox'][name='sources[]'][value='GitHub Issues']"
    assert_match "Source: GitHub Issues", response.body
  end

  test "should handle nil sources parameter" do
    get posts_url(sources: nil)
    assert_response :success
    
    # Should show all posts
    assert_match @post1.title, response.body
    assert_match @post2.title, response.body
  end

  test "should clear source filter when Clear All link is clicked" do
    # Create Source records
    Source.create!(name: "GitHub Issues", source_type: "github", url: "http://github.com", active: true)
    
    # First request with sources filter
    get posts_url(sources: ["GitHub Issues"])
    assert_response :success
    assert_match "Source: GitHub Issues", response.body
    
    # Click clear all link (simulate by removing sources param)
    get posts_url
    assert_response :success
    
    # Should show all posts now
    assert_match @post1.title, response.body
    assert_match @post2.title, response.body
  end

  test "should handle source names with URL-unsafe characters" do
    # Create post with source name containing URL-unsafe characters
    unsafe_post = Post.create!(
      source: "Source with spaces & symbols!",
      external_id: "unsafe-1",
      title: "Unsafe Source Post",
      url: "http://example.com/unsafe",
      author: "unsafe_user",
      status: "unread",
      posted_at: Time.current
    )
    
    get posts_url(sources: ["Source with spaces & symbols!"])
    assert_response :success
    
    assert_match unsafe_post.title, response.body
    assert_no_match @post1.title, response.body
  end

  private

  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
end