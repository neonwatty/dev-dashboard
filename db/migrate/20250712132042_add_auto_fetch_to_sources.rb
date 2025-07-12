class AddAutoFetchToSources < ActiveRecord::Migration[8.0]
  def change
    add_column :sources, :auto_fetch_enabled, :boolean, default: true, null: false
  end
end
