require "test_helper"

class SourceBroadcastingTest < ActiveSupport::TestCase
  include ActionCable::TestHelper
  include ActiveJob::TestHelper

  def setup
    @source = sources(:huggingface_forum)
  end

  test "update_status_and_broadcast should update status and broadcast" do
    # Should broadcast to both channels
    assert_broadcasts("source_status:#{@source.id}", 1) do
      assert_broadcasts("source_status:all", 1) do
        @source.update_status_and_broadcast("refreshing...")
      end
    end
    
    # Verify status was updated
    assert_equal "refreshing...", @source.reload.status
  end

  test "broadcast_status_update should broadcast to both channels" do
    @source.update!(status: "ok (5 new)")
    
    # Should broadcast to both channels
    assert_broadcasts("source_status:#{@source.id}", 1) do
      assert_broadcasts("source_status:all", 1) do
        @source.broadcast_status_update
      end
    end
  end

  test "broadcasts should include turbo stream replace" do
    @source.update!(status: "ok (3 new)")
    
    @source.broadcast_status_update
    
    # The broadcast should contain turbo_stream replace action
    broadcasts_list = broadcasts("source_status:#{@source.id}")
    assert_equal 1, broadcasts_list.size
    
    # Decode the JSON-encoded broadcast content
    broadcast_content = JSON.parse(broadcasts_list.first)
    assert_match(/turbo-stream/, broadcast_content)
    assert_match(/action=\\?"replace\\?"/, broadcast_content)
    assert_match(/source_#{@source.id}_status/, broadcast_content)
  end
end