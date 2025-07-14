require "test_helper"
require_relative "../../app/services/discourse_service"

class DiscourseDuplicateHandlingTest < ActiveSupport::TestCase
  setup do
    @source = sources(:huggingface_forum)
    @discourse_service = DiscourseService.new(@source)
    
    @topic_data = {
      'id' => 456,
      'title' => 'Test Topic',
      'created_at' => '2025-01-14T10:00:00Z',
      'last_posted_at' => '2025-01-14T12:00:00Z',
      'posts_count' => 5,
      'views' => 100,
      'like_count' => 10,
      'category_id' => 1,
      'pinned' => false,
      'tags' => ['transformers', 'help']
    }
  end

  test "should use last_posted_at for activity tracking" do
    # Create initial post
    result = @discourse_service.create_post_from_topic(@topic_data)
    assert result, "Should create new post"
    
    post = Post.find_by(source: @source.name, external_id: '456')
    assert_equal Time.parse('2025-01-14T12:00:00Z'), post.posted_at
  end

  test "should not update ignored forum posts" do
    # Create ignored post
    post = Post.create!(
      source: @source.name,
      external_id: '456',
      title: 'Old Topic',
      url: "#{@source.url}/t/456",
      author: 'olduser',
      posted_at: 1.day.ago,
      status: 'ignored',
      tags: '["old-tag"]'
    )
    
    # Update topic data
    @topic_data['title'] = 'Updated Topic'
    @topic_data['last_posted_at'] = Time.current.iso8601
    @topic_data['posts_count'] = 20
    
    # Try to update
    result = @discourse_service.create_post_from_topic(@topic_data)
    assert_not result, "Should not create new post"
    
    # Verify not updated
    post.reload
    assert_equal 'ignored', post.status
    assert_equal 'Old Topic', post.title
  end

  test "should update read posts when last_posted_at changes" do
    # Create read post
    old_time = 2.days.ago
    post = Post.create!(
      source: @source.name,
      external_id: '456',
      title: 'Test Topic',
      url: "#{@source.url}/t/456",
      author: 'testuser',
      posted_at: old_time,
      status: 'read',
      summary: 'Old summary'
    )
    
    # Update with new activity
    new_time = 1.hour.ago
    @topic_data['last_posted_at'] = new_time.iso8601
    @topic_data['posts_count'] = 15
    
    # Process update
    result = @discourse_service.create_post_from_topic(@topic_data)
    assert_not result, "Should not count as new post"
    
    # Verify updated but status preserved
    post.reload
    assert_equal 'read', post.status
    assert_equal new_time.to_i, post.posted_at.to_i
  end
end