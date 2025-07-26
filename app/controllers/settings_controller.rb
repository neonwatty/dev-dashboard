class SettingsController < ApplicationController
  before_action :authenticate_user!
  
  def edit
    @user_setting = Current.user.settings
  end

  def update
    @user_setting = Current.user.settings
    
    if @user_setting.update(user_setting_params)
      redirect_to edit_settings_path, notice: "Settings updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  private
  
  def authenticate_user!
    redirect_to new_session_path, alert: "Please sign in to access settings." unless authenticated?
  end
  
  def user_setting_params
    params.require(:user_setting).permit(:post_retention_days)
  end
end
