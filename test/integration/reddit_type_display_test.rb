require "test_helper"

class RedditTypeDisplayTest < ActionDispatch::IntegrationTest
  fixtures :sources, :posts, :users
  
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "posts index displays Reddit as source type" do
    # Create a Reddit post
    reddit_source = sources(:machine_learning_reddit)
    post = Post.create!(
      source: 'reddit',
      external_id: 'test_reddit_123',
      title: 'Test Reddit Post',
      author: 'test_user',
      summary: 'This is a test post',
      url: 'https://reddit.com/r/test/comments/123',
      posted_at: Time.current,
      tags: ['reddit', 'test'],
      priority_score: 5.0,
      status: 'unread'
    )
    
    # Visit posts index
    get posts_path
    assert_response :success
    
    # Check that Reddit is displayed (case-insensitive)
    assert_match /Reddit/i, response.body
    # Check for the specific span with orange background
    assert_select "span.bg-orange-500" do |elements|
      assert elements.any? { |e| e.text =~ /Reddit/i }
    end
  end
  
  test "sources index displays reddit as source type" do
    # Reddit source is already in fixtures
    get sources_path
    assert_response :success
    
    # Check that reddit type badge is displayed
    assert_select "span", text: "Reddit"
  end
end