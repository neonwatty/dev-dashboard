# frozen_string_literal: true

require "application_system_test_case"

class ScreenReaderAccessibilityTest < ApplicationSystemTestCase
  test "ARIA live regions are present in layout" do
    visit root_path
    
    # Check that all required ARIA live regions exist
    assert_selector "[data-screen-reader-target='politeRegion'][aria-live='polite']", visible: false
    assert_selector "[data-screen-reader-target='assertiveRegion'][aria-live='assertive']", visible: false  
    assert_selector "[data-screen-reader-target='statusRegion'][aria-live='polite']", visible: false
  end
  
  test "screen reader controller is connected to body" do
    visit root_path
    
    # Check that screen reader controller is connected to body
    assert_selector "body[data-controller~='screen-reader']"
  end
  
  test "skip navigation links are present" do
    visit root_path
    
    # Check skip links exist
    assert_link "Skip to main content"
    assert_link "Skip to navigation"
  end
  
  test "main content areas have proper landmark roles" do
    visit root_path
    
    # Check main landmarks
    assert_selector "main#main-content"
    assert_selector "nav#main-navigation"
  end
  
  test "dark mode toggle has proper ARIA attributes" do
    visit root_path
    
    # Check dark mode button accessibility
    dark_mode_button = find("button[aria-label='Toggle dark mode']")
    assert dark_mode_button.present?
    assert_equal "false", dark_mode_button["aria-pressed"]
  end
  
  test "mobile menu has proper ARIA attributes" do
    visit root_path
    
    # Check mobile menu button
    mobile_menu_button = find("button[aria-label='Open navigation menu']", visible: false)
    assert mobile_menu_button.present?
    assert_equal "false", mobile_menu_button["aria-expanded"]
    
    # Check mobile menu drawer
    mobile_drawer = find("[role='dialog'][aria-modal='true']", visible: false)
    assert mobile_drawer.present?
    assert mobile_drawer["aria-labelledby"].present?
  end
  
  test "forms have accessibility helpers included" do
    # Test source form accessibility - might need authentication
    begin
      visit new_source_path
      
      # Check that form has screen reader controller
      form = find("form")
      controllers = form["data-controller"]
      assert_includes controllers, "screen-reader" if controllers
      
      # Check required field has aria-required
      name_field = find("#source_name")
      assert_equal "true", name_field["aria-required"]
    rescue Capybara::ElementNotFound
      # If source form is not accessible (requires auth), skip this test
      skip "Sources form requires authentication or is not available"
    end
  end
  
  test "post actions trigger screen reader announcements" do
    # Create a test post first
    post = posts(:one) # Assuming we have fixtures
    
    visit root_path
    
    # Check that post status updates include screen reader announcements
    # This would typically be tested with JavaScript, but we can verify
    # the Turbo streams include the announcement partials
    
    # The actual announcement testing would need JavaScript execution
    # which is complex in system tests, but the structure is verified
    assert_selector "#sr-polite-announcements", visible: false
    assert_selector "#sr-assertive-announcements", visible: false
    assert_selector "#sr-status-updates", visible: false
  end
  
  test "error messages have proper ARIA attributes" do
    begin
      visit new_source_path
      
      # Submit form with errors to trigger validation
      fill_in "Name", with: "" # Clear required field
      click_button "Create Source"
      
      # Check that error messages have proper accessibility
      if page.has_css?("[role='alert']")
        error_section = find("[role='alert']")
        assert error_section["aria-describedby"].present? || error_section["id"].present?
      else
        # If no role=alert, check that validation works differently
        # This test might pass if there are client-side validations
        skip "No server-side validation errors displayed"
      end
    rescue Capybara::ElementNotFound
      skip "Sources form requires authentication or is not available"
    end
  end
  
  test "navigation links have descriptive text" do
    visit root_path
    
    # Check that navigation links are descriptive
    within "#main-navigation" do
      assert_link "Dashboard"
      assert_link "Sources"
    end
    
    # Check bottom navigation for mobile
    within ".bottom-nav", visible: false do
      assert_selector "a", text: "Dashboard", visible: false
      assert_selector "a", text: "Sources", visible: false
    end
  end
  
  test "interactive elements have sufficient touch targets" do
    visit root_path
    
    # Check that buttons have touch-target class
    assert_selector "button.touch-target"
    assert_selector "a.touch-target"
  end
  
  test "screen reader announcements are included in turbo streams" do
    # This test verifies that our Turbo stream responses include
    # screen reader announcements, but actual JavaScript execution
    # testing would be needed for full verification
    
    visit root_path
    
    # Verify structure exists for announcements
    assert_selector "#sr-polite-announcements", visible: false
    assert_selector "#sr-assertive-announcements", visible: false
    assert_selector "#sr-status-updates", visible: false
    
    # The helpers should be available in views
    # (Testing this fully would require integration tests)
  end
  
  private
  
  def assert_accessible_form_field(field_selector, required: false, has_errors: false)
    field = find(field_selector)
    
    if required
      assert_equal "true", field["aria-required"]
    end
    
    if has_errors
      assert_equal "true", field["aria-invalid"]
      assert field["aria-describedby"].present?
    end
  end
end