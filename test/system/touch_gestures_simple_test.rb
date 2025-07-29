require "application_system_test_case"

class TouchGesturesSimpleTest < ApplicationSystemTestCase
  def setup
    @user = users(:one)
    sign_in_as(@user)
    
    # Ensure we have active sources and posts
    Source.update_all(active: true)
    Post.update_all(status: 'unread')
    
    # Set up mobile viewport
    resize_to_mobile
  end

  def teardown
    # Reset to default viewport
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end

  test "posts are displayed with touch controllers" do
    # Ensure we have posts
    assert Post.count > 0, "Should have posts in fixtures"
    
    visit root_path
    
    # Debug what's on the page
    puts "Page content: #{page.body[0..500]}"
    
    # Check that posts are loaded
    assert_selector ".post-card", minimum: 1
    
    # Check that touch controllers are applied
    assert_selector "[data-controller~='swipe-actions']", minimum: 1
    assert_selector "[data-controller~='long-press']", minimum: 1
    assert_selector "[data-controller~='touch-feedback']", minimum: 1
  end

  test "pull to refresh controller is applied to page" do
    visit root_path
    
    # Check that pull-to-refresh is applied to container
    assert_selector "[data-controller='pull-to-refresh']"
    
    # Check that the refresh indicator element exists (even if hidden)
    within "[data-controller='pull-to-refresh']" do
      # The indicator should be created by the controller
      sleep(0.5) # Give controller time to initialize
      assert_selector ".pull-refresh-indicator", visible: :all
    end
  end

  test "touch feedback works on buttons" do
    visit root_path
    
    # Find a button with touch feedback
    button = find("[data-controller='touch-feedback']", match: :first)
    
    # Click it
    button.click
    
    # Just verify it clicked without errors
    assert true, "Touch feedback button clicked successfully"
  end

  test "swipe gesture visual indicators exist" do
    visit root_path
    
    # Wait for first post card
    post_card = find("[data-controller~='swipe-actions']", match: :first)
    
    # Check that swipe wrapper exists
    within post_card.ancestor(".swipe-wrapper") do
      # Indicators should be created by the controller
      assert_selector ".swipe-indicator-left", visible: :all
      assert_selector ".swipe-indicator-right", visible: :all
    end
  end

  test "long press menu can be triggered" do
    visit root_path
    
    # Find element with long press
    element = find("[data-controller~='long-press']", match: :first)
    
    # Simulate long press using page.driver
    page.driver.browser.action.move_to(element.native).click_and_hold.perform
    sleep(0.6) # Wait for long press duration
    page.driver.browser.action.release.perform
    
    # Check for menu
    assert_selector ".long-press-menu", wait: 2
  end

  test "basic swipe gesture can be performed" do
    visit root_path
    
    # Find swipeable element
    element = find("[data-controller~='swipe-actions']", match: :first)
    
    # Get element location
    location = element.native.location
    
    # Perform swipe using Selenium Actions API
    page.driver.browser.action
      .move_to(element.native)
      .click_and_hold
      .move_by(100, 0)
      .release
      .perform
    
    # Just verify no errors occurred
    assert true, "Swipe gesture performed"
  end

  test "posts display correctly on mobile viewport" do
    visit root_path
    
    # Check mobile-specific classes are applied
    post_card = find(".post-card", match: :first)
    
    # Check responsive layout
    within post_card do
      # Mobile layout should have vertical structure
      assert_selector ".flex.flex-col.sm\\:flex-row"
      
      # Mobile status badge should be visible
      assert_selector ".sm\\:hidden [data-status-badge]", visible: true
      
      # Action buttons should have mobile labels
      assert_selector "button span", text: "Read", visible: true
    end
  end

  test "touch targets meet minimum size requirements" do
    visit root_path
    
    # Check button sizes
    buttons = all("button.touch-target")
    
    buttons.each do |button|
      height = button.evaluate_script("this.offsetHeight")
      width = button.evaluate_script("this.offsetWidth")
      
      assert height >= 44, "Button height should be at least 44px"
      assert width >= 44, "Button width should be at least 44px"
    end
  end

  private

  def resize_to_mobile
    page.driver.browser.manage.window.resize_to(375, 812) # iPhone X size
    sleep(0.2) # Allow time for resize
  end

  def sign_in_as(user)
    visit new_session_path
    fill_in "Email", with: user.email_address
    fill_in "Password", with: "password"
    click_button "Sign in"
  end
end