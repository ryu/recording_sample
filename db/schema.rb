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

ActiveRecord::Schema[8.1].define(version: 2026_01_05_082108) do
  create_table "documents", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "events", force: :cascade do |t|
    t.string "action_type"
    t.integer "actor_id"
    t.string "actor_name"
    t.datetime "created_at", null: false
    t.json "metadata", default: {}
    t.integer "recordable_id"
    t.string "recordable_type"
    t.integer "recording_id", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_events_on_actor_id"
    t.index ["actor_name"], name: "index_events_on_actor_name"
    t.index ["recordable_type", "recordable_id"], name: "index_events_on_recordable"
    t.index ["recording_id"], name: "index_events_on_recording_id"
  end

  create_table "recordings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.integer "recordable_id"
    t.string "recordable_type"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "events", "recordings"
end
