class AddUniqueIndexToSourcesUrl < ActiveRecord::Migration[8.0]
  def change
    add_index :sources, :url, unique: true
  end
end
