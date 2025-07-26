require "test_helper"

class CleanupOldPostsJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    @user2 = users(:two)
    
    # Create or update user settings with different retention days
    @user.user_setting&.destroy
    @user2.user_setting&.destroy
    @user.create_user_setting!(post_retention_days: 7)
    @user2.create_user_setting!(post_retention_days: 30)
  end
  
  test "deletes posts older than the most generous retention setting" do
    # Create posts of different ages
    very_old_post = Post.create!(
      source: "Test",
      external_id: "old-1",
      title: "Very Old Post",
      url: "http://example.com/old",
      author: "tester",
      status: "unread",
      posted_at: 40.days.ago
    )
    
    medium_old_post = Post.create!(
      source: "Test",
      external_id: "medium-1",
      title: "Medium Old Post",
      url: "http://example.com/medium",
      author: "tester",
      status: "unread",
      posted_at: 20.days.ago
    )
    
    recent_post = Post.create!(
      source: "Test",
      external_id: "recent-1",
      title: "Recent Post",
      url: "http://example.com/recent",
      author: "tester",
      status: "unread",
      posted_at: 5.days.ago
    )
    
    # Run the job
    CleanupOldPostsJob.perform_now
    
    # Very old post should be deleted (older than 30 days)
    assert_not Post.exists?(very_old_post.id)
    
    # Medium old and recent posts should still exist
    assert Post.exists?(medium_old_post.id)
    assert Post.exists?(recent_post.id)
  end
  
  test "uses default retention days when no user settings exist" do
    # Delete all user settings
    UserSetting.destroy_all
    
    old_post = Post.create!(
      source: "Test",
      external_id: "old-2",
      title: "Old Post",
      url: "http://example.com/old2",
      author: "tester",
      status: "unread",
      posted_at: 35.days.ago
    )
    
    recent_post = Post.create!(
      source: "Test",
      external_id: "recent-2",
      title: "Recent Post",
      url: "http://example.com/recent2",
      author: "tester",
      status: "unread",
      posted_at: 25.days.ago
    )
    
    # Run the job
    CleanupOldPostsJob.perform_now
    
    # Old post should be deleted (older than default 30 days)
    assert_not Post.exists?(old_post.id)
    
    # Recent post should still exist
    assert Post.exists?(recent_post.id)
  end
  
  test "deletes old posts successfully" do
    # Create an old post
    old_post = Post.create!(
      source: "Test",
      external_id: "old-3",
      title: "Old Post to Delete",
      url: "http://example.com/old3",
      author: "tester",
      status: "unread",
      posted_at: 35.days.ago
    )
    
    # Run the job
    assert_difference "Post.count", -1 do
      CleanupOldPostsJob.perform_now
    end
    
    # Verify the old post was deleted
    assert_not Post.exists?(old_post.id)
  end
  
  test "handles empty result set gracefully" do
    # Create only recent posts
    Post.create!(
      source: "Test",
      external_id: "recent-3",
      title: "Recent Post",
      url: "http://example.com/recent3",
      author: "tester",
      status: "unread",
      posted_at: 1.day.ago
    )
    
    # Should not raise any errors
    assert_nothing_raised do
      CleanupOldPostsJob.perform_now
    end
  end
end
