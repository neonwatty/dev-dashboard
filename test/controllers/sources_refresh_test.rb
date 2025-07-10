require "test_helper"

class SourcesRefreshTest < ActionDispatch::IntegrationTest
  setup do
    @source = sources(:huggingface_forum)
    @github_source = sources(:rails_github)
    @rss_source = sources(:ruby_blog_rss)
    @user = users(:one)
    sign_in_as(@user)
  end

  test "should refresh individual discourse source" do
    assert_not_equal 'refreshing...', @source.status
    
    # Mock successful job enqueue
    assert_enqueued_with(job: FetchHuggingFaceJob, args: [@source.id]) do
      post refresh_source_path(@source)
    end
    
    @source.reload
    assert_equal 'refreshing...', @source.status
    assert_redirected_to sources_path
    assert_equal "HuggingFace refresh job queued for #{@source.name}. Check back in a moment.", flash[:notice]
  end

  test "should refresh GitHub source" do
    assert_enqueued_with(job: FetchGithubIssuesJob, args: [@github_source.id]) do
      post refresh_source_path(@github_source)
    end
    
    @github_source.reload
    assert_equal 'refreshing...', @github_source.status
    assert_redirected_to sources_path
  end

  test "should refresh RSS source" do
    assert_enqueued_with(job: FetchRssJob, args: [@rss_source.id]) do
      post refresh_source_path(@rss_source)
    end
    
    @rss_source.reload
    assert_equal 'refreshing...', @rss_source.status
    assert_redirected_to sources_path
  end

  test "should refresh Hacker News source" do
    hn_source = sources(:hacker_news)
    
    assert_enqueued_with(job: FetchHackerNewsJob, args: [hn_source.id]) do
      post refresh_source_path(hn_source)
    end
    
    hn_source.reload
    assert_equal 'refreshing...', hn_source.status
  end

  test "should handle unsupported source type" do
    # Create a Reddit source (not yet supported)
    reddit_source = Source.create!(
      name: "Reddit Programming",
      source_type: "reddit",
      url: "https://reddit.com/r/programming",
      active: true
    )
    
    assert_no_enqueued_jobs do
      post refresh_source_path(reddit_source)
    end
    
    reddit_source.reload
    assert_equal 'error: unsupported source type', reddit_source.status
    assert_redirected_to sources_path
    assert_equal "Refresh not supported for this source type yet.", flash[:alert]
  end

  test "should refresh all active sources" do
    # Ensure sources are active
    @source.update!(active: true)
    @github_source.update!(active: true)
    @rss_source.update!(active: true)
    
    # Count active sources that will be refreshed
    active_count = Source.active.count
    
    # Create an inactive source that should not be refreshed
    inactive_source = sources(:inactive_source)
    inactive_source.update!(active: false)
    
    assert_enqueued_jobs active_count do
      post refresh_all_sources_path
    end
    
    assert_redirected_to sources_path
    assert_match /Queued \d+ refresh jobs/, flash[:notice]
    
    # Active sources should be refreshing
    [@source, @github_source, @rss_source].each do |source|
      source.reload
      assert_equal 'refreshing...', source.status
    end
    
    # Inactive source should not be touched
    inactive_source.reload
    assert_not_equal 'refreshing...', inactive_source.status
  end

  test "should redirect back to previous page after refresh" do
    # When coming from source show page
    post refresh_source_path(@source), headers: { "HTTP_REFERER" => source_url(@source) }
    assert_redirected_to source_url(@source)
    
    # When coming from sources index
    post refresh_source_path(@source), headers: { "HTTP_REFERER" => sources_url }
    assert_redirected_to sources_url
    
    # When no referrer, should fallback to sources index
    post refresh_source_path(@source)
    assert_redirected_to sources_path
  end

  test "should handle PyTorch source refresh" do
    pytorch_source = sources(:pytorch_forum)
    
    assert_enqueued_with(job: FetchPytorchJob, args: [pytorch_source.id]) do
      post refresh_source_path(pytorch_source)
    end
    
    pytorch_source.reload
    assert_equal 'refreshing...', pytorch_source.status
    assert_equal "PyTorch refresh job queued for #{pytorch_source.name}. Check back in a moment.", flash[:notice]
  end

  test "refresh button should be visible on sources index" do
    get sources_path
    assert_response :success
    
    # Check for refresh all button
    assert_select "a[href='#{refresh_all_sources_path}']", text: /Refresh All Active/
    
    # Check for individual refresh buttons
    assert_select "a[href='#{refresh_source_path(@source)}']", text: /Refresh/
  end

  test "refresh button should be visible on source show page" do
    get source_path(@source)
    assert_response :success
    
    assert_select "a[href='#{refresh_source_path(@source)}']", text: /Refresh Content/
  end
end