require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should create default settings after user creation" do
    user = User.create!(
      email_address: "test@example.com",
      password: "password123"
    )
    
    assert_not_nil user.user_setting
    assert_equal 30, user.user_setting.post_retention_days
  end
  
  test "settings method should return existing user_setting" do
    user = users(:one)
    user.user_setting&.destroy
    setting = user.create_user_setting(post_retention_days: 60)
    
    assert_equal setting, user.settings
  end
  
  test "settings method should create user_setting if missing" do
    user = users(:one)
    user.user_setting&.destroy
    
    assert_nil user.reload.user_setting
    
    setting = user.settings
    assert_not_nil setting
    assert_equal 30, setting.post_retention_days
    assert setting.persisted?
  end
  
  test "destroying user should destroy associated user_setting" do
    user = users(:one)
    user.user_setting&.destroy
    user.create_user_setting(post_retention_days: 45)
    
    assert_difference "UserSetting.count", -1 do
      user.destroy
    end
  end
end
