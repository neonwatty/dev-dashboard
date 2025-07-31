class UserSetting < ApplicationRecord
  belongs_to :user
  
  validates :post_retention_days, presence: true, 
            numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 365 }
  
  # Sensible defaults
  after_initialize do
    self.post_retention_days ||= 30 if new_record?
    self.keyboard_shortcuts_enabled = true if keyboard_shortcuts_enabled.nil? && new_record?
  end
end
