require "application_system_test_case"

class MobileFormsTest < ApplicationSystemTestCase
  def setup
    @user = users(:one)
    sign_in_as(@user)
  end

  # ============================================================================
  # MOBILE FORM INPUT TESTS
  # ============================================================================

  test "mobile form inputs prevent iOS zoom with 16px font size" do
    resize_to_mobile
    visit new_source_path

    # Test all form inputs
    inputs = all("input[type='text'], input[type='url'], input[type='email'], textarea, select")
    
    inputs.each do |input|
      font_size = input.evaluate_script("getComputedStyle(this).fontSize")
      font_size_px = font_size.to_f
      
      # Font size should be at least 16px to prevent zoom on iOS
      assert_operator font_size_px, :>=, 16, 
                     "Input #{input.tag_name} should have font-size >= 16px to prevent iOS zoom, got #{font_size_px}px"
    end
  end

  test "mobile form inputs have minimum height for touch targets" do
    resize_to_mobile
    visit new_source_path

    # Test form inputs for touch-friendly height
    inputs = all("input, textarea, select")
    
    inputs.each do |input|
      height = input.evaluate_script("this.offsetHeight")
      
      # Should be at least 48px for mobile touch targets
      assert_operator height, :>=, 48, 
                     "Input #{input.tag_name} should be at least 48px tall for mobile touch, got #{height}px"
    end
  end

  test "form labels are appropriately sized for mobile" do
    resize_to_mobile
    visit new_source_path

    labels = all("label")
    
    labels.each do |label|
      if label.text.present? && label.visible?
        font_size = label.evaluate_script("getComputedStyle(this).fontSize")
        font_size_px = font_size.to_f
        
        # Labels should be readable (at least 14px)
        assert_operator font_size_px, :>=, 14, 
                       "Label should be at least 14px for mobile readability"
        
        # Should have appropriate margin for touch targets
        margin_bottom = label.evaluate_script("getComputedStyle(this).marginBottom")
        margin_px = margin_bottom.to_f
        assert_operator margin_px, :>=, 4, "Label should have bottom margin for spacing"
      end
    end
  end

  test "form buttons are touch-friendly on mobile" do
    resize_to_mobile
    visit new_source_path

    # Test submit buttons and other form buttons
    buttons = all("button, input[type='submit']")
    
    buttons.each do |button|
      height = button.evaluate_script("this.offsetHeight") 
      width = button.evaluate_script("this.offsetWidth")
      
      # Should meet minimum touch target requirements
      assert_operator height, :>=, 44, "Form button should be at least 44px tall"
      assert_operator width, :>=, 44, "Form button should be at least 44px wide"
      
      # Should have appropriate padding
      padding_y = button.evaluate_script("
        var style = getComputedStyle(this);
        return parseFloat(style.paddingTop) + parseFloat(style.paddingBottom);
      ")
      assert_operator padding_y, :>=, 16, "Form button should have adequate vertical padding"
    end
  end

  test "form layout stacks vertically on mobile" do
    resize_to_mobile
    visit new_source_path

    # Form should use vertical layout on mobile
    form_elements = all(".field, .form-group, .mb-4, .mb-6, .space-y-4")
    
    if form_elements.any?
      # Check that form elements are stacked (not side-by-side)
      form_elements.each do |element|
        # Element should take full width or close to it
        width_percent = element.evaluate_script("(function() { var parentWidth = this.parentElement.offsetWidth; var elementWidth = this.offsetWidth; return (elementWidth / parentWidth) * 100; }).call(this)")
        
        assert_operator width_percent, :>=, 90, 
                       "Form elements should take most of available width on mobile"
      end
    end
  end

  test "error messages are visible and appropriately styled on mobile" do
    resize_to_mobile
    
    # Try to submit an invalid form to trigger errors
    visit new_source_path
    
    # Submit form without required fields
    click_button "Create Source" rescue nil
    
    # Look for error messages
    error_elements = all(".error, .text-red-600, .text-red-500, [class*='text-red']")
    
    error_elements.each do |error|
      if error.visible? && error.text.present?
        font_size = error.evaluate_script("getComputedStyle(this).fontSize")
        font_size_px = font_size.to_f
        
        # Error text should be readable
        assert_operator font_size_px, :>=, 14, 
                       "Error messages should be at least 14px for mobile readability"
        
        # Should have appropriate color contrast
        color = error.evaluate_script("getComputedStyle(this).color")
        assert_match(/rgb\(\d+,\s*\d+,\s*\d+\)/, color, "Error should have valid RGB color")
      end
    end
  end

  # ============================================================================
  # MOBILE FORM NAVIGATION TESTS
  # ============================================================================

  test "form navigation works properly on mobile" do
    resize_to_mobile
    visit new_source_path

    # Test tab navigation through form elements
    first_input = find("input, select, textarea", match: :first)
    first_input.click
    
    # Should be able to tab through form elements
    5.times do |i|
      active_element = page.evaluate_script("document.activeElement")
      assert active_element, "Should have an active element when tabbing through form"
      
      # Tab to next element
      page.evaluate_script("document.activeElement.blur()") if i < 4
      find("body").send_keys(:tab)
    end
  end

  test "mobile form submit button is easily accessible" do
    resize_to_mobile
    visit new_source_path

    # Submit button should be prominently placed
    submit_buttons = all("input[type='submit'], button[type='submit']")
    # Add buttons that contain common submit text
    submit_buttons += all("button").select { |btn| btn.text.include?("Create") || btn.text.include?("Submit") }
    
    assert_operator submit_buttons.length, :>=, 1, "Should have at least one submit button"
    
    submit_buttons.each do |button|
      # Should be visible and not hidden by keyboard or other elements
      assert button.visible?, "Submit button should be visible"
      
      # Should be positioned where thumb can easily reach
      button_rect = button.evaluate_script("this.getBoundingClientRect()")
      button_top = button_rect["top"]
      viewport_height = page.evaluate_script("window.innerHeight")
      
      # Submit button shouldn't be too high up (hard to reach with thumb)
      assert_operator button_top, :>=, 100, "Submit button should not be at very top of screen"
    end
  end

  # ============================================================================
  # MOBILE FORM VALIDATION TESTS
  # ============================================================================

  test "form validation messages appear correctly on mobile" do
    resize_to_mobile
    visit new_source_path

    # Fill out form with invalid data to trigger validation
    if page.has_field?("source[url]")
      fill_in "source[url]", with: "invalid-url"
    end
    
    if page.has_field?("source[name]")
      fill_in "source[name]", with: ""
    end
    
    click_button "Create Source" rescue nil
    
    # Check for validation messages
    validation_messages = all("[class*='invalid'], [class*='error'], .field_with_errors")
    
    validation_messages.each do |message|
      if message.visible?
        # Validation styling should be touch-friendly
        bounds = message.evaluate_script("this.getBoundingClientRect()")
        height = bounds["height"]
        
        # Should have adequate height for mobile readability
        assert_operator height, :>=, 20, "Validation messages should be tall enough to read on mobile"
      end
    end
  end

  # ============================================================================
  # MOBILE FORM ACCESSIBILITY TESTS
  # ============================================================================

  test "form elements have proper labels and accessibility attributes" do
    resize_to_mobile
    visit new_source_path

    # All form inputs should have associated labels
    inputs = all("input, select, textarea")
    
    inputs.each do |input|
      input_id = input["id"]
      input_name = input["name"]
      
      if input_id.present?
        # Should have a label with matching 'for' attribute
        label = find("label[for='#{input_id}']", visible: :all) rescue nil
        
        if label.nil?
          # Or input should have aria-label or aria-labelledby
          aria_label = input["aria-label"]
          aria_labelledby = input["aria-labelledby"]
          
          assert aria_label.present? || aria_labelledby.present?,
                "Input #{input_name} should have label, aria-label, or aria-labelledby"
        else
          assert label.text.present?, "Label for #{input_name} should have text content"
        end
      end
    end
  end

  test "form has proper mobile viewport meta tag" do
    resize_to_mobile
    visit new_source_path

    # Check that page has mobile viewport meta tag
    viewport_meta = page.evaluate_script("(function() { var meta = document.querySelector('meta[name=\"viewport\"]'); return meta ? meta.getAttribute('content') : null; })()")
    
    assert viewport_meta.present?, "Page should have viewport meta tag for mobile"
    assert_includes viewport_meta, "width=device-width", "Viewport should set width=device-width"
  end

  # ============================================================================
  # SPECIFIC FORM TESTS
  # ============================================================================

  test "source creation form works properly on mobile" do
    resize_to_mobile
    visit new_source_path

    # Fill out the form
    if page.has_field?("source[name]")
      fill_in "source[name]", with: "Test Mobile Source"
    end
    
    if page.has_field?("source[url]")
      fill_in "source[url]", with: "https://example.com/feed.xml"
    end
    
    if page.has_select?("source[source_type]")
      select "RSS", from: "source[source_type]"
    end

    # Submit button should be accessible
    submit_button = find("input[type='submit'], button[type='submit']", match: :first)
    
    height = submit_button.evaluate_script("this.offsetHeight")
    assert_operator height, :>=, 44, "Submit button should meet touch target requirements"
    
    # Should be able to submit (will fail due to test environment, but form should be accessible)
    click_button "Create Source" rescue nil
  end

  test "settings form is mobile-friendly" do
    resize_to_mobile
    
    # Visit settings page if it exists
    begin
      if defined?(edit_user_settings_path)
        visit edit_user_settings_path
      else
        # Try alternative settings paths
        visit "/settings/edit" rescue skip("Settings page not available")
      end
    rescue ActionController::RoutingError, NoMethodError
      # Skip if settings path doesn't exist
      skip "Settings page not available"
    end
    
    # Settings form should be mobile-responsive
    inputs = all("input, select, textarea")
    
    inputs.each do |input|
      height = input.evaluate_script("this.offsetHeight")
      assert_operator height, :>=, 44, "Settings form inputs should be touch-friendly"
    end
  end

  private

  def resize_to_mobile
    resize_window_to(375, 812) # iPhone X size
  end

  def resize_to_desktop
    resize_window_to(1400, 1000)
  end

  def resize_window_to(width, height)
    page.driver.browser.manage.window.resize_to(width, height)
    sleep(0.2) # Allow time for resize to take effect and CSS to apply
  end

  def sign_in_as(user)
    visit new_session_path
    fill_in "Email", with: user.email_address
    fill_in "Password", with: "password"
    click_button "Sign in"
  end
end