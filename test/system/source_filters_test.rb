require "application_system_test_case"

class SourceFiltersTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    sign_in_as @user
    
    # Create test sources
    @github_source = Source.create!(
      name: "GitHub Issues",
      source_type: "github",
      url: "https://github.com/test/repo",
      active: true,
      auto_fetch_enabled: false
    )
    
    @hf_source = Source.create!(
      name: "HuggingFace Forum",
      source_type: "discourse",
      url: "https://huggingface.co/forums",
      active: true,
      auto_fetch_enabled: false
    )
    
    @reddit_source = Source.create!(
      name: "Reddit",
      source_type: "reddit",
      url: "https://reddit.com/r/test",
      active: true,
      auto_fetch_enabled: false
    )
    
    # Create test posts
    @github_post = Post.create!(
      source: @github_source.name,
      external_id: "github_1",
      title: "GitHub Issue Post",
      url: "https://github.com/test/repo/issues/1",
      author: "github_user",
      status: "unread",
      posted_at: 1.hour.ago
    )
    
    @hf_post = Post.create!(
      source: @hf_source.name,
      external_id: "hf_1",
      title: "HuggingFace Discussion",
      url: "https://huggingface.co/discussions/1",
      author: "hf_user",
      status: "unread",
      posted_at: 2.hours.ago
    )
    
    @reddit_post = Post.create!(
      source: @reddit_source.name,
      external_id: "reddit_1",
      title: "Reddit Post",
      url: "https://reddit.com/r/test/comments/1",
      author: "reddit_user",
      status: "unread",
      posted_at: 3.hours.ago
    )
  end

  test "source filter checkboxes toggle visual state without auto-submit" do
    visit posts_path
    
    # Verify all posts are initially visible
    assert_selector "#post_#{@github_post.id}"
    assert_selector "#post_#{@hf_post.id}"
    assert_selector "#post_#{@reddit_post.id}"
    
    # Find GitHub source checkbox and label
    github_checkbox = find("input[value='#{@github_source.name}']", visible: false)
    github_label = github_checkbox.find(:xpath, "..")
    github_span = github_label.find("span")
    
    # Initially should be unselected (gray)
    assert github_span.matches_css?(".bg-gray-100")
    assert github_span.matches_css?(".text-gray-700")
    refute github_checkbox.checked?
    
    # Click the label to select
    github_label.click
    
    # Should be selected visually (blue) but NO auto-submit
    assert github_span.matches_css?(".bg-blue-600")
    assert github_span.matches_css?(".text-white")
    assert github_checkbox.checked?
    
    # Posts should NOT be filtered yet (all still visible)
    assert_selector "#post_#{@github_post.id}"
    assert_selector "#post_#{@hf_post.id}"
    assert_selector "#post_#{@reddit_post.id}"
    
    # Click again to deselect
    github_label.click
    
    # Should be back to unselected (gray)
    assert github_span.matches_css?(".bg-gray-100")
    assert github_span.matches_css?(".text-gray-700")
    refute github_checkbox.checked?
  end

  test "apply source filter button filters posts without page reload" do
    visit posts_path
    
    # Select GitHub source
    github_checkbox = find("input[value='#{@github_source.name}']", visible: false)
    github_label = github_checkbox.find(:xpath, "..")
    github_label.click
    
    # Verify checkbox is selected
    assert github_checkbox.checked?
    
    # Click "Apply Source Filter" button
    click_button "Apply Source Filter"
    
    # Should show only GitHub posts (filtered via Turbo Frame)
    assert_selector "#post_#{@github_post.id}"
    assert_no_selector "#post_#{@hf_post.id}"
    assert_no_selector "#post_#{@reddit_post.id}"
    
    # Verify URL has been updated with filter parameter
    assert_current_path posts_path
    assert page.current_url.include?("sources%5B%5D=#{CGI.escape(@github_source.name)}")
  end

  test "multiple source selection and filtering" do
    visit posts_path
    
    # Select multiple sources
    github_checkbox = find("input[value='#{@github_source.name}']", visible: false)
    hf_checkbox = find("input[value='#{@hf_source.name}']", visible: false)
    
    github_checkbox.find(:xpath, "..").click
    hf_checkbox.find(:xpath, "..").click
    
    # Verify both are selected
    assert github_checkbox.checked?
    assert hf_checkbox.checked?
    
    # Apply filters
    click_button "Apply Source Filter"
    
    # Should show posts from both sources
    assert_selector "#post_#{@github_post.id}"
    assert_selector "#post_#{@hf_post.id}"
    assert_no_selector "#post_#{@reddit_post.id}"
  end

  test "select all sources button" do
    visit posts_path
    
    # Click "Select All" button
    click_button "Select All"
    
    # All source checkboxes should be checked
    [@github_source, @hf_source, @reddit_source].each do |source|
      checkbox = find("input[value='#{source.name}']", visible: false)
      assert checkbox.checked?
      
      # Visual state should be selected (blue)
      span = checkbox.find(:xpath, "..").find("span")
      assert span.matches_css?(".bg-blue-600")
      assert span.matches_css?(".text-white")
    end
    
    # Apply filters - should show all posts
    click_button "Apply Source Filter"
    
    assert_selector "#post_#{@github_post.id}"
    assert_selector "#post_#{@hf_post.id}"
    assert_selector "#post_#{@reddit_post.id}"
  end

  test "clear all sources button" do
    visit posts_path
    
    # First select some sources
    github_checkbox = find("input[value='#{@github_source.name}']", visible: false)
    hf_checkbox = find("input[value='#{@hf_source.name}']", visible: false)
    
    github_checkbox.find(:xpath, "..").click
    hf_checkbox.find(:xpath, "..").click
    
    # Verify they're selected
    assert github_checkbox.checked?
    assert hf_checkbox.checked?
    
    # Click "Clear All" button
    click_button "Clear All"
    
    # All checkboxes should be unchecked
    [@github_source, @hf_source, @reddit_source].each do |source|
      checkbox = find("input[value='#{source.name}']", visible: false)
      refute checkbox.checked?
      
      # Visual state should be unselected (gray)
      span = checkbox.find(:xpath, "..").find("span")
      assert span.matches_css?(".bg-gray-100")
      assert span.matches_css?(".text-gray-700")
    end
  end

  test "source filters persist after source creation" do
    visit posts_path
    
    # Select GitHub source and apply filter
    github_checkbox = find("input[value='#{@github_source.name}']", visible: false)
    github_checkbox.find(:xpath, "..").click
    click_button "Apply Source Filter"
    
    # Should show only GitHub posts
    assert_selector "#post_#{@github_post.id}"
    assert_no_selector "#post_#{@hf_post.id}"
    
    # Navigate to sources page and create a new source
    visit sources_path
    click_link "Add New Source"
    
    fill_in "Name", with: "New Test Source"
    select "RSS", from: "Source type"
    fill_in "URL", with: "https://example.com/feed"
    click_button "Create Source"
    
    # Go back to posts page
    visit posts_path
    
    # Source filters should still be functional
    # The new source should appear in the filter options
    assert_selector "input[value='New Test Source']", visible: false
    
    # GitHub filter should still work
    github_checkbox = find("input[value='#{@github_source.name}']", visible: false)
    github_checkbox.find(:xpath, "..").click
    click_button "Apply Source Filter"
    
    assert_selector "#post_#{@github_post.id}"
    assert_no_selector "#post_#{@hf_post.id}"
  end

  test "clear sources link works" do
    visit posts_path
    
    # Select a source and apply filter
    github_checkbox = find("input[value='#{@github_source.name}']", visible: false)
    github_checkbox.find(:xpath, "..").click
    click_button "Apply Source Filter"
    
    # Should show filtered results
    assert_selector "#post_#{@github_post.id}"
    assert_no_selector "#post_#{@hf_post.id}"
    
    # Clear Sources link should be visible
    assert_selector "a", text: "Clear Sources"
    
    # Click it
    click_link "Clear Sources"
    
    # Should show all posts again
    assert_selector "#post_#{@github_post.id}"
    assert_selector "#post_#{@hf_post.id}"
    assert_selector "#post_#{@reddit_post.id}"
  end

  test "turbo frame filtering doesn't reload page" do
    visit posts_path
    
    # Get initial page title and URL
    initial_title = page.title
    initial_url = page.current_url
    
    # Select source and apply filter
    github_checkbox = find("input[value='#{@github_source.name}']", visible: false)
    github_checkbox.find(:xpath, "..").click
    click_button "Apply Source Filter"
    
    # Page should not have fully reloaded
    # Title should be the same (indicating no full page reload)
    assert_equal initial_title, page.title
    
    # But URL should be updated with filter params
    refute_equal initial_url, page.current_url
    assert page.current_url.include?("sources%5B%5D=")
    
    # Content should be filtered
    assert_selector "#post_#{@github_post.id}"
    assert_no_selector "#post_#{@hf_post.id}"
  end

  private

  def sign_in_as(user)
    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: "password"
    click_button "Sign in"
    
    # Wait for redirect to complete
    assert_current_path posts_path
  end
end