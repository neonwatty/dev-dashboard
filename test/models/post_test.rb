require "test_helper"

class PostTest < ActiveSupport::TestCase
  # Validation tests
  test "should be valid with valid attributes" do
    post = posts(:one)
    assert post.valid?
  end

  test "should require source" do
    post = Post.new(
      external_id: "123",
      title: "Test Post", 
      url: "https://example.com",
      author: "test_author",
      posted_at: Time.current,
      status: "unread"
    )
    assert_not post.valid?
    assert_includes post.errors[:source], "can't be blank"
  end

  test "should require external_id" do
    post = posts(:one)
    post.external_id = nil
    assert_not post.valid?
    assert_includes post.errors[:external_id], "can't be blank"
  end

  test "should require title" do
    post = posts(:one)
    post.title = nil
    assert_not post.valid?
    assert_includes post.errors[:title], "can't be blank"
  end

  test "should require valid url" do
    post = posts(:one)
    post.url = "invalid-url"
    assert_not post.valid?
    assert_includes post.errors[:url], "is invalid"
  end

  test "should require unique external_id per source" do
    existing_post = posts(:one)
    duplicate_post = Post.new(
      source: existing_post.source,
      external_id: existing_post.external_id,
      title: "Different Title",
      url: "https://example.com/different",
      author: "different_author",
      posted_at: Time.current,
      status: "unread"
    )
    assert_not duplicate_post.valid?
    assert_includes duplicate_post.errors[:external_id], "has already been taken"
  end

  test "should allow same external_id for different sources" do
    existing_post = posts(:one)
    different_source_post = Post.new(
      source: "github",  # Different source
      external_id: existing_post.external_id,  # Same external_id
      title: "Different Title",
      url: "https://example.com/different",
      author: "different_author",
      posted_at: Time.current,
      status: "unread"
    )
    assert different_source_post.valid?
  end

  # Status enum tests
  test "should have valid status enum values" do
    post = posts(:one)
    
    ['unread', 'read', 'ignored', 'responded'].each do |status|
      post.status = status
      assert post.valid?, "Should accept status: #{status}"
    end
  end

  test "should reject invalid status" do
    post = posts(:one)
    assert_raises(ArgumentError) do
      post.status = 'invalid_status'
    end
  end

  # Scope tests
  test "by_source scope should filter correctly" do
    rails_github_posts = Post.by_source('rails_github') 
    assert_equal 2, rails_github_posts.count
    rails_github_posts.each do |post|
      assert_equal 'rails_github', post.source
    end
  end

  test "by_priority scope should order by priority_score desc" do
    posts = Post.by_priority.limit(3)
    priorities = posts.map(&:priority_score)
    assert_equal priorities.sort.reverse, priorities
  end

  test "recent scope should order by posted_at desc" do
    posts = Post.recent.limit(3)
    dates = posts.map(&:posted_at)
    assert_equal dates.sort.reverse, dates
  end

  # Tags array methods
  test "tags_array should parse JSON tags" do
    post = posts(:one)
    expected_tags = ["transformers", "fine-tuning", "tutorial"]
    assert_equal expected_tags, post.tags_array
  end

  test "tags_array should return empty array for blank tags" do
    post = posts(:one)
    post.tags = nil
    assert_equal [], post.tags_array
    
    post.tags = ""
    assert_equal [], post.tags_array
  end

  test "tags_array= should set JSON tags" do
    post = posts(:one)
    new_tags = ["ruby", "rails", "testing"]
    post.tags_array = new_tags
    assert_equal new_tags.to_json, post.tags
    assert_equal new_tags, post.tags_array
  end

  test "tags_array should handle invalid JSON gracefully" do
    post = posts(:one)
    post.tags = "invalid json"
    assert_equal [], post.tags_array
  end

  # Edge cases
  test "should handle very long titles" do
    post = posts(:one)
    long_title = "a" * 1000
    post.title = long_title
    assert post.valid?  # Should be valid but may be truncated by DB
  end

  test "should handle nil priority_score" do
    post = posts(:one)
    post.priority_score = nil
    assert post.valid?
  end

  test "should handle negative priority_score" do
    post = posts(:one)
    post.priority_score = -5.0
    assert post.valid?
  end
  
  # Expiration tests
  test "expired_for_user scope should return posts older than user retention days" do
    user = users(:one)
    user.user_setting&.destroy
    user.create_user_setting(post_retention_days: 7)
    
    # Create posts of different ages
    old_post = Post.create!(
      source: "Test",
      external_id: "old-test",
      title: "Old Post",
      url: "http://example.com/old",
      author: "tester",
      status: "unread",
      posted_at: 10.days.ago
    )
    
    recent_post = Post.create!(
      source: "Test",
      external_id: "recent-test",
      title: "Recent Post",
      url: "http://example.com/recent",
      author: "tester",
      status: "unread",
      posted_at: 5.days.ago
    )
    
    expired_posts = Post.expired_for_user(user)
    assert_includes expired_posts, old_post
    assert_not_includes expired_posts, recent_post
  end
  
  test "not_expired_for_user scope should return posts within user retention days" do
    user = users(:one)
    user.user_setting&.destroy
    user.create_user_setting(post_retention_days: 7)
    
    # Create posts of different ages
    old_post = Post.create!(
      source: "Test",
      external_id: "old-test2",
      title: "Old Post",
      url: "http://example.com/old2",
      author: "tester",
      status: "unread",
      posted_at: 10.days.ago
    )
    
    recent_post = Post.create!(
      source: "Test",
      external_id: "recent-test2",
      title: "Recent Post",
      url: "http://example.com/recent2",
      author: "tester",
      status: "unread",
      posted_at: 5.days.ago
    )
    
    active_posts = Post.not_expired_for_user(user)
    assert_not_includes active_posts, old_post
    assert_includes active_posts, recent_post
  end
  
  test "expired_for? should return true for posts older than retention days" do
    user = users(:one)
    user.user_setting&.destroy
    user.create_user_setting(post_retention_days: 7)
    
    old_post = Post.create!(
      source: "Test",
      external_id: "expired-check",
      title: "Old Post",
      url: "http://example.com/expired",
      author: "tester",
      status: "unread",
      posted_at: 10.days.ago
    )
    
    assert old_post.expired_for?(user)
  end
  
  test "expired_for? should return false for posts within retention days" do
    user = users(:one)
    user.user_setting&.destroy
    user.create_user_setting(post_retention_days: 7)
    
    recent_post = Post.create!(
      source: "Test",
      external_id: "not-expired-check",
      title: "Recent Post",
      url: "http://example.com/notexpired",
      author: "tester",
      status: "unread",
      posted_at: 5.days.ago
    )
    
    assert_not recent_post.expired_for?(user)
  end
  
  test "expired_for? should return false when user is nil" do
    post = posts(:one)
    assert_not post.expired_for?(nil)
  end
  
  test "days_until_expiry_for should calculate remaining days correctly" do
    user = users(:one)
    user.user_setting&.destroy
    user.create_user_setting(post_retention_days: 7)
    
    post = Post.create!(
      source: "Test",
      external_id: "expiry-calc",
      title: "Test Post",
      url: "http://example.com/expiry",
      author: "tester",
      status: "unread",
      posted_at: 5.days.ago
    )
    
    # Post is 5 days old, retention is 7 days, so 2 days remaining
    assert_equal 2, post.days_until_expiry_for(user)
  end
  
  test "days_until_expiry_for should return negative for expired posts" do
    user = users(:one)
    user.user_setting&.destroy
    user.create_user_setting(post_retention_days: 7)
    
    post = Post.create!(
      source: "Test",
      external_id: "expired-calc",
      title: "Old Post",
      url: "http://example.com/expired-calc",
      author: "tester",
      status: "unread",
      posted_at: 10.days.ago
    )
    
    # Post is 10 days old, retention is 7 days, so -3 days (expired 3 days ago)
    assert_equal -3, post.days_until_expiry_for(user)
  end
  
  test "days_until_expiry_for should return nil when user is nil" do
    post = posts(:one)
    assert_nil post.days_until_expiry_for(nil)
  end
end
