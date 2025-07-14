require "test_helper"
require_relative "../../app/services/github_service"

class PostDuplicateHandlingTest < ActiveSupport::TestCase
  setup do
    @source = sources(:rails_github)
    @github_service = GitHubService.new(@source)
    
    @issue_data = {
      'number' => 123,
      'title' => 'Test Issue',
      'html_url' => 'https://github.com/test/repo/issues/123',
      'user' => { 'login' => 'testuser' },
      'created_at' => '2025-01-14T10:00:00Z',
      'body' => 'Original issue body',
      'labels' => [],
      'comments' => 5,
      'reactions' => { '+1' => 2, '-1' => 0 }
    }
  end

  test "should not create duplicate posts with same external_id" do
    # Create first post
    assert_difference 'Post.count', 1 do
      result = @github_service.create_post_from_issue(@issue_data)
      assert result, "First post should be created"
    end
    
    # Try to create same post again
    assert_no_difference 'Post.count' do
      result = @github_service.create_post_from_issue(@issue_data)
      assert_not result, "Duplicate post should not be created"
    end
    
    # Verify only one post exists
    posts = Post.where(source: @source.name, external_id: '123')
    assert_equal 1, posts.count
  end

  test "should not recreate ignored posts" do
    # Create and ignore a post
    post = Post.create!(
      source: @source.name,
      external_id: '123',
      title: 'Old Title',
      url: 'https://github.com/test/repo/issues/123',
      author: 'olduser',
      posted_at: 1.day.ago,
      status: 'ignored',
      priority_score: 1.0
    )
    
    # Update issue data
    @issue_data['title'] = 'Updated Title'
    @issue_data['comments'] = 10
    
    # Try to create/update
    assert_no_difference 'Post.count' do
      result = @github_service.create_post_from_issue(@issue_data)
      assert_not result, "Should not create new post"
    end
    
    # Verify post wasn't updated
    post.reload
    assert_equal 'ignored', post.status
    assert_equal 'Old Title', post.title
    assert_equal 1.0, post.priority_score
  end

  test "should update read posts when there's new activity" do
    # Create a read post
    post = Post.create!(
      source: @source.name,
      external_id: '123',
      title: 'Old Title',
      url: 'https://github.com/test/repo/issues/123',
      author: 'testuser',
      posted_at: 2.days.ago,
      status: 'read',
      priority_score: 1.0,
      summary: 'Old summary'
    )
    
    # Update issue data with new activity
    @issue_data['title'] = 'Updated Title'
    @issue_data['body'] = 'Updated body with new information'
    @issue_data['comments'] = 15
    
    # Process update
    assert_no_difference 'Post.count' do
      result = @github_service.create_post_from_issue(@issue_data)
      assert_not result, "Should not count as new post"
    end
    
    # Verify post was updated but status preserved
    post.reload
    assert_equal 'read', post.status, "Status should remain 'read'"
    assert_equal 'Updated Title', post.title
    assert_match 'Updated body', post.summary
    assert post.priority_score > 1.0, "Priority score should increase with activity"
  end

  test "should update responded posts when priority increases significantly" do
    # Create a responded post
    post = Post.create!(
      source: @source.name,
      external_id: '123',
      title: 'Test Issue',
      url: 'https://github.com/test/repo/issues/123',
      author: 'testuser',
      posted_at: 2.days.ago,
      status: 'responded',
      priority_score: 2.0
    )
    
    # Add high priority labels
    @issue_data['labels'] = [
      { 'name' => 'bug' },
      { 'name' => 'help wanted' },
      { 'name' => 'good first issue' }
    ]
    @issue_data['comments'] = 20
    
    # Process update
    @github_service.create_post_from_issue(@issue_data)
    
    # Verify post was updated
    post.reload
    assert_equal 'responded', post.status, "Status should remain 'responded'"
    assert post.priority_score > 5.0, "Priority score should be high"
  end

  test "should always update unread posts" do
    # Create an unread post
    post = Post.create!(
      source: @source.name,
      external_id: '123',
      title: 'Old Title',
      url: 'https://github.com/test/repo/issues/123',
      author: 'testuser',
      posted_at: 1.hour.ago,
      status: 'unread',
      priority_score: 1.0
    )
    
    # Update issue data
    @issue_data['title'] = 'Updated Title'
    
    # Process update
    @github_service.create_post_from_issue(@issue_data)
    
    # Verify post was updated
    post.reload
    assert_equal 'unread', post.status
    assert_equal 'Updated Title', post.title
  end

  test "should handle multiple sources with same external_id" do
    # Create posts from different sources with same external_id
    Post.create!(
      source: 'GitHub Issues',
      external_id: '123',
      title: 'GitHub Issue',
      url: 'https://github.com/test/repo/issues/123',
      author: 'github_user',
      posted_at: Time.current,
      status: 'unread'
    )
    
    Post.create!(
      source: 'HuggingFace Forum',
      external_id: '123',
      title: 'Forum Topic',
      url: 'https://discuss.huggingface.co/t/123',
      author: 'forum_user',
      posted_at: Time.current,
      status: 'unread'
    )
    
    # Both should exist
    assert_equal 2, Post.where(external_id: '123').count
    assert_equal 1, Post.where(source: 'GitHub Issues', external_id: '123').count
    assert_equal 1, Post.where(source: 'HuggingFace Forum', external_id: '123').count
  end
end