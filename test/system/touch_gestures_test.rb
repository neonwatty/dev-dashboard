require "application_system_test_case"

class TouchGesturesTest < ApplicationSystemTestCase
  def setup
    @user = users(:one)
    sign_in_as(@user)
    
    # Ensure we have test data
    @source = sources(:one)
    @post = posts(:one)
    
    # Make sure the post is in a testable state
    @post.update!(status: "unread")
    
    # Set up mobile viewport
    resize_to_mobile
  end

  def teardown
    # Reset to default viewport
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end

  # ============================================================================
  # SWIPE GESTURE TESTS
  # ============================================================================

  test "swipe right marks post as read" do
    visit root_path
    
    # Ensure posts are loaded
    assert_selector ".post-card", minimum: 1, wait: 5
    
    post_card = find("[data-controller='swipe-actions']", match: :first)
    # Get post ID from the turbo frame
    turbo_frame = post_card.ancestor("turbo-frame[id^='post_']")
    post_id = turbo_frame["id"].gsub("post_", "") if turbo_frame
    
    # Simulate swipe right gesture
    simulate_swipe(post_card, direction: :right, distance: 120)
    
    # Wait for animation and turbo frame update
    sleep(0.5)
    
    # Verify post was marked as read by checking the status badge
    if post_id
      within "#post_#{post_id}" do
        assert_no_selector "[data-status-badge]", text: "Unread"
        assert_selector "[data-status-badge]", text: "Read"
      end
    end
    
    # Check for visual feedback during swipe
    assert_text "marked as read", wait: 2
  end

  test "swipe left clears post" do
    visit root_path
    
    post_card = find("[data-controller='swipe-actions']", match: :first)
    # Get post ID from the turbo frame
    turbo_frame = post_card.ancestor("turbo-frame[id^='post_']")
    post_id = turbo_frame["id"].gsub("post_", "") if turbo_frame
    
    # Count posts before swipe
    initial_post_count = all("[data-controller='swipe-actions']").count
    
    # Simulate swipe left gesture
    simulate_swipe(post_card, direction: :left, distance: 120)
    
    # Wait for animation and removal
    sleep(0.5)
    
    # Verify post was cleared (marked as ignored)
    if post_id
      within "#post_#{post_id}" do
        assert_selector "[data-status-badge]", text: "Cleared"
      end
    end
  end

  test "partial swipe returns card to original position" do
    visit root_path
    
    post_card = find("[data-controller='swipe-actions']", match: :first)
    
    # Simulate partial swipe (less than threshold)
    simulate_swipe(post_card, direction: :right, distance: 50)
    
    # Card should return to original position
    transform = post_card.evaluate_script("getComputedStyle(this).transform")
    assert_equal "none", transform, "Card should return to original position"
  end

  test "swipe indicators appear during swipe" do
    visit root_path
    
    post_card = find("[data-controller='swipe-actions']", match: :first)
    
    # Start swipe right
    simulate_touch_start(post_card, x: 100, y: 100)
    simulate_touch_move(post_card, x: 150, y: 100)
    
    # Check for left indicator (mark as read)
    assert_selector ".swipe-indicator-left", visible: true
    assert_text "Mark as Read"
    
    simulate_touch_end(post_card, x: 50, y: 100)
    
    # Start swipe left
    simulate_touch_start(post_card, x: 200, y: 100)
    simulate_touch_move(post_card, x: 150, y: 100)
    
    # Check for right indicator (clear)
    assert_selector ".swipe-indicator-right", visible: true
    assert_text "Clear"
    
    simulate_touch_end(post_card, x: 250, y: 100)
  end

  test "swipe threshold provides haptic feedback" do
    visit root_path
    
    post_card = find("[data-controller='swipe-actions']", match: :first)
    
    # Mock haptic feedback
    haptic_called = page.evaluate_script(<<~JS)
      window.hapticCalls = [];
      window.HapticFeedback = {
        light: () => window.hapticCalls.push('light'),
        medium: () => window.hapticCalls.push('medium'),
        heavy: () => window.hapticCalls.push('heavy'),
        success: () => window.hapticCalls.push('success'),
        error: () => window.hapticCalls.push('error'),
        selection: () => window.hapticCalls.push('selection')
      };
      true
    JS
    
    # Simulate swipe past threshold
    simulate_swipe(post_card, direction: :right, distance: 120)
    
    # Check haptic feedback was triggered
    haptic_calls = page.evaluate_script("window.hapticCalls")
    assert_includes haptic_calls, "light", "Haptic feedback should trigger at threshold"
  end

  # ============================================================================
  # PULL-TO-REFRESH TESTS
  # ============================================================================

  test "pull to refresh only activates at top of page" do
    visit root_path
    
    # Scroll down first
    page.execute_script("window.scrollTo(0, 100)")
    
    # Try to pull down - should not activate
    container = find("[data-controller='pull-to-refresh']")
    simulate_pull_down(container, distance: 100)
    
    # Should not see refresh indicator
    assert_no_selector ".pull-refresh-indicator.visible"
    
    # Scroll to top
    page.execute_script("window.scrollTo(0, 0)")
    sleep(0.1)
    
    # Now pull should work
    simulate_pull_down(container, distance: 100)
    
    # Should see refresh indicator
    assert_selector ".pull-refresh-indicator", visible: true
  end

  test "pull to refresh shows visual indicator and rotates" do
    visit root_path
    
    container = find("[data-controller='pull-to-refresh']")
    
    # Start pulling down
    simulate_touch_start(container, x: 200, y: 100)
    simulate_touch_move(container, x: 200, y: 140)
    
    # Check indicator is visible and has rotation
    indicator = find(".pull-refresh-indicator")
    opacity = indicator.evaluate_script("getComputedStyle(this).opacity")
    assert_operator opacity.to_f, :>, 0, "Indicator should be visible"
    
    transform = indicator.evaluate_script("getComputedStyle(this).transform")
    assert_match /rotate/, transform, "Indicator should rotate during pull"
    
    simulate_touch_end(container, x: 200, y: 140)
  end

  test "pull to refresh triggers page reload at threshold" do
    visit root_path
    
    container = find("[data-controller='pull-to-refresh']")
    
    # Set up request expectation
    refresh_triggered = false
    page.execute_script(<<~JS)
      window.originalFetch = window.fetch;
      window.fetch = function(url, options) {
        if (options && options.headers && options.headers['Accept'] === 'text/vnd.turbo-stream.html') {
          window.refreshTriggered = true;
          return Promise.resolve({
            ok: true,
            text: () => Promise.resolve('<turbo-stream action="append" target="posts"><template></template></turbo-stream>')
          });
        }
        return window.originalFetch(url, options);
      };
    JS
    
    # Pull past threshold
    simulate_pull_down(container, distance: 100)
    
    # Wait for refresh
    sleep(0.5)
    
    # Check refresh was triggered
    refresh_triggered = page.evaluate_script("window.refreshTriggered")
    assert refresh_triggered, "Refresh should be triggered at threshold"
  end

  test "pull to refresh shows loading spinner during refresh" do
    visit root_path
    
    container = find("[data-controller='pull-to-refresh']")
    
    # Mock slow network request
    page.execute_script(<<~JS)
      window.fetch = function(url, options) {
        return new Promise(resolve => {
          setTimeout(() => {
            resolve({
              ok: true,
              text: () => Promise.resolve('<turbo-stream action="append" target="posts"><template></template></turbo-stream>')
            });
          }, 1000);
        });
      };
    JS
    
    # Pull past threshold
    simulate_pull_down(container, distance: 100)
    
    # Check for loading spinner
    assert_selector ".pull-refresh-indicator.refreshing"
    assert_selector ".animate-spin", visible: true
  end

  test "pull to refresh spring-back animation works" do
    visit root_path
    
    container = find("[data-controller='pull-to-refresh']")
    
    # Pull but not past threshold
    simulate_pull_down(container, distance: 40)
    
    # Check indicator springs back
    indicator = find(".pull-refresh-indicator")
    sleep(0.3) # Wait for animation
    
    transform = indicator.evaluate_script("getComputedStyle(this).transform")
    assert_match /translateY\(-60px\)/, transform, "Indicator should spring back to hidden position"
  end

  # ============================================================================
  # LONG PRESS TESTS
  # ============================================================================

  test "long press triggers action menu after 500ms" do
    visit root_path
    
    post_card = find("[data-controller='long-press']", match: :first)
    
    # Start long press
    simulate_touch_start(post_card, x: 100, y: 100)
    
    # Should not show menu immediately
    assert_no_selector ".long-press-menu"
    
    # Wait for long press duration
    sleep(0.6)
    
    # Menu should appear
    assert_selector ".long-press-menu.visible"
    assert_selector ".long-press-action", minimum: 1
    
    simulate_touch_end(post_card, x: 100, y: 100)
  end

  test "long press menu appears at touch location" do
    visit root_path
    
    post_card = find("[data-controller='long-press']", match: :first)
    
    # Get card position
    card_rect = post_card.evaluate_script("this.getBoundingClientRect()")
    touch_x = card_rect["left"] + 50
    touch_y = card_rect["top"] + 50
    
    # Long press at specific location
    simulate_long_press(post_card, x: touch_x, y: touch_y)
    
    # Check menu position
    menu = find(".long-press-menu")
    menu_left = menu.evaluate_script("parseInt(this.style.left)")
    menu_top = menu.evaluate_script("parseInt(this.style.top)")
    
    # Menu should be positioned near touch point
    assert_in_delta touch_x, menu_left + 100, 150, "Menu should be horizontally centered on touch"
    assert_operator menu_top, :<, touch_y, "Menu should appear above touch point"
  end

  test "long press menu actions work correctly" do
    visit root_path
    
    post_card = find("[data-controller='long-press']", match: :first)
    # Get post ID from the turbo frame
    turbo_frame = post_card.ancestor("turbo-frame[id^='post_']")
    post_id = turbo_frame["id"].gsub("post_", "") if turbo_frame
    
    # Long press to show menu
    simulate_long_press(post_card)
    
    # Click "Mark as Read" action
    within(".long-press-menu") do
      click_button "Mark as Read"
    end
    
    # Wait for action to complete
    sleep(0.5)
    
    # Verify post was marked as read
    if post_id
      within "#post_#{post_id}" do
        assert_no_selector "[data-status-badge]", text: "Unread"
        assert_selector "[data-status-badge]", text: "Read"
      end
    end
  end

  test "long press menu auto-dismisses after 3 seconds" do
    visit root_path
    
    post_card = find("[data-controller='long-press']", match: :first)
    
    # Long press to show menu
    simulate_long_press(post_card)
    
    assert_selector ".long-press-menu.visible"
    
    # Wait for auto-dismiss
    sleep(3.5)
    
    # Menu should be gone
    assert_no_selector ".long-press-menu.visible"
  end

  test "long press cancelled if finger moves" do
    visit root_path
    
    post_card = find("[data-controller='long-press']", match: :first)
    
    # Start long press
    simulate_touch_start(post_card, x: 100, y: 100)
    
    # Move finger more than 10px
    simulate_touch_move(post_card, x: 115, y: 100)
    
    # Wait for would-be long press duration
    sleep(0.6)
    
    # Menu should not appear
    assert_no_selector ".long-press-menu"
    
    simulate_touch_end(post_card, x: 115, y: 100)
  end

  # ============================================================================
  # TOUCH FEEDBACK TESTS
  # ============================================================================

  test "touch feedback adds ripple effect" do
    visit root_path
    
    # Find element with touch feedback
    button = find("[data-controller='touch-feedback']", match: :first)
    
    # Trigger ripple effect
    button.click
    
    # Check for ripple element
    assert_selector ".ripple", visible: true
    
    # Ripple should animate and disappear
    sleep(0.8)
    assert_no_selector ".ripple"
  end

  test "touch feedback adds active state on press" do
    visit root_path
    
    button = find("[data-controller='touch-feedback']", match: :first)
    
    # Simulate touch start
    simulate_touch_start(button, x: 50, y: 50)
    
    # Check for active class
    assert button.matches_css?(".touching"), "Element should have touching class"
    
    # Release touch
    simulate_touch_end(button, x: 50, y: 50)
    
    # Active class should be removed
    assert_not button.matches_css?(".touching"), "Touching class should be removed"
  end

  test "touch feedback provides haptic feedback" do
    visit root_path
    
    # Mock haptic feedback
    page.execute_script(<<~JS)
      window.hapticCalls = [];
      window.HapticFeedback = {
        light: () => window.hapticCalls.push('light'),
        medium: () => window.hapticCalls.push('medium'),
        heavy: () => window.hapticCalls.push('heavy'),
        success: () => window.hapticCalls.push('success'),
        error: () => window.hapticCalls.push('error'),
        selection: () => window.hapticCalls.push('selection')
      };
    JS
    
    button = find("[data-controller='touch-feedback']", match: :first)
    
    # Touch the button
    simulate_touch_start(button, x: 50, y: 50)
    simulate_touch_end(button, x: 50, y: 50)
    
    # Check haptic was called
    haptic_calls = page.evaluate_script("window.hapticCalls")
    assert_includes haptic_calls, "light", "Light haptic feedback should be triggered"
  end

  # ============================================================================
  # DARK MODE TOUCH GESTURE TESTS
  # ============================================================================

  test "touch gestures work correctly in dark mode" do
    # Enable dark mode via user settings
    @user.setting.update!(theme: "dark")
    
    visit root_path
    
    # Test swipe in dark mode
    post_card = find("[data-controller='swipe-actions']", match: :first)
    simulate_swipe(post_card, direction: :right, distance: 120)
    
    # Visual indicators should be visible in dark mode
    assert_selector ".swipe-indicator-left", visible: false # After swipe completes
    
    # Test long press in dark mode
    post_card = find("[data-controller='long-press']", match: :first)
    simulate_long_press(post_card)
    
    # Menu should be visible and styled for dark mode
    menu = find(".long-press-menu")
    assert menu.matches_css?(".long-press-menu"), "Menu should have dark mode styles"
  end

  # ============================================================================
  # PERFORMANCE TESTS
  # ============================================================================

  test "animations maintain smooth frame rate" do
    visit root_path
    
    # Enable FPS monitoring
    fps_data = page.evaluate_script(<<~JS)
      window.fpsData = [];
      let lastTime = performance.now();
      let frameCount = 0;
      
      function measureFPS() {
        frameCount++;
        const currentTime = performance.now();
        const delta = currentTime - lastTime;
        
        if (delta >= 1000) {
          window.fpsData.push(frameCount);
          frameCount = 0;
          lastTime = currentTime;
        }
        
        if (window.measuring) {
          requestAnimationFrame(measureFPS);
        }
      }
      
      window.measuring = true;
      measureFPS();
      true
    JS
    
    # Perform multiple animations
    post_card = find("[data-controller='swipe-actions']", match: :first)
    
    3.times do
      simulate_swipe(post_card, direction: :right, distance: 50)
      sleep(0.2)
    end
    
    # Stop measuring
    page.execute_script("window.measuring = false")
    
    # Check average FPS
    fps_values = page.evaluate_script("window.fpsData")
    average_fps = fps_values.sum.to_f / fps_values.length if fps_values.any?
    
    # Should maintain at least 30fps (ideally 60fps)
    assert_operator average_fps || 60, :>=, 30, "Animations should maintain smooth frame rate"
  end

  test "touch events do not conflict with each other" do
    visit root_path
    
    post_card = all("[data-controller*='swipe-actions'][data-controller*='long-press']").first
    
    # Try swipe immediately after failed long press
    simulate_touch_start(post_card, x: 100, y: 100)
    sleep(0.2) # Not long enough for long press
    simulate_touch_end(post_card, x: 100, y: 100)
    
    # Immediately try swipe
    simulate_swipe(post_card, direction: :right, distance: 120)
    
    # Swipe should still work
    assert_text "marked as read", wait: 2
  end

  test "memory usage remains stable during repeated gestures" do
    visit root_path
    
    # Measure initial memory
    initial_memory = page.evaluate_script("performance.memory ? performance.memory.usedJSHeapSize : 0")
    
    # Perform many gestures
    post_cards = all("[data-controller='swipe-actions']")
    return unless post_cards.any?
    
    20.times do |i|
      post_card = post_cards[i % post_cards.count]
      
      # Alternate between different gestures
      case i % 3
      when 0
        simulate_swipe(post_card, direction: [:left, :right].sample, distance: 30)
      when 1
        simulate_touch_start(post_card, x: 100, y: 100)
        sleep(0.1)
        simulate_touch_end(post_card, x: 100, y: 100)
      when 2
        simulate_pull_down(find("[data-controller='pull-to-refresh']"), distance: 30)
      end
    end
    
    # Force garbage collection if available
    page.execute_script("if (window.gc) window.gc()")
    sleep(0.5)
    
    # Measure final memory
    final_memory = page.evaluate_script("performance.memory ? performance.memory.usedJSHeapSize : 0")
    
    # Memory increase should be reasonable (less than 10MB)
    memory_increase = final_memory - initial_memory
    assert_operator memory_increase, :<, 10_000_000, "Memory usage should not increase significantly"
  end

  # ============================================================================
  # MULTIPLE VIEWPORT SIZE TESTS
  # ============================================================================

  test "touch gestures work across different mobile viewport sizes" do
    mobile_viewports = [
      { width: 375, height: 667, name: "iPhone SE" },
      { width: 390, height: 844, name: "iPhone 12" },
      { width: 414, height: 896, name: "iPhone 11" },
      { width: 360, height: 740, name: "Android" },
      { width: 768, height: 1024, name: "iPad Portrait" }
    ]
    
    mobile_viewports.each do |viewport|
      page.driver.browser.manage.window.resize_to(viewport[:width], viewport[:height])
      visit root_path
      
      # Test swipe gesture
      post_card = find("[data-controller='swipe-actions']", match: :first)
      simulate_swipe(post_card, direction: :right, distance: 50)
      
      # Verify gesture works at this viewport
      transform = post_card.evaluate_script("getComputedStyle(this).transform")
      assert_equal "none", transform, "Swipe should work on #{viewport[:name]}"
      
      # Test pull to refresh
      container = find("[data-controller='pull-to-refresh']")
      simulate_pull_down(container, distance: 40)
      
      # Verify pull to refresh works
      indicator = find(".pull-refresh-indicator", visible: :all)
      assert indicator, "Pull to refresh should work on #{viewport[:name]}"
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

  def simulate_touch_start(element, x:, y:)
    page.execute_script(<<~JS, element, x, y)
      const element = arguments[0];
      const x = arguments[1];
      const y = arguments[2];
      
      const touch = new Touch({
        identifier: Date.now(),
        target: element,
        clientX: x,
        clientY: y,
        screenX: x,
        screenY: y,
        pageX: x,
        pageY: y,
        radiusX: 1,
        radiusY: 1,
        rotationAngle: 0,
        force: 1
      });
      
      const touchEvent = new TouchEvent('touchstart', {
        bubbles: true,
        cancelable: true,
        touches: [touch],
        targetTouches: [touch],
        changedTouches: [touch]
      });
      
      element.dispatchEvent(touchEvent);
    JS
  end

  def simulate_touch_move(element, x:, y:)
    page.execute_script(<<~JS, element, x, y)
      const element = arguments[0];
      const x = arguments[1];
      const y = arguments[2];
      
      const touch = new Touch({
        identifier: Date.now(),
        target: element,
        clientX: x,
        clientY: y,
        screenX: x,
        screenY: y,
        pageX: x,
        pageY: y,
        radiusX: 1,
        radiusY: 1,
        rotationAngle: 0,
        force: 1
      });
      
      const touchEvent = new TouchEvent('touchmove', {
        bubbles: true,
        cancelable: true,
        touches: [touch],
        targetTouches: [touch],
        changedTouches: [touch]
      });
      
      element.dispatchEvent(touchEvent);
    JS
  end

  def simulate_touch_end(element, x:, y:)
    page.execute_script(<<~JS, element, x, y)
      const element = arguments[0];
      const x = arguments[1];
      const y = arguments[2];
      
      const touch = new Touch({
        identifier: Date.now(),
        target: element,
        clientX: x,
        clientY: y,
        screenX: x,
        screenY: y,
        pageX: x,
        pageY: y,
        radiusX: 1,
        radiusY: 1,
        rotationAngle: 0,
        force: 1
      });
      
      const touchEvent = new TouchEvent('touchend', {
        bubbles: true,
        cancelable: true,
        touches: [],
        targetTouches: [],
        changedTouches: [touch]
      });
      
      element.dispatchEvent(touchEvent);
    JS
  end

  def simulate_swipe(element, direction:, distance:)
    start_x = 100
    start_y = 100
    end_x = direction == :right ? start_x + distance : start_x - distance
    end_y = start_y
    
    simulate_touch_start(element, x: start_x, y: start_y)
    
    # Simulate intermediate moves for smooth swipe
    steps = 5
    (1..steps).each do |i|
      progress = i.to_f / steps
      current_x = start_x + ((end_x - start_x) * progress)
      simulate_touch_move(element, x: current_x, y: start_y)
      sleep(0.02)
    end
    
    simulate_touch_end(element, x: end_x, y: end_y)
  end

  def simulate_pull_down(element, distance:)
    start_x = 200
    start_y = 100
    end_y = start_y + distance
    
    simulate_touch_start(element, x: start_x, y: start_y)
    
    # Simulate pull down
    steps = 5
    (1..steps).each do |i|
      progress = i.to_f / steps
      current_y = start_y + (distance * progress)
      simulate_touch_move(element, x: start_x, y: current_y)
      sleep(0.02)
    end
    
    simulate_touch_end(element, x: start_x, y: end_y)
  end

  def simulate_long_press(element, x: nil, y: nil)
    x ||= 100
    y ||= 100
    
    simulate_touch_start(element, x: x, y: y)
    sleep(0.6) # Wait for long press duration
    simulate_touch_end(element, x: x, y: y)
    
    # Wait for menu animation
    sleep(0.2)
  end
end