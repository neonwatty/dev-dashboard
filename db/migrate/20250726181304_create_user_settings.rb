class CreateUserSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :user_settings do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.integer :post_retention_days, default: 30, null: false

      t.timestamps
    end
  end
end
