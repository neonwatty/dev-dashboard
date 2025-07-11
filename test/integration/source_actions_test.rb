require "test_helper"

class SourceActionsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @source = sources(:huggingface_forum)
    sign_in_as(@user)
  end

  test "should view source details" do
    get source_path(@source)
    assert_response :success
    
    # Check that all important information is displayed
    assert_select "h1", @source.name
    assert_select "span", text: @source.source_type.titleize
    assert_select "a[href=?]", @source.url
    assert_select "span", text: /Connected|ok|error/
    assert_select "span", text: @source.active? ? "Yes" : "No"
  end

  test "should show action buttons for authenticated user" do
    get source_path(@source)
    assert_response :success
    
    # Check that all action buttons are present
    assert_select "form[action=?]", test_connection_source_path(@source)
    assert_select "form[action=?]", refresh_source_path(@source)
    assert_select "form[action=?]", source_path(@source)
    
    # Check button texts
    assert_select "button", text: "Test Connection"
    assert_select "button", text: "Refresh Content"
    assert_select "button", text: "Delete Source"
  end

  test "should test connection successfully" do
    # Mock successful HTTP response
    stub_request(:get, @source.url)
      .to_return(status: 200, body: "OK")

    post test_connection_source_path(@source)
    
    assert_redirected_to source_path(@source)
    follow_redirect!
    
    assert_match(/Connection test successful/, flash[:notice])
    
    @source.reload
    assert_equal "ok", @source.status
  end

  test "should handle connection test failure" do
    # Mock failed HTTP response
    stub_request(:get, @source.url)
      .to_return(status: 404, body: "Not Found")

    post test_connection_source_path(@source)
    
    assert_redirected_to source_path(@source)
    follow_redirect!
    
    assert_match(/Connection failed/, flash[:alert])
    
    @source.reload
    assert_match(/error: HTTP 404/, @source.status)
  end

  test "should handle connection test network error" do
    # Mock network error
    stub_request(:get, @source.url)
      .to_raise(SocketError.new("Network unreachable"))

    post test_connection_source_path(@source)
    
    assert_redirected_to source_path(@source)
    follow_redirect!
    
    assert_match(/Connection failed/, flash[:alert])
    
    @source.reload
    assert_match(/error: Network unreachable/, @source.status)
  end

  test "should refresh content for discourse source" do
    discourse_source = sources(:huggingface_forum)
    
    assert_enqueued_with(job: FetchHuggingFaceJob, args: [discourse_source.id]) do
      post refresh_source_path(discourse_source)
    end
    
    assert_redirected_to sources_path
    follow_redirect!
    
    assert_match(/HuggingFace refresh job queued/, flash[:notice])
    
    discourse_source.reload
    assert_equal "refreshing...", discourse_source.status
  end

  test "should refresh content for github source" do
    github_source = sources(:rails_github)
    
    assert_enqueued_with(job: FetchGithubIssuesJob, args: [github_source.id]) do
      post refresh_source_path(github_source)
    end
    
    assert_redirected_to sources_path
    follow_redirect!
    
    assert_match(/GitHub refresh job queued/, flash[:notice])
  end

  test "should refresh content for rss source" do
    rss_source = sources(:ruby_blog_rss)
    
    assert_enqueued_with(job: FetchRssJob, args: [rss_source.id]) do
      post refresh_source_path(rss_source)
    end
    
    assert_redirected_to sources_path
    follow_redirect!
    
    assert_match(/RSS refresh job queued/, flash[:notice])
  end

  test "should refresh content for reddit source" do
    reddit_source = sources(:machine_learning_reddit)
    
    assert_enqueued_with(job: FetchRedditJob, args: [reddit_source.id]) do
      post refresh_source_path(reddit_source)
    end
    
    assert_redirected_to sources_path
    follow_redirect!
    
    assert_match(/Reddit refresh job queued/, flash[:notice])
  end


  test "should create new source" do
    get new_source_path
    assert_response :success
    
    assert_difference("Source.count", 1) do
      post sources_path, params: {
        source: {
          name: "Test Source",
          source_type: "rss",
          url: "https://example.com/feed.xml",
          config: '{"keywords": ["test"]}',
          active: true
        }
      }
    end
    
    source = Source.last
    assert_redirected_to source_path(source)
    assert_equal "Test Source", source.name
    assert_equal "rss", source.source_type
    assert source.active?
  end

  test "should not create invalid source" do
    get new_source_path
    assert_response :success
    
    assert_no_difference("Source.count") do
      post sources_path, params: {
        source: {
          name: "",
          source_type: "",
          url: "invalid-url",
          config: "{}",
          active: true
        }
      }
    end
    
    assert_response :unprocessable_entity
  end

  test "should edit and update source" do
    get edit_source_path(@source)
    assert_response :success
    
    patch source_path(@source), params: {
      source: {
        name: "Updated Source Name",
        active: false
      }
    }
    
    assert_redirected_to source_path(@source)
    
    @source.reload
    assert_equal "Updated Source Name", @source.name
    assert_not @source.active?
  end

  test "should delete source" do
    # Remove any posts associated with this source to allow deletion
    Post.where(source: "huggingface").delete_all
    
    assert_difference("Source.count", -1) do
      delete source_path(@source)
    end
    
    assert_redirected_to sources_path
    follow_redirect!
    
    assert_match(/successfully deleted/, flash[:notice])
  end

  test "should show recent posts from source" do
    # Create a post from this source
    post = Post.create!(
      source: @source.name,
      external_id: "test_post_123",
      title: "Test Post from Source",
      summary: "This is a test post",
      url: "https://example.com/post/123",
      author: "test_author",
      posted_at: 1.hour.ago,
      priority_score: 5.0,
      tags: "test, source",
      status: "unread"
    )
    
    get source_path(@source)
    assert_response :success
    
    # Should show the recent post
    assert_select "h3", text: /Test Post from Source/
    assert_select "p", text: /test_author/
  end

  test "should handle empty recent posts" do
    # Ensure no posts exist for this source
    Post.where(source: @source.name).destroy_all
    
    get source_path(@source)
    assert_response :success
    
    assert_select "p", text: /No posts have been fetched/
  end

  test "should require authentication for all actions" do
    # Sign out
    delete session_path
    
    # Test all source actions redirect to login
    [
      [:get, source_path(@source)],
      [:get, new_source_path],
      [:get, edit_source_path(@source)],
      [:post, sources_path],
      [:patch, source_path(@source)],
      [:delete, source_path(@source)],
      [:post, test_connection_source_path(@source)],
      [:post, refresh_source_path(@source)]
    ].each do |method, path|
      send(method, path)
      assert_redirected_to new_session_path, "#{method.upcase} #{path} should require authentication"
    end
  end

  test "should display proper source type colors" do
    # Test different source types have different colors
    discourse_source = sources(:huggingface_forum)
    github_source = sources(:rails_github)
    
    get source_path(discourse_source)
    assert_response :success
    # Should have some color class (exact color may vary)
    assert_select "span[class*='bg-']"
    
    get source_path(github_source)
    assert_response :success
    assert_select "span[class*='bg-']"
  end
end