require "test_helper"

class DiscourseBroadcastingTest < ActiveJob::TestCase
  include ActionCable::TestHelper

  def setup
    @huggingface_source = sources(:huggingface_forum)
    @pytorch_source = sources(:pytorch_forum)
  end

  test "FetchHuggingFaceJob broadcasts when refreshing" do
    # Stub the initial status broadcast
    assert_broadcasts("source_status:#{@huggingface_source.id}", 1) do
      assert_broadcasts("source_status:all", 1) do
        @huggingface_source.update_status_and_broadcast('refreshing...')
      end
    end
  end

  test "FetchHuggingFaceJob broadcasts on successful fetch" do
    stub_request(:get, "#{@huggingface_source.url}/latest.json")
      .to_return(
        status: 200,
        body: {
          topic_list: {
            topics: [
              {
                id: 123,
                title: "Test Topic",
                slug: "test-topic",
                created_at: 1.hour.ago,
                last_poster_username: "testuser",
                excerpt: "Test excerpt",
                reply_count: 5,
                like_count: 10,
                views: 100
              }
            ]
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    # The job should broadcast status update when complete
    assert_broadcasts("source_status:#{@huggingface_source.id}", 1) do
      assert_broadcasts("source_status:all", 1) do
        FetchHuggingFaceJob.perform_now(@huggingface_source.id)
      end
    end

    @huggingface_source.reload
    assert_match(/ok/, @huggingface_source.status)
  end

  test "FetchPytorchJob broadcasts on successful fetch" do
    stub_request(:get, "#{@pytorch_source.url}/latest.json")
      .to_return(
        status: 200,
        body: {
          topic_list: {
            topics: [
              {
                id: 456,
                title: "PyTorch Question",
                slug: "pytorch-question",
                created_at: 2.hours.ago,
                last_poster_username: "pytorch_user",
                excerpt: "PyTorch help needed",
                reply_count: 3,
                like_count: 5,
                views: 50
              }
            ]
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    assert_broadcasts("source_status:#{@pytorch_source.id}", 1) do
      assert_broadcasts("source_status:all", 1) do
        FetchPytorchJob.perform_now(@pytorch_source.id)
      end
    end

    @pytorch_source.reload
    assert_match(/ok/, @pytorch_source.status)
  end

  test "Discourse jobs broadcast errors properly" do
    stub_request(:get, "#{@huggingface_source.url}/latest.json")
      .to_return(status: 500)

    assert_broadcasts("source_status:#{@huggingface_source.id}", 1) do
      assert_broadcasts("source_status:all", 1) do
        FetchHuggingFaceJob.perform_now(@huggingface_source.id)
      end
    end

    @huggingface_source.reload
    assert_match(/error/, @huggingface_source.status)
  end
end