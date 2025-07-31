# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_31_192233) do
  create_table "posts", force: :cascade do |t|
    t.string "source"
    t.string "external_id"
    t.string "title"
    t.string "url"
    t.string "author"
    t.datetime "posted_at"
    t.text "summary"
    t.text "tags"
    t.string "status"
    t.float "priority_score"
    t.text "llm_reply_draft"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sources", force: :cascade do |t|
    t.string "name"
    t.string "source_type"
    t.string "url"
    t.text "config"
    t.boolean "active"
    t.datetime "last_fetched_at"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "auto_fetch_enabled", default: true, null: false
    t.index ["url"], name: "index_sources_on_url", unique: true
  end

  create_table "user_settings", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "post_retention_days", default: 30, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "keyboard_shortcuts_enabled", default: true, null: false
    t.index ["user_id"], name: "index_user_settings_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "sessions", "users"
  add_foreign_key "user_settings", "users"
end
