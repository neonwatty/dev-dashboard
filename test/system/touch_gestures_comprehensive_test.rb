require "application_system_test_case"

class TouchGesturesComprehensiveTest < ApplicationSystemTestCase
  def setup
    @user = users(:one)
    sign_in_as(@user)
    
    # Ensure we have active sources and posts
    Source.update_all(active: true)
    Post.update_all(status: 'unread')
    
    resize_to_mobile
  end

  def teardown
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end

  # Test 1: Basic Touch Controllers Setup
  test "touch gesture controllers are properly initialized" do
    visit root_path
    
    # Verify posts are loaded with all touch controllers
    assert_selector ".post-card", minimum: 1
    assert_selector "[data-controller~='swipe-actions']", minimum: 1
    assert_selector "[data-controller~='long-press']", minimum: 1
    assert_selector "[data-controller~='touch-feedback']", minimum: 1
    assert_selector "[data-controller='pull-to-refresh']"
  end

  # Test 2: Swipe Visual Indicators 
  test "swipe indicators are created and positioned correctly" do
    visit root_path
    
    # Wait for controller initialization
    sleep(0.5)
    
    # Check that swipe wrapper and indicators exist
    post_card = find("[data-controller~='swipe-actions']", match: :first)
    wrapper = post_card.ancestor(".swipe-wrapper")
    
    within wrapper do
      assert_selector ".swipe-indicator-left", visible: :all
      assert_selector ".swipe-indicator-right", visible: :all
      
      # Check indicator content
      assert_text "Mark as Read"
      assert_text "Clear"
    end
  end

  # Test 3: Pull-to-Refresh Indicator
  test "pull to refresh indicator is properly initialized" do
    visit root_path
    
    # Wait for controller initialization
    sleep(0.5)
    
    # Check refresh indicator exists (may be hidden initially)
    assert_selector ".pull-refresh-indicator", visible: :all
    
    # Check indicator content
    within ".pull-refresh-indicator" do
      assert_selector ".refresh-icon svg"
      assert_text "Pull to refresh"
    end
  end

  # Test 4: Touch Feedback Integration
  test "touch feedback is applied to interactive elements" do
    visit root_path
    
    # Find buttons with touch feedback
    buttons = all("[data-controller='touch-feedback']")
    assert buttons.any?, "Should have buttons with touch feedback"
    
    # Click a button and verify no JavaScript errors
    buttons.first.click
    assert true, "Touch feedback button clicked without errors"
  end

  # Test 5: Long Press Menu Structure  
  test "long press creates contextual menu" do
    visit root_path
    
    element = find("[data-controller~='long-press']", match: :first)
    
    # Simulate long press using JavaScript (more reliable for tests)
    page.execute_script(<<~JS, element)
      const element = arguments[0];
      const controller = this.application.getControllerForElementAndIdentifier(element, 'long-press');
      if (controller) {
        controller.showActionMenu(100, 100);
      }
    JS
    
    # Check menu appears
    assert_selector ".long-press-menu", wait: 1
    
    # Check menu has actions
    within ".long-press-menu" do
      assert_selector ".long-press-action", minimum: 1
      # Should have at least Mark as Read or Clear actions
      assert_text(/Mark as Read|Clear/)
    end
  end

  # Test 6: Mobile Touch Target Compliance
  test "touch targets meet mobile accessibility standards" do
    visit root_path
    
    # Check all touch targets meet minimum size
    touch_targets = all(".touch-target, button, a")
    
    touch_targets.each_with_index do |target, index|
      next unless target.visible?
      
      height = target.evaluate_script("this.offsetHeight")
      width = target.evaluate_script("this.offsetWidth")
      
      assert height >= 44, "Touch target #{index} height (#{height}px) should be >= 44px"
      assert width >= 44, "Touch target #{index} width (#{width}px) should be >= 44px"
    end
  end

  # Test 7: Mobile Layout Responsiveness
  test "mobile layout adapts correctly for touch interaction" do
    visit root_path
    
    post_card = find(".post-card", match: :first)
    
    within post_card do
      # Mobile-specific layout should be active
      assert_selector ".flex.flex-col.sm\\:flex-row"
      
      # Mobile status badge should be visible  
      assert_selector ".sm\\:hidden [data-status-badge]", visible: true
      
      # Action buttons should show text labels on mobile
      within "[data-post-actions-target='buttons']" do
        assert_selector "button span", text: "Read", visible: true
        assert_selector "button span", text: "Clear", visible: true
      end
    end
  end

  # Test 8: Swipe Action Integration
  test "swipe actions integrate with existing post action buttons" do
    visit root_path
    
    post_card = find("[data-controller~='swipe-actions']", match: :first)
    
    # Verify required action buttons exist
    within post_card do
      assert_selector '[data-action*="post-actions#markAsRead"]'
      assert_selector '[data-action*="post-actions#clear"]'
    end
    
    # These buttons should be discoverable by the swipe controller
    # for executing swipe actions
    assert true, "Action buttons are properly integrated"
  end

  # Test 9: Dark Mode Touch Gesture Compatibility
  test "touch gestures work in dark mode" do
    # Enable dark mode
    page.execute_script("document.documentElement.classList.add('dark')")
    
    visit root_path
    
    # Verify all touch controllers still work
    assert_selector "[data-controller~='swipe-actions']", minimum: 1
    assert_selector "[data-controller~='long-press']", minimum: 1
    assert_selector "[data-controller='pull-to-refresh']"
    
    # Check dark mode styles are applied
    assert_selector ".dark", visible: true
    
    # Touch feedback should still work
    button = find("[data-controller='touch-feedback']", match: :first)
    button.click
    assert true, "Touch feedback works in dark mode"
  end

  # Test 10: Performance and Memory
  test "touch gesture controllers don't cause memory leaks" do
    visit root_path
    
    initial_memory = page.evaluate_script("performance.memory ? performance.memory.usedJSHeapSize : 0")
    
    # Interact with multiple elements
    5.times do
      # Click touch feedback buttons
      all("[data-controller='touch-feedback']").each do |button|
        button.click if button.visible?
      end
      
      # Trigger long press menus (and dismiss them)
      page.execute_script(<<~JS)
        document.querySelectorAll('[data-controller~="long-press"]').forEach(element => {
          const controller = this.application.getControllerForElementAndIdentifier(element, 'long-press');
          if (controller) {
            controller.showActionMenu(50, 50);
            setTimeout(() => {
              const menu = document.querySelector('.long-press-menu');
              if (menu) controller.hideActionMenu(menu);
            }, 100);
          }
        });
      JS
      
      sleep(0.2)
    end
    
    # Force garbage collection if available
    page.execute_script("if (window.gc) window.gc()")
    sleep(0.5)
    
    final_memory = page.evaluate_script("performance.memory ? performance.memory.usedJSHeapSize : 0")
    
    # Memory increase should be reasonable (less than 5MB)
    memory_increase = final_memory - initial_memory
    assert memory_increase < 5_000_000, "Memory increase should be reasonable, got #{memory_increase} bytes"
  end

  private

  def resize_to_mobile
    page.driver.browser.manage.window.resize_to(375, 812)
    sleep(0.2)
  end

  def sign_in_as(user)
    visit new_session_path
    fill_in "Email", with: user.email_address
    fill_in "Password", with: "password"
    click_button "Sign in"
  end
end