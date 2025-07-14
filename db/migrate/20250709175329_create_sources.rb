class CreateSources < ActiveRecord::Migration[8.0]
  def change
    create_table :sources do |t|
      t.string :name
      t.string :source_type
      t.string :url
      t.text :config
      t.boolean :active
      t.datetime :last_fetched_at
      t.string :status

      t.timestamps
    end
  end
end
