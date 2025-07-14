require "test_helper"

class SourceWorkflowTest < ActionDispatch::IntegrationTest
  setup do
    @source = sources(:huggingface_forum)
    @user = users(:one)
    sign_in_as(@user)
  end

  test "complete source CRUD workflow" do
    # Visit sources index
    get sources_path
    assert_response :success
    assert_select "h1", "Sources"
    
    # Click new source link
    get new_source_path
    assert_response :success
    assert_select "h1", "New Source"
    
    # Create new source with valid data
    assert_difference("Source.count", 1) do
      post sources_path, params: {
        source: {
          name: "New Tech Forum",
          source_type: "discourse",
          url: "https://forum.example.com",
          active: true,
          config: '{"max_items": 50}'
        }
      }
    end
    
    new_source = Source.last
    assert_redirected_to sources_path
    follow_redirect!
    
    # Verify new source appears in list
    assert_select "h2", "New Tech Forum"
    assert_select "span", text: "discourse"
    
    # Edit the source
    get edit_source_path(new_source)
    assert_response :success
    assert_select "h1", "Edit Source"
    
    # Update source
    patch source_path(new_source), params: {
      source: {
        name: "Updated Tech Forum",
        active: false
      }
    }
    assert_redirected_to sources_path
    follow_redirect!
    
    # Verify changes
    new_source.reload
    assert_equal "Updated Tech Forum", new_source.name
    assert_equal false, new_source.active
    
    # Delete the source
    assert_difference("Source.count", -1) do
      delete source_path(new_source)
    end
    assert_redirected_to sources_path
  end

  test "workflow: create source with validation errors" do
    get new_source_path
    assert_response :success
    
    # Try to create source with invalid data
    assert_no_difference("Source.count") do
      post sources_path, params: {
        source: {
          name: "", # Invalid: blank name
          source_type: "", # Invalid: blank type
          url: "not-a-url", # Invalid URL
          active: true
        }
      }
    end
    
    assert_response :unprocessable_entity
    
    # Should show error messages
    assert_select ".bg-red-100" # Error box
    assert_match /Name can't be blank/, response.body
    assert_match /Source type can't be blank/, response.body
    assert_match /Url is invalid/, response.body
  end

  test "workflow: toggle source active status" do
    # Ensure source starts active
    @source.update!(active: true)
    
    get sources_path
    assert_response :success
    
    # Find and click edit for our source
    get edit_source_path(@source)
    assert_response :success
    
    # Toggle active to false
    patch source_path(@source), params: {
      source: { active: false }
    }
    assert_redirected_to sources_path
    
    @source.reload
    assert_equal false, @source.active
    
    # Posts from inactive sources should still be visible
    get posts_path
    assert_response :success
    # But no new posts would be fetched
  end

  test "workflow: source configuration handling" do
    # Create RSS source with specific config
    get new_source_path
    assert_response :success
    
    post sources_path, params: {
      source: {
        name: "Dev Blog RSS",
        source_type: "rss",
        url: "https://devblog.example.com/feed",
        active: true,
        config: '{"keywords": ["ruby", "rails"], "max_items": 10}'
      }
    }
    
    rss_source = Source.last
    assert_redirected_to sources_path
    
    # Verify config was saved correctly
    assert_equal ["ruby", "rails"], rss_source.config_hash["keywords"]
    assert_equal 10, rss_source.config_hash["max_items"]
    
    # Edit to update config
    get edit_source_path(rss_source)
    patch source_path(rss_source), params: {
      source: {
        config: '{"keywords": ["python", "django"], "max_items": 20}'
      }
    }
    
    rss_source.reload
    assert_equal ["python", "django"], rss_source.config_hash["keywords"]
    assert_equal 20, rss_source.config_hash["max_items"]
  end

  test "workflow: handle source with associated posts" do
    # Create posts for the source
    3.times do |i|
      Post.create!(
        source: @source.source_type,
        external_id: "source-post-#{i}",
        title: "Post #{i} from #{@source.name}",
        url: "https://example.com/#{i}",
        author: "tester",
        posted_at: i.hours.ago,
        status: "unread"
      )
    end
    
    # Try to delete source with posts
    delete source_path(@source)
    assert_redirected_to sources_path
    
    # Source should still exist (we don't cascade delete)
    assert Source.exists?(@source.id)
    
    # Posts should still exist
    assert_equal 3, Post.where(source: @source.source_type).count
  end

  test "workflow: view source details and status" do
    # Update source with recent fetch info
    @source.update!(
      last_fetched_at: 10.minutes.ago,
      status: "ok (15 new items)"
    )
    
    get sources_path
    assert_response :success
    
    # Should show last fetched time
    assert_match /10 minutes ago/, response.body
    assert_match /ok \(15 new items\)/, response.body
    
    # Test source with error status
    @source.update!(status: "error: HTTP 500")
    get sources_path
    assert_response :success
    
    assert_select "span.text-red-600", text: /error: HTTP 500/
  end

  test "workflow: create sources for different types" do
    # Create GitHub source
    post sources_path, params: {
      source: {
        name: "React GitHub",
        source_type: "github",
        url: "https://github.com/facebook/react",
        active: true,
        config: '{"labels": ["bug", "enhancement"], "token": "fake-token"}'
      }
    }
    assert_redirected_to sources_path
    
    # Create Discourse source
    post sources_path, params: {
      source: {
        name: "Rust Forum",
        source_type: "discourse",
        url: "https://users.rust-lang.org",
        active: true,
        config: '{}'
      }
    }
    assert_redirected_to sources_path
    
    # Create Reddit source
    post sources_path, params: {
      source: {
        name: "r/programming",
        source_type: "reddit",
        url: "https://reddit.com/r/programming",
        active: true,
        config: '{"sort": "hot", "limit": 25}'
      }
    }
    assert_redirected_to sources_path
    
    # Verify all sources created
    get sources_path
    assert_response :success
    
    assert_select "h2", "React GitHub"
    assert_select "h2", "Rust Forum"
    assert_select "h2", "r/programming"
    
    # Each should have appropriate type badge
    assert_select "span", text: "github"
    assert_select "span", text: "discourse"
    assert_select "span", text: "reddit"
  end
end