require "test_helper"

class SourcesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @source = sources(:huggingface_forum)
    @user = users(:one)
    sign_in_as(@user)
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
end
