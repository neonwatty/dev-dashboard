require "test_helper"

class UserSettingTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end
  
  test "should belong to user" do
    user_setting = UserSetting.new(post_retention_days: 30)
    assert_not user_setting.valid?
    
    user_setting.user = @user
    assert user_setting.valid?
  end
  
  test "should validate presence of post_retention_days" do
    user_setting = @user.build_user_setting
    user_setting.post_retention_days = nil
    assert_not user_setting.valid?
    assert_includes user_setting.errors[:post_retention_days], "can't be blank"
  end
  
  test "should validate post_retention_days is at least 1" do
    user_setting = @user.build_user_setting(post_retention_days: 0)
    assert_not user_setting.valid?
    assert_includes user_setting.errors[:post_retention_days], "must be greater than or equal to 1"
    
    user_setting.post_retention_days = 1
    assert user_setting.valid?
  end
  
  test "should validate post_retention_days is at most 365" do
    user_setting = @user.build_user_setting(post_retention_days: 366)
    assert_not user_setting.valid?
    assert_includes user_setting.errors[:post_retention_days], "must be less than or equal to 365"
    
    user_setting.post_retention_days = 365
    assert user_setting.valid?
  end
  
  test "should set default post_retention_days to 30 for new records" do
    user_setting = @user.build_user_setting
    assert_equal 30, user_setting.post_retention_days
  end
  
  test "should not override existing post_retention_days on initialization" do
    user_setting = @user.build_user_setting(post_retention_days: 60)
    assert_equal 60, user_setting.post_retention_days
  end
  
  test "should enforce unique user_id" do
    # Ensure no existing setting
    @user.user_setting&.destroy
    
    # Create first setting
    first_setting = @user.create_user_setting(post_retention_days: 30)
    
    # Attempt to create duplicate through direct creation
    # This should raise an error due to the unique constraint
    assert_raises(ActiveRecord::RecordNotUnique) do
      UserSetting.create!(user: @user, post_retention_days: 60)
    end
  end
end
