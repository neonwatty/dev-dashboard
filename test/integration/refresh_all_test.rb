require "test_helper"

class RefreshAllTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @source1 = sources(:huggingface_forum)
    @source2 = sources(:pytorch_forum)
    
    # Ensure only these sources are active by deactivating all others
    Source.where.not(id: [@source1.id, @source2.id]).update_all(active: false)
    
    # Make sure our two sources are active
    @source1.update!(active: true)
    @source2.update!(active: true)
  end

  test "refresh all button should be visible when authenticated" do
    sign_in_as(@user)
    
    get posts_path
    assert_response :success
    
    # Check that the refresh all button is present
    assert_select "form[action=?]", refresh_all_sources_path do
      assert_select "button", text: /Refresh All/
    end
  end

  test "refresh all button should work correctly" do
    sign_in_as(@user)
    
    # Reload sources to ensure they have the updated active status
    @source1.reload
    @source2.reload
    
    # Visit the posts page first
    get posts_path
    assert_response :success
    
    # Debug: Check active sources
    active_count = Source.active.count
    assert_equal 2, active_count, "Expected 2 active sources, got #{active_count}"
    
    # Click the refresh all button with job assertions
    assert_enqueued_jobs 2 do
      post refresh_all_sources_path
    end
    
    assert_redirected_to sources_path
    follow_redirect!
    
    # Check flash message
    assert_not_nil flash[:notice], "Flash notice should be set"
    assert_match(/Queued 2 refresh jobs/, flash[:notice])
    
    # Check that sources are marked as refreshing
    @source1.reload
    @source2.reload
    assert_equal 'refreshing...', @source1.status
    assert_equal 'refreshing...', @source2.status
  end

  test "refresh all route should exist and respond to POST" do
    sign_in_as(@user)
    
    # Direct POST to the refresh_all route
    post "/sources/refresh_all"
    
    assert_redirected_to sources_path
  end
  
  test "refresh all should not be accessible without authentication" do
    post refresh_all_sources_path
    
    assert_redirected_to new_session_path
  end
end