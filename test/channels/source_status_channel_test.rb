require "test_helper"

class SourceStatusChannelTest < ActionCable::Channel::TestCase
  def setup
    @source = sources(:huggingface_forum)
  end

  test "subscribes to all sources stream" do
    subscribe
    assert subscription.confirmed?
    assert_has_stream "source_status:all"
  end

  test "subscribes to specific source stream when source_id provided" do
    subscribe source_id: @source.id
    assert subscription.confirmed?
    assert_has_stream "source_status:all"
    assert_has_stream "source_status:#{@source.id}"
  end

  test "subscribes only to all stream when no source_id" do
    subscribe
    assert subscription.confirmed?
    assert_has_stream "source_status:all"
    assert_has_no_stream "source_status:#{@source.id}"
  end

  test "unsubscribe removes streams" do
    subscribe source_id: @source.id
    assert subscription.confirmed?
    
    unsubscribe
    assert_no_streams
  end
end