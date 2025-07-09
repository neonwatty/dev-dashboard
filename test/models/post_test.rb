require "test_helper"

class PostTest < ActiveSupport::TestCase
  # Validation tests
  test "should be valid with valid attributes" do
    post = posts(:huggingface_post)
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
    post = posts(:huggingface_post)
    post.external_id = nil
    assert_not post.valid?
    assert_includes post.errors[:external_id], "can't be blank"
  end

  test "should require title" do
    post = posts(:huggingface_post)
    post.title = nil
    assert_not post.valid?
    assert_includes post.errors[:title], "can't be blank"
  end

  test "should require valid url" do
    post = posts(:huggingface_post)
    post.url = "invalid-url"
    assert_not post.valid?
    assert_includes post.errors[:url], "is invalid"
  end

  test "should require unique external_id per source" do
    existing_post = posts(:huggingface_post)
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
    existing_post = posts(:huggingface_post)
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
    post = posts(:huggingface_post)
    
    ['unread', 'read', 'ignored', 'responded'].each do |status|
      post.status = status
      assert post.valid?, "Should accept status: #{status}"
    end
  end

  test "should reject invalid status" do
    post = posts(:huggingface_post)
    assert_raises(ArgumentError) do
      post.status = 'invalid_status'
    end
  end

  # Scope tests
  test "by_source scope should filter correctly" do
    github_posts = Post.by_source('github')
    assert_equal 2, github_posts.count
    github_posts.each do |post|
      assert_equal 'github', post.source
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
    post = posts(:huggingface_post)
    expected_tags = ["transformers", "fine-tuning", "tutorial"]
    assert_equal expected_tags, post.tags_array
  end

  test "tags_array should return empty array for blank tags" do
    post = posts(:huggingface_post)
    post.tags = nil
    assert_equal [], post.tags_array
    
    post.tags = ""
    assert_equal [], post.tags_array
  end

  test "tags_array= should set JSON tags" do
    post = posts(:huggingface_post)
    new_tags = ["ruby", "rails", "testing"]
    post.tags_array = new_tags
    assert_equal new_tags.to_json, post.tags
    assert_equal new_tags, post.tags_array
  end

  test "tags_array should handle invalid JSON gracefully" do
    post = posts(:huggingface_post)
    post.tags = "invalid json"
    assert_equal [], post.tags_array
  end

  # Edge cases
  test "should handle very long titles" do
    post = posts(:huggingface_post)
    long_title = "a" * 1000
    post.title = long_title
    assert post.valid?  # Should be valid but may be truncated by DB
  end

  test "should handle nil priority_score" do
    post = posts(:huggingface_post)
    post.priority_score = nil
    assert post.valid?
  end

  test "should handle negative priority_score" do
    post = posts(:huggingface_post)
    post.priority_score = -5.0
    assert post.valid?
  end
end
