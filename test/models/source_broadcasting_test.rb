require "test_helper"

class SourceBroadcastingTest < ActiveSupport::TestCase
  setup do
    @source = sources(:huggingface_forum)
  end

  test "broadcast_recent_posts_update method exists and can be called" do
    # Simple test to ensure the method exists and doesn't raise an error
    assert_respond_to @source, :broadcast_recent_posts_update
    
    # Test that it can be called without error (we can't easily test the actual broadcast in unit tests)
    assert_nothing_raised do
      @source.broadcast_recent_posts_update
    end
  end

  test "broadcast_status_update works independently" do
    # Ensure existing status broadcasting still works
    @source.update_status_and_broadcast("test status")
    assert_equal "test status", @source.reload.status
  end
end