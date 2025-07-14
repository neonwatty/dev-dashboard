require "test_helper"

class SourcesTurboStreamTest < ActionDispatch::IntegrationTest
  setup do
    @source = sources(:huggingface_forum)
    @user = users(:one)
    sign_in_as(@user)
  end

  test "refresh action responds with turbo stream" do
    assert_enqueued_with(job: FetchHuggingFaceJob, args: [@source.id]) do
      post refresh_source_path(@source), headers: { 
        'Accept' => 'text/vnd.turbo-stream.html, text/html' 
      }
    end
    
    assert_response :success
    assert_equal 'text/vnd.turbo-stream.html; charset=utf-8', response.content_type
    
    # Check for status badge update
    assert_match %r{<turbo-stream action="replace" target="source_#{@source.id}_status">}, response.body
    
    # Check for notification
    assert_match %r{<turbo-stream action="prepend" target="notifications">}, response.body
    assert_match 'HuggingFace refresh job queued', response.body
    
    # Verify source status was updated
    @source.reload
    assert_equal 'refreshing...', @source.status
  end

  test "refresh with unsupported source type returns turbo stream error" do
    unsupported_source = Source.create!(
      name: "Unknown Source",
      source_type: "discourse",
      url: "https://unknown.example.com",
      active: true
    )
    
    post refresh_source_path(unsupported_source), headers: { 
      'Accept' => 'text/vnd.turbo-stream.html, text/html' 
    }
    
    assert_response :success
    assert_equal 'text/vnd.turbo-stream.html; charset=utf-8', response.content_type
    
    # Should only have error notification, no status update
    assert_match %r{<turbo-stream action="prepend" target="notifications">}, response.body
    assert_match 'Refresh not supported for this source type yet', response.body
    
    unsupported_source.reload
    assert_equal 'error: unsupported source type', unsupported_source.status
  end

  test "test_connection action responds with turbo stream for success" do
    stub_request(:get, @source.url).to_return(status: 200, body: "OK")
    
    post test_connection_source_path(@source), headers: { 
      'Accept' => 'text/vnd.turbo-stream.html, text/html' 
    }
    
    # Should redirect for now (not implemented as turbo stream yet)
    assert_redirected_to source_path(@source)
    
    @source.reload
    assert_equal 'ok', @source.status
  end

  test "refresh all sources works with HTML request" do
    active_sources = Source.active.auto_fetch_enabled
    
    assert_enqueued_jobs active_sources.count do
      post refresh_all_sources_path
    end
    
    assert_redirected_to sources_path
    assert_match /Queued \d+ refresh jobs/, flash[:notice]
  end

  test "individual source refresh buttons use POST method" do
    get sources_path
    assert_response :success
    
    # Check that refresh buttons are forms with POST method
    assert_select "form[action='#{refresh_source_path(@source)}'][method='post']"
    assert_select "button[data-disable-with='...']", minimum: 1
  end

  test "refresh action updates status immediately before job runs" do
    initial_status = @source.status
    
    # Freeze time to ensure we can check the status was updated
    freeze_time do
      post refresh_source_path(@source), headers: { 
        'Accept' => 'text/vnd.turbo-stream.html, text/html' 
      }
      
      @source.reload
      assert_equal 'refreshing...', @source.status
      assert_equal Time.current, @source.updated_at
    end
  end

  test "multiple source types queue correct jobs" do
    # Test each source type
    sources_to_test = {
      huggingface_forum: FetchHuggingFaceJob,
      pytorch_forum: FetchPytorchJob,
      rails_github: FetchGithubIssuesJob,
      ruby_blog_rss: FetchRssJob,
      hacker_news: FetchHackerNewsJob,
      machine_learning_reddit: FetchRedditJob,
      github_trending: FetchGithubTrendingJob
    }
    
    sources_to_test.each do |fixture_name, expected_job|
      source = sources(fixture_name)
      
      assert_enqueued_with(job: expected_job, args: [source.id]) do
        post refresh_source_path(source)
      end
    end
  end

  private

  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
end