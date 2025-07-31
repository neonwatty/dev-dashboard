class AddKeyboardShortcutsEnabledToUserSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :user_settings, :keyboard_shortcuts_enabled, :boolean, default: true, null: false
  end
end
