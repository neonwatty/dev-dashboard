require "test_helper"

class PostsTurboFrameTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
    
    # Create test sources
    @github_source = Source.create!(
      name: "GitHub Test",
      source_type: "github",
      url: "https://github.com/test/repo",
      active: true
    )
    
    @hf_source = Source.create!(
      name: "HuggingFace Test",
      source_type: "discourse",
      url: "https://huggingface.co/forums",
      active: true
    )
    
    # Create test posts
    @github_post = Post.create!(
      source: @github_source.name,
      external_id: "github_test_1",
      title: "GitHub Test Post",
      url: "https://github.com/test/repo/issues/1",
      author: "github_user",
      status: "unread",
      posted_at: 1.hour.ago
    )
    
    @hf_post = Post.create!(
      source: @hf_source.name,
      external_id: "hf_test_1",
      title: "HuggingFace Test Post",
      url: "https://huggingface.co/discussions/1",
      author: "hf_user",
      status: "unread",
      posted_at: 2.hours.ago
    )
  end

  test "should handle turbo_stream request for source filtering" do
    get posts_path, 
        params: { sources: [@github_source.name] },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    
    # Should contain turbo stream actions
    assert_includes response.body, "turbo-stream"
    assert_includes response.body, 'action="replace"'
    assert_includes response.body, 'target="posts-list"'
    assert_includes response.body, 'target="posts-pagination"'
    
    # Should include filtered content
    assert_includes response.body, "GitHub Test Post"
    assert_not_includes response.body, "HuggingFace Test Post"
  end

  test "should handle regular HTML request for source filtering" do
    get posts_path, params: { sources: [@github_source.name] }
    
    assert_response :success
    assert_equal "text/html", response.media_type
    
    # Should contain turbo frame tags
    assert_includes response.body, 'id="posts-list"'
    assert_includes response.body, 'id="posts-pagination"'
    
    # Should include filtered content
    assert_includes response.body, "GitHub Test Post"
    assert_not_includes response.body, "HuggingFace Test Post"
  end

  test "should filter by multiple sources in turbo stream" do
    get posts_path, 
        params: { sources: [@github_source.name, @hf_source.name] },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :success
    
    # Should include both posts
    assert_includes response.body, "GitHub Test Post"
    assert_includes response.body, "HuggingFace Test Post"
  end

  test "should handle empty sources array in turbo stream" do
    get posts_path, 
        params: { sources: [] },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :success
    
    # Should show all posts when no sources selected
    assert_includes response.body, "GitHub Test Post"
    assert_includes response.body, "HuggingFace Test Post"
  end

  test "should combine source filter with other filters in turbo stream" do
    # Mark one post as read
    @github_post.update!(status: 'read')
    
    get posts_path, 
        params: { 
          sources: [@github_source.name], 
          status: 'read' 
        },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :success
    
    # Should show only the read GitHub post
    assert_includes response.body, "GitHub Test Post"
    assert_not_includes response.body, "HuggingFace Test Post"
  end

  test "should include source filter options in turbo stream response" do
    get posts_path, 
        params: { sources: [@github_source.name] },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :success
    
    # Response should include the posts-list frame with source names
    assert_includes response.body, @github_source.name
    assert_includes response.body, @hf_source.name
  end

  test "should handle pagination with source filters in turbo stream" do
    # Create many posts to trigger pagination
    (1..25).each do |i|
      Post.create!(
        source: @github_source.name,
        external_id: "github_paginated_#{i}",
        title: "GitHub Paginated Post #{i}",
        url: "https://github.com/test/repo/issues/#{i}",
        author: "github_user",
        status: "unread",
        posted_at: i.hours.ago
      )
    end
    
    get posts_path, 
        params: { 
          sources: [@github_source.name], 
          page: 2 
        },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :success
    
    # Should include pagination turbo stream
    assert_includes response.body, 'target="posts-pagination"'
    
    # Should maintain source filter in pagination
    assert_includes response.body, "GitHub"
    assert_not_includes response.body, "HuggingFace Test Post"
  end

  test "should handle turbo frame request with data-turbo-frame header" do
    get posts_path, 
        params: { sources: [@github_source.name] },
        headers: { 
          "Accept" => "text/html", 
          "Turbo-Frame" => "posts-list"
        }
    
    assert_response :success
    
    # Should contain turbo frame content
    assert_includes response.body, 'id="posts-list"'
    assert_includes response.body, "GitHub Test Post"
    assert_not_includes response.body, "HuggingFace Test Post"
  end

  private

  def sign_in_as(user)
    post session_url, params: { 
      email_address: user.email_address, 
      password: "password" 
    }
  end
end