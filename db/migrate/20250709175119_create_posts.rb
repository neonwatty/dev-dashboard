class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.string :source
      t.string :external_id
      t.string :title
      t.string :url
      t.string :author
      t.datetime :posted_at
      t.text :summary
      t.text :tags
      t.string :status
      t.float :priority_score
      t.text :llm_reply_draft

      t.timestamps
    end
  end
end
