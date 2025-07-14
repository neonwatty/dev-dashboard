require "test_helper"

class AnalysisNavigationTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "analysis link not shown to unauthenticated users" do
    get root_url
    assert_response :success
    
    # Should not see Analysis link in navigation
    assert_select "a[href='#{analysis_path}']", count: 0
  end

  test "analysis link shown to authenticated users" do
    sign_in_as @user
    get root_url
    assert_response :success
    
    # Should see Analysis link in navigation
    assert_select "a[href='#{analysis_path}']", text: "Analysis"
  end

  test "can navigate to analysis from dashboard" do
    sign_in_as @user
    get root_url
    assert_response :success
    
    # Click on Analysis link
    get analysis_url
    assert_response :success
    assert_select "h1", "Analytics Dashboard"
  end

  test "analysis link is highlighted when on analysis page" do
    sign_in_as @user
    get analysis_url
    assert_response :success
    
    # Check that Analysis link has active styling
    assert_select "a.border-blue-500[href='#{analysis_path}']", text: "Analysis"
  end

  test "can navigate back to dashboard from analysis" do
    sign_in_as @user
    get analysis_url
    assert_response :success
    
    # Should have Dashboard link
    assert_select "a[href='#{root_path}']", text: "Dashboard"
    
    # Navigate back
    get root_url
    assert_response :success
    assert_select "h1", "Posts"
  end

  test "stats removed from dashboard view" do
    sign_in_as @user
    get root_url
    assert_response :success
    
    # Should not have stats cards on dashboard anymore
    # Skip gradient check as it might come from other elements
    assert_select "p", text: "Total Posts", count: 0
    assert_select "p", text: "Unread", count: 0
    assert_select "p", text: "Responded", count: 0
    
    # Should have simple header
    assert_select "h1", "Posts"
  end

  test "all stats moved to analysis view" do
    sign_in_as @user
    
    # Create some test data
    Post.create!(
      source: "GitHub",
      external_id: "gh-nav-test",
      title: "Test",
      url: "http://test.com",
      author: "nav_user",
      status: "unread",
      posted_at: Time.current
    )
    Source.create!(name: "Test Source", source_type: "github", url: "http://github.com/test", active: true)
    
    get analysis_url
    assert_response :success
    
    # Should have all the stats that were removed from dashboard
    assert_match(/Total Posts/, response.body)
    assert_match(/Unread/, response.body)
    assert_match(/Responded/, response.body)
    assert_match(/Active Sources/, response.body)
    assert_match(/Response Rate/, response.body)
    assert_match(/Recent Activity/, response.body)
    assert_match(/Daily Average/, response.body)
  end

  private

  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
end