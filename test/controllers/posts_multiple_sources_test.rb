require "test_helper"

class PostsMultipleSourcesTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
    
    # Create posts from different sources
    @github_post1 = Post.create!(
      source: "GitHub Issues",
      external_id: "gh-1",
      title: "GitHub Issue 1",
      url: "http://github.com/issue1",
      author: "github_user",
      status: "unread",
      posted_at: Time.current
    )
    
    @github_post2 = Post.create!(
      source: "GitHub Trending",
      external_id: "gh-trend-1",
      title: "GitHub Trending Repo",
      url: "http://github.com/trending",
      author: "trending_user",
      status: "unread",
      posted_at: Time.current
    )
    
    @reddit_post = Post.create!(
      source: "Reddit",
      external_id: "reddit-1",
      title: "Reddit Post",
      url: "http://reddit.com/post1",
      author: "reddit_user",
      status: "unread",
      posted_at: Time.current
    )
    
    @huggingface_post = Post.create!(
      source: "HuggingFace Forum",
      external_id: "hf-1",
      title: "HuggingFace Question",
      url: "http://huggingface.co/post1",
      author: "hf_user",
      status: "unread",
      posted_at: Time.current
    )
  end

  test "should filter by single source using legacy parameter" do
    get posts_url(source: "GitHub Issues")
    assert_response :success
    
    assert_match @github_post1.title, response.body
    assert_no_match @github_post2.title, response.body
    assert_no_match @reddit_post.title, response.body
    assert_no_match @huggingface_post.title, response.body
  end

  test "should filter by multiple sources" do
    get posts_url(sources: ["GitHub Issues", "GitHub Trending"])
    assert_response :success
    
    assert_match @github_post1.title, response.body
    assert_match @github_post2.title, response.body
    assert_no_match @reddit_post.title, response.body
    assert_no_match @huggingface_post.title, response.body
  end

  test "should filter by all GitHub sources" do
    get posts_url(sources: ["GitHub Issues", "GitHub Trending"])
    assert_response :success
    
    # Both GitHub posts should be shown
    assert_match @github_post1.title, response.body
    assert_match @github_post2.title, response.body
  end

  test "should show source checkboxes in filter section" do
    # Create corresponding Source records so they appear in @sources
    Source.create!(name: "GitHub Issues", source_type: "github", url: "http://github.com", active: true)
    Source.create!(name: "GitHub Trending", source_type: "github_trending", active: true)
    Source.create!(name: "Reddit", source_type: "reddit", url: "http://reddit.com", active: true)
    Source.create!(name: "HuggingFace Forum", source_type: "discourse", url: "http://huggingface.co", active: true)
    
    get posts_url
    assert_response :success
    
    # Should see source filter checkboxes
    assert_select "input[type='checkbox'][name='sources[]']", minimum: 1
    assert_select "label", text: /GitHub Issues/
    assert_select "label", text: /GitHub Trending/
    assert_select "label", text: /Reddit/
    assert_select "label", text: /HuggingFace Forum/
  end

  test "should maintain source selection in filters" do
    # Create corresponding Source records
    Source.create!(name: "GitHub Issues", source_type: "github", url: "http://github.com", active: true)
    Source.create!(name: "Reddit", source_type: "reddit", url: "http://reddit.com", active: true)
    
    get posts_url(sources: ["GitHub Issues", "Reddit"])
    assert_response :success
    
    # The checkboxes should exist for these sources
    assert_select "input[type='checkbox'][name='sources[]'][value='GitHub Issues']"
    assert_select "input[type='checkbox'][name='sources[]'][value='Reddit']"
    
    # Should see the selected sources in active filters
    assert_match "Source: GitHub Issues", response.body
    assert_match "Source: Reddit", response.body
  end

  test "should show active filter badges for selected sources" do
    get posts_url(sources: ["GitHub Issues", "Reddit"])
    assert_response :success
    
    # Should show filter badges
    assert_match "Source: GitHub Issues", response.body
    assert_match "Source: Reddit", response.body
  end

  test "should combine source filter with other filters" do
    get posts_url(sources: ["GitHub Issues", "Reddit"], keyword: "GitHub")
    assert_response :success
    
    # Should only show GitHub Issues post (matches both filters)
    assert_match @github_post1.title, response.body
    assert_no_match @reddit_post.title, response.body  # Reddit post doesn't match keyword
  end

  test "should handle empty sources array" do
    get posts_url(sources: [])
    assert_response :success
    
    # Should show all posts when sources array is empty
    assert_match @github_post1.title, response.body
    assert_match @github_post2.title, response.body
    assert_match @reddit_post.title, response.body
    assert_match @huggingface_post.title, response.body
  end

  test "should remove source filter from more filters section" do
    get posts_url
    assert_response :success
    
    # Source filter should not be in the advanced filters section
    # Check that there's no source select in the hidden advanced filters
    assert_select "#advanced-filters select[name='source']", count: 0
  end

  test "should have select all and clear all buttons" do
    get posts_url
    assert_response :success
    
    assert_select "button", text: "Select All"
    assert_select "button", text: "Clear All"
  end

  private

  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
end