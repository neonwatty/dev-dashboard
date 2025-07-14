require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_session_url
    assert_response :success
  end

  test "should sign in with valid credentials" do
    user = users(:one)
    
    post session_url, params: { email_address: user.email_address, password: "password" }
    
    assert_redirected_to root_url
    assert_not_nil cookies[:session_id]
  end

  test "should not sign in with invalid credentials" do
    post session_url, params: { email_address: "wrong@example.com", password: "wrongpassword" }
    
    assert_redirected_to new_session_url
    assert_match(/Try another email address or password/, flash[:alert])
  end

  test "should sign out" do
    user = users(:one)
    post session_url, params: { email_address: user.email_address, password: "password" }
    
    delete session_url
    
    assert_redirected_to new_session_url
    assert cookies[:session_id].blank?
  end
end