class CreateDefaultUserSettings < ActiveRecord::Migration[8.0]
  def up
    # Create default settings for all existing users
    User.find_each do |user|
      user.create_user_setting unless user.user_setting
    end
  end
  
  def down
    # Nothing to do here
  end
end
