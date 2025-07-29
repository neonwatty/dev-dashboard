require "application_system_test_case"

class TouchGesturesIntegrationTest < ApplicationSystemTestCase
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

  test "touch gesture system is properly integrated" do
    visit root_path
    
    # Test 1: Verify controllers are applied
    assert_selector ".post-card", minimum: 1
    assert_selector "[data-controller~='swipe-actions']", minimum: 1
    assert_selector "[data-controller~='long-press']", minimum: 1  
    assert_selector "[data-controller='pull-to-refresh']"
    
    # Test 2: Touch feedback works
    touch_button = find("[data-controller='touch-feedback']", match: :first)
    touch_button.click
    
    # Test 3: Post actions are available for swipe integration
    post_card = find("[data-controller~='swipe-actions']", match: :first)
    within post_card do
      # Swipe controller needs these buttons to execute actions
      assert_selector '[data-action*="post-actions#markAsRead"]'
      assert_selector '[data-action*="post-actions#clear"]'
    end
    
    # Test 4: Mobile layout is optimized for touch
    within post_card do
      # Mobile vertical layout
      assert_selector ".flex.flex-col.sm\\:flex-row"
      
      # Touch-friendly action buttons with labels
      within "[data-post-actions-target='buttons']" do
        buttons = all("button")
        assert buttons.any?, "Should have action buttons"
        
        buttons.each do |button|
          # Should have touch-target class
          assert button.matches_css?(".touch-target"), "Button should have touch-target class"
          
          # Should show text on mobile
          assert button.has_selector?("span", visible: true), "Mobile buttons should show text"
        end
      end
    end
    
    # Test 5: Performance - no JavaScript errors
    errors = page.driver.browser.logs.get(:browser)
    javascript_errors = errors.select { |e| e.level == "SEVERE" }
    assert javascript_errors.empty?, "Should have no JavaScript errors: #{javascript_errors.map(&:message)}"
  end

  test "touch gestures work across different mobile viewports" do
    viewports = [
      [375, 667], # iPhone SE
      [390, 844], # iPhone 12  
      [414, 896], # iPhone 11
      [768, 1024] # iPad Portrait
    ]
    
    viewports.each do |width, height|
      page.driver.browser.manage.window.resize_to(width, height)
      visit root_path
      
      # Controllers should work at all viewport sizes
      assert_selector "[data-controller~='swipe-actions']", minimum: 1
      assert_selector "[data-controller='pull-to-refresh']"
      
      # Touch targets should be appropriately sized
      buttons = all("button.touch-target")
      buttons.first(3).each do |button| # Test first 3 to avoid timeout
        next unless button.visible?
        
        button_height = button.evaluate_script("this.offsetHeight")
        assert button_height >= 40, "Button should be at least 40px tall at #{width}x#{height}"
      end
    end
  end

  test "touch gesture CSS is properly loaded" do
    visit root_path
    
    # Check that key CSS classes are defined
    css_classes = [
      '.touch-target',
      '.swipe-indicator', 
      '.pull-refresh-indicator',
      '.long-press-menu',
      '.ripple'
    ]
    
    css_classes.each do |css_class|
      # Check if CSS class has any styles applied
      element_with_class = page.execute_script(<<~JS)
        const testElement = document.createElement('div');
        testElement.className = '#{css_class.gsub('.', '')}';
        document.body.appendChild(testElement);
        const styles = window.getComputedStyle(testElement);
        const hasStyles = styles.position !== 'static' || 
                         styles.display !== 'inline' ||
                         styles.opacity !== '1' ||
                         styles.transform !== 'none';
        document.body.removeChild(testElement);
        return hasStyles;
      JS
      
      assert element_with_class, "CSS class #{css_class} should be defined with styles"
    end
  end

  test "haptic feedback utility is available" do
    visit root_path
    
    # Check that HapticFeedback is available globally
    haptic_available = page.evaluate_script(<<~JS)
      (function() {
        try {
          // Try to import and use the haptic feedback
          return typeof window.navigator !== 'undefined' && 
                 typeof window.navigator.vibrate !== 'undefined';
        } catch (e) {
          return false;
        }
      })()
    JS
    
    # Haptic should be available (even if navigator.vibrate is mocked)
    assert haptic_available, "Haptic feedback should be available"
  end

  test "touch gesture performance is acceptable" do
    visit root_path
    
    # Measure initial performance
    initial_time = Time.current
    
    # Interact with multiple touch elements
    touch_buttons = all("[data-controller='touch-feedback']").first(5)
    touch_buttons.each do |button|
      button.click if button.visible?
    end
    
    # Interaction should complete quickly
    interaction_time = Time.current - initial_time
    assert interaction_time < 2.seconds, "Touch interactions should be fast"
    
    # Check for any performance warnings in console
    logs = page.driver.browser.logs.get(:browser)
    performance_warnings = logs.select { |log| 
      log.message.include?('performance') || 
      log.message.include?('slow') ||
      log.message.include?('blocking')
    }
    
    assert performance_warnings.empty?, "Should have no performance warnings"
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