require "test_helper"

class SourceUniquenessFlowTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @existing_source = sources(:huggingface_forum)
    sign_in_as(@user)
  end

  test "should show error when trying to create source with duplicate URL" do
    get new_source_path
    assert_response :success
    
    # Try to create a source with the same URL as existing
    assert_no_difference("Source.count") do
      post sources_path, params: {
        source: {
          name: "Duplicate HuggingFace",
          source_type: "discourse",
          url: @existing_source.url,
          config: "",
          active: true
        }
      }
    end
    
    assert_response :unprocessable_entity
    assert_select ".bg-red-100", text: /Please fix the following errors/
    assert_select "li", text: /Url has already been added/
  end

  test "should show friendly error message for duplicate URLs" do
    get new_source_path
    assert_response :success
    
    post sources_path, params: {
      source: {
        name: "Another Forum",
        source_type: "discourse",
        url: @existing_source.url.upcase, # Test case insensitivity
        config: "",
        active: true
      }
    }
    
    assert_response :unprocessable_entity
    assert_match(/has already been added/, response.body)
  end

  test "should allow creating source with different URL" do
    get new_source_path
    assert_response :success
    
    assert_difference("Source.count", 1) do
      post sources_path, params: {
        source: {
          name: "New Forum",
          source_type: "discourse",
          url: "https://new-forum.example.com",
          config: "",
          active: true
        }
      }
    end
    
    assert_redirected_to source_path(Source.last)
    follow_redirect!
    assert_match(/successfully created/, flash[:notice])
  end

  test "should show error when editing source to have duplicate URL" do
    other_source = sources(:pytorch_forum)
    
    get edit_source_path(other_source)
    assert_response :success
    
    patch source_path(other_source), params: {
      source: {
        url: @existing_source.url
      }
    }
    
    assert_response :success # Renders edit view again
    assert_select ".bg-red-100", text: /Please fix the following errors/
    assert_select "li", text: /Url has already been added/
    
    # Verify the source wasn't updated
    other_source.reload
    assert_not_equal @existing_source.url, other_source.url
  end

  test "should allow updating source without changing URL" do
    get edit_source_path(@existing_source)
    assert_response :success
    
    patch source_path(@existing_source), params: {
      source: {
        name: "Updated HuggingFace Forum",
        active: false
      }
    }
    
    assert_redirected_to source_path(@existing_source)
    follow_redirect!
    assert_match(/successfully updated/, flash[:notice])
    
    @existing_source.reload
    assert_equal "Updated HuggingFace Forum", @existing_source.name
    assert_equal false, @existing_source.active
  end
end