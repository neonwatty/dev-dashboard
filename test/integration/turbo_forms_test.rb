require "test_helper"

class TurboFormsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @source = sources(:huggingface_forum)
    sign_in_as(@user)
  end

  test "all POST/PATCH/DELETE links should use button_to or forms" do
    # Check sources index page
    get sources_path
    assert_response :success
    
    # Should have forms for actions, not links
    assert_select "form[action=?]", refresh_all_sources_path
    assert_select "form[action=?]", test_connection_source_path(@source)
    assert_select "form[action=?]", refresh_source_path(@source)
    assert_select "form[action=?]", source_path(@source)
    
    # Should NOT have any link_to with method: :post/delete/patch
    assert_select "a[data-method]", false, "Found link_to with data-method attribute (old UJS syntax)"
  end

  test "refresh button should work from sources index" do
    assert_enqueued_with(job: FetchHuggingFaceJob, args: [@source.id]) do
      post refresh_source_path(@source)
    end
    
    assert_redirected_to sources_path
    follow_redirect!
    
    assert_match(/refresh job queued/, flash[:notice])
  end

  test "test connection button should work from sources index" do
    stub_request(:get, @source.url)
      .to_return(status: 200, body: "OK")

    post test_connection_source_path(@source)
    
    assert_redirected_to source_path(@source)
    follow_redirect!
    
    assert_match(/Connection test successful/, flash[:notice])
  end

  test "delete button should work from sources index" do
    assert_difference("Source.count", -1) do
      delete source_path(@source)
    end
    
    assert_redirected_to sources_path
    follow_redirect!
    
    assert_match(/successfully deleted/, flash[:notice])
  end

  test "refresh all button should work from sources index" do
    active_sources = Source.active
    
    assert_enqueued_jobs active_sources.count do
      post refresh_all_sources_path
    end
    
    assert_redirected_to sources_path
    follow_redirect!
    
    assert_match(/Queued \d+ refresh jobs/, flash[:notice])
  end

  test "posts index action buttons should use button_to" do
    @post = posts(:huggingface_post)
    
    get posts_path
    assert_response :success
    
    # Should have forms for mark as actions
    assert_select "form[action=?]", mark_as_read_post_path(@post)
    assert_select "form[action=?]", mark_as_ignored_post_path(@post)
    assert_select "form[action=?]", mark_as_responded_post_path(@post)
  end

  test "source show page buttons should use button_to" do
    get source_path(@source)
    assert_response :success
    
    # Should have forms for actions
    assert_select "form[action=?]", test_connection_source_path(@source)
    assert_select "form[action=?]", refresh_source_path(@source)
    assert_select "form[action=?]", source_path(@source)
  end
end