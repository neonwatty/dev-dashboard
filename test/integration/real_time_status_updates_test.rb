require "test_helper"

class RealTimeStatusUpdatesTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper
  
  def setup
    @user = users(:one)
    @source = sources(:huggingface_forum)
    sign_in_as(@user)
  end

  test "refreshing a source should broadcast status updates" do
    # Visit sources index
    get sources_path
    assert_response :success
    
    # Verify Turbo Cable Stream Source is present (Rails 8 uses turbo-cable-stream-source)
    assert_match(/turbo-cable-stream-source.*channel="Turbo::StreamsChannel"/, response.body)
    
    # Click refresh should trigger broadcasts
    assert_broadcasts("source_status:#{@source.id}", 1) do
      assert_broadcasts("source_status:all", 1) do
        post refresh_source_path(@source)
      end
    end
    
    # Should redirect with notice
    assert_redirected_to sources_path
    follow_redirect!
    assert_match(/refresh job queued/, flash[:notice])
  end

  test "refresh all should broadcast status updates for all active sources" do
    # Ensure we have multiple active sources
    active_sources = Source.active
    assert active_sources.count > 1
    
    # Each active source should get a broadcast
    expected_broadcasts = active_sources.count
    
    assert_broadcasts("source_status:all", expected_broadcasts) do
      post refresh_all_sources_path
    end
    
    assert_redirected_to sources_path
    follow_redirect!
    assert_match(/Queued \d+ refresh jobs/, flash[:notice])
  end

  test "source show page should have turbo stream subscription" do
    get source_path(@source)
    assert_response :success
    
    # Should have subscription to specific source channel
    assert_match(/turbo-cable-stream-source.*channel="Turbo::StreamsChannel"/, response.body)
    
    # Should render status badge with turbo frame
    assert_select "turbo-frame#source_#{@source.id}_status"
  end

  test "test connection should broadcast status updates" do
    stub_request(:get, @source.url)
      .to_return(status: 200, body: "OK")
    
    assert_broadcasts("source_status:#{@source.id}", 1) do
      assert_broadcasts("source_status:all", 1) do
        post test_connection_source_path(@source)
      end
    end
    
    assert_redirected_to source_path(@source)
  end

  test "job completion should broadcast final status" do
    # Mock the job performing and broadcasting
    perform_enqueued_jobs do
      stub_request(:get, "#{@source.url}/latest.json")
        .to_return(
          status: 200,
          body: {
            topic_list: {
              topics: [
                {
                  id: 999,
                  title: "New Topic",
                  slug: "new-topic",
                  created_at: 1.hour.ago,
                  last_poster_username: "test_user",
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
      
      # The job should broadcast when complete
      assert_broadcasts("source_status:#{@source.id}", 1) do
        assert_broadcasts("source_status:all", 1) do
          FetchHuggingFaceJob.perform_now(@source.id)
        end
      end
    end
    
    # Status should be updated
    @source.reload
    assert_match(/ok/, @source.status)
  end

  test "job error should broadcast error status" do
    perform_enqueued_jobs do
      stub_request(:get, "#{@source.url}/latest.json")
        .to_return(status: 500)
      
      # The job should broadcast error status
      assert_broadcasts("source_status:#{@source.id}", 1) do
        assert_broadcasts("source_status:all", 1) do
          FetchHuggingFaceJob.perform_now(@source.id)
        end
      end
    end
    
    # Status should show error
    @source.reload
    assert_match(/error/, @source.status)
  end
end