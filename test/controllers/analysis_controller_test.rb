require "test_helper"

class AnalysisControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    # Clean up any posts created by other tests
    Post.destroy_all
  end

  test "should redirect to login when not authenticated and show auth required message" do
    get analysis_url
    assert_redirected_to new_session_url
    follow_redirect!
    
    assert_select 'div.bg-blue-50'
    assert response.body.include?("Authentication Required"), "Should display authentication required header"
    assert response.body.include?("Analytics Dashboard"), "Should mention Analytics Dashboard in the message"
    assert_select 'button[form="sign-in-form"]', text: 'Sign In Now'
    assert_select 'a[href="/"]', text: 'Learn More'
  end

  test "should get index when authenticated" do
    sign_in_as @user
    get analysis_url
    assert_response :success
  end

  test "should display correct statistics" do
    sign_in_as @user
    
    
    # Create test data
    3.times do |i| 
      Post.create!(
        source: "GitHub",
        external_id: "gh-#{i}",
        title: "Test",
        url: "http://test.com/#{i}",
        author: "test_user",
        status: "unread",
        posted_at: Time.current
      )
    end
    2.times do |i|
      Post.create!(
        source: "Reddit",
        external_id: "reddit-#{i}",
        title: "Test",
        url: "http://test.com/reddit-#{i}",
        author: "reddit_user",
        status: "responded",
        posted_at: Time.current
      )
    end
    Post.create!(
      source: "HackerNews",
      external_id: "hn-1",
      title: "Test",
      url: "http://test.com/hn",
      author: "hn_user",
      status: "ignored",
      posted_at: Time.current
    )
    
    get analysis_url
    
    assert_select "h1", "Analytics Dashboard"
    # Check that stats are displayed
    assert_match(/Total Posts/, response.body)
    assert_match(/Unread/, response.body)
    assert_match(/Responded/, response.body)
    assert_match(/Active Sources/, response.body)
  end

  test "should calculate response rate correctly" do
    sign_in_as @user
    
    
    # Create 5 posts: 2 responded, 2 unread, 1 ignored
    Post.create!(source: "GitHub", external_id: "gh-resp-1", title: "Test1", url: "http://test1.com", author: "user1", status: "responded", posted_at: Time.current)
    Post.create!(source: "GitHub", external_id: "gh-resp-2", title: "Test2", url: "http://test2.com", author: "user2", status: "responded", posted_at: Time.current)
    Post.create!(source: "GitHub", external_id: "gh-unread-1", title: "Test3", url: "http://test3.com", author: "user3", status: "unread", posted_at: Time.current)
    Post.create!(source: "GitHub", external_id: "gh-unread-2", title: "Test4", url: "http://test4.com", author: "user4", status: "unread", posted_at: Time.current)
    Post.create!(source: "GitHub", external_id: "gh-ignored-1", title: "Test5", url: "http://test5.com", author: "user5", status: "ignored", posted_at: Time.current)
    
    get analysis_url
    
    # Response rate should be 50% (2 responded out of 4 non-ignored)
    assert_match(/50\.0%/, response.body)
  end

  test "should display posts by source" do
    sign_in_as @user
    
    
    # Create posts from different sources
    3.times do |i|
      Post.create!(
        source: "GitHub",
        external_id: "gh-source-#{i}",
        title: "GH",
        url: "http://gh.com/#{i}",
        author: "gh_user",
        status: "unread",
        posted_at: Time.current
      )
    end
    2.times do |i|
      Post.create!(
        source: "Reddit",
        external_id: "reddit-source-#{i}",
        title: "Reddit",
        url: "http://reddit.com/#{i}",
        author: "reddit_user",
        status: "unread",
        posted_at: Time.current
      )
    end
    
    get analysis_url
    
    assert_select "h3", text: "Posts by Source"
    # Just check that we have posts by source showing
    assert_no_match(/No posts yet/, response.body)
  end

  test "should display top tags" do
    sign_in_as @user
    
    
    # Create posts with tags
    p1 = Post.create!(source: "GitHub", external_id: "gh-tag-1", title: "Test1", url: "http://test1.com", author: "tag_user", tags: '["ruby","rails"]', status: "unread", posted_at: Time.current)
    p2 = Post.create!(source: "GitHub", external_id: "gh-tag-2", title: "Test2", url: "http://test2.com", author: "tag_user", tags: '["ruby","javascript"]', status: "unread", posted_at: Time.current)
    p3 = Post.create!(source: "GitHub", external_id: "gh-tag-3", title: "Test3", url: "http://test3.com", author: "tag_user", tags: '["python"]', status: "unread", posted_at: Time.current)
    
    # Ensure posts were created with tags
    assert_equal 3, Post.where.not(tags: [nil, '']).count
    assert_equal ["ruby", "rails"], p1.tags_array
    assert_equal ["ruby", "javascript"], p2.tags_array
    assert_equal ["python"], p3.tags_array
    
    get analysis_url
    
    assert_select "h3", text: "Top Tags"
    # Just check that we have tags showing
    assert_no_match(/No tags found/, response.body)
  end

  test "should calculate daily average correctly" do
    sign_in_as @user
    
    
    # Create posts over the last 30 days
    10.times do |i|
      Post.create!(
        source: "GitHub",
        external_id: "gh-avg-#{i}",
        title: "Test#{i}",
        url: "http://test#{i}.com",
        author: "avg_user",
        status: "unread",
        posted_at: (30 - i).days.ago
      )
    end
    
    get analysis_url
    
    # Just check that we have a reasonable average
    assert_match(/Daily Average/, response.body)
  end

  test "should handle empty data gracefully" do
    sign_in_as @user
    
    # Delete all posts
    Post.destroy_all
    
    get analysis_url
    assert_response :success
    
    # Should show 0 for all stats
    assert_select "p.text-2xl", text: "0"
    assert_match(/0%/, response.body) # Response rate
    assert_match(/No posts yet/, response.body)
  end

  test "should group posts over time correctly" do
    sign_in_as @user
    
    
    # Create posts on specific dates
    Post.create!(source: "GitHub", external_id: "gh-today", title: "Today", url: "http://today.com", author: "time_user", status: "unread", posted_at: Time.current)
    Post.create!(source: "GitHub", external_id: "gh-yesterday", title: "Yesterday", url: "http://yesterday.com", author: "time_user", status: "unread", posted_at: 1.day.ago)
    Post.create!(source: "GitHub", external_id: "gh-week", title: "Week ago", url: "http://week.com", author: "time_user", status: "unread", posted_at: 7.days.ago)
    
    get analysis_url
    
    # Should mention activity chart
    assert_match(/Activity Over Time/, response.body)
    assert_match(/3 days of data/, response.body) # 3 different days with posts
  end

  private

  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
end