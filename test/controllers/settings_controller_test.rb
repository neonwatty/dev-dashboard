require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end
  
  test "should get edit when authenticated" do
    get edit_settings_url
    assert_response :success
    assert_select "h1", "Settings"
    assert_select "input[name='user_setting[post_retention_days]']"
  end

  test "should redirect to login when not authenticated" do
    sign_out
    get edit_settings_url
    assert_redirected_to new_session_path
  end
  
  test "should update settings" do
    patch settings_url, params: { user_setting: { post_retention_days: 60 } }
    assert_redirected_to edit_settings_path
    assert_equal "Settings updated successfully.", flash[:notice]
    
    @user.reload
    assert_equal 60, @user.settings.post_retention_days
  end
  
  test "should show errors for invalid settings" do
    patch settings_url, params: { user_setting: { post_retention_days: 400 } }
    assert_response :unprocessable_entity
    assert_select "div", text: /must be less than or equal to 365/
  end
  
  private
  
  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
  
  def sign_out
    delete session_url
  end
end
