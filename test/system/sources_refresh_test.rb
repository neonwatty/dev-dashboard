require "application_system_test_case"

class SourcesRefreshTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @source = sources(:huggingface_forum)
    sign_in_as @user
  end

  test "clicking refresh button shows immediate feedback" do
    visit sources_path
    
    # Find the row containing our source
    within "tr", text: @source.name do
      # Initial status should not be refreshing
      assert_no_selector ".animate-pulse", text: "Refreshing..."
      
      # Click the refresh button
      find("button[title='Refresh']").click
      
      # Should show refreshing status immediately
      assert_selector ".animate-pulse", text: "Refreshing...", wait: 2
    end
    
    # Should show notification
    assert_selector "[data-controller='notification']", text: "refresh job queued"
  end

  test "refresh all button shows confirmation and queues jobs" do
    visit sources_path
    
    # Click refresh all button
    accept_confirm "This will refresh all active sources. Continue?" do
      click_button "Refresh All Active"
    end
    
    # Should show success notification
    assert_text "Queued"
    assert_text "refresh jobs"
  end

  test "status badge updates in real-time without page reload" do
    visit sources_path
    
    initial_status = @source.status
    
    # Simulate a status update (this would normally come from ActionCable)
    @source.update_status_and_broadcast("refreshing...")
    
    # Status should update without page reload
    within "tr", text: @source.name do
      assert_selector ".animate-pulse", text: "Refreshing...", wait: 2
    end
    
    # Simulate completion
    @source.update_status_and_broadcast("ok (5 new)")
    
    within "tr", text: @source.name do
      assert_no_selector ".animate-pulse"
      assert_selector ".bg-green-500", text: "ok (5 new)", wait: 2
    end
  end

  test "error status shows red badge" do
    error_source = sources(:inactive_source)
    error_source.update!(status: "error: connection failed", active: true)
    
    visit sources_path
    
    within "tr", text: error_source.name do
      assert_selector ".bg-red-100.text-red-600", text: "Error"
    end
  end

  test "refresh button is disabled while refreshing" do
    skip "Requires JavaScript driver configuration for disable-with behavior"
  end

  test "notifications auto-dismiss after delay" do
    visit sources_path
    
    within "tr", text: @source.name do
      find("button[title='Refresh']").click
    end
    
    # Notification should appear
    assert_selector "[data-controller='notification']"
    
    # Should auto-dismiss after delay
    assert_no_selector "[data-controller='notification']", wait: 6
  end

  private

  def sign_in_as(user)
    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: "password"
    click_button "Sign in"
  end
end