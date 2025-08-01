require "test_helper"

class SourcesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @source = sources(:huggingface_forum)
    @user = users(:one)
    sign_in_as(@user)
  end

  test "unauthenticated user gets auth required message for sources index" do
    sign_out
    get sources_url
    
    assert_redirected_to new_session_path
    
    # Check that return URL is set in session
    assert_equal sources_url, session[:return_to_after_authenticating]
    
    follow_redirect!
    
    # Verify that the authentication required message is displayed
    assert_select 'div.bg-blue-50'
    assert_select 'h3', text: 'Authentication Required'
    assert response.body.include?("Authentication Required"), "Should display authentication required header"
    assert response.body.include?("Sign In Now"), "Should contain 'Sign In Now' button"
    assert response.body.include?("Learn More"), "Should contain 'Learn More' link"
    assert_select 'button[form="sign-in-form"]', text: 'Sign In Now'
    assert_select 'a[href="/"]', text: 'Learn More'
  end

  test "unauthenticated user gets auth required message for sources new" do
    sign_out  
    get new_source_url
    
    assert_redirected_to new_session_path
    
    follow_redirect!
    
    # Verify that the authentication required message is displayed
    assert_select 'div.bg-blue-50'
    assert_select 'h3', text: 'Authentication Required'
    assert response.body.include?("Authentication Required"), "Should display authentication required header"
    assert response.body.include?("Source Creation"), "Should mention Source Creation in the message"
    assert response.body.include?("Sign In Now"), "Should contain 'Sign In Now' button"
    assert response.body.include?("Learn More"), "Should contain 'Learn More' link"
  end

  test "should get index" do
    get sources_url
    assert_response :success
    assert_select 'h1', text: 'Sources'
  end

  test "should get show" do
    get source_url(@source)
    assert_response :success
    assert_select 'h1', text: @source.name
  end

  test "should get new" do
    get new_source_url
    assert_response :success
    assert_select 'h1', text: 'Add New Source'
  end

  test "should create source" do
    assert_difference('Source.count') do
      post sources_url, params: { 
        source: { 
          name: 'Test Source',
          source_type: 'github',
          url: 'https://github.com/test/repo',
          config: '{}',
          active: true
        }
      }
    end

    assert_redirected_to source_url(Source.last)
  end

  test "should not create invalid source" do
    assert_no_difference('Source.count') do
      post sources_url, params: { 
        source: { 
          name: '',  # Invalid - name is required
          source_type: 'github',
          url: 'invalid-url',  # Invalid URL
          config: '{}',
          active: true
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_source_url(@source)
    assert_response :success
    assert_select 'h1', text: 'Edit Source'
  end

  test "should update source" do
    patch source_url(@source), params: { 
      source: { name: 'Updated Name' }
    }
    assert_redirected_to source_url(@source)
    
    @source.reload
    assert_equal 'Updated Name', @source.name
  end

  test "should destroy source" do
    # Remove any posts associated with this source to allow deletion
    Post.where(source: "huggingface").delete_all
    
    assert_difference('Source.count', -1) do
      delete source_url(@source)
    end

    assert_redirected_to sources_url
  end

  test "should refresh source" do
    # Mock the job
    assert_enqueued_with(job: FetchHuggingFaceJob, args: [@source.id]) do
      post refresh_source_url(@source)
    end

    assert_redirected_to sources_url
    assert_match(/HuggingFace refresh job queued/, flash[:notice])
  end

  test "should test connection" do
    # Mock successful HTTP response
    stub_request(:get, @source.url)
      .to_return(status: 200, body: 'OK')

    post test_connection_source_url(@source)
    assert_redirected_to source_url(@source)
    
    @source.reload
    assert_equal 'ok', @source.status
  end
  
  test "should refresh Reddit source" do
    reddit_source = sources(:machine_learning_reddit)
    
    # Mock the job
    assert_enqueued_with(job: FetchRedditJob, args: [reddit_source.id]) do
      post refresh_source_url(reddit_source)
    end

    assert_redirected_to sources_url
    assert_match(/Reddit refresh job queued/, flash[:notice])
  end
end
