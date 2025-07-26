class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :user_setting, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || !password.nil? }
  
  # Ensure user always has settings
  after_create :create_default_settings
  
  def settings
    user_setting || create_user_setting
  end
  
  private
  
  def create_default_settings
    create_user_setting unless user_setting
  end
end
