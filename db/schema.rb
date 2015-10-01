# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150929175442) do

  create_table "attachment_headers", force: true do |t|
    t.integer  "message_attachment_id"
    t.string   "name"
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "attachment_headers", ["message_attachment_id"], name: "index_attachment_headers_on_message_attachment_id"
  add_index "attachment_headers", ["name"], name: "index_attachment_headers_on_name"

  create_table "authorisations", force: true do |t|
    t.integer  "requester_id"
    t.integer  "granter_id"
    t.string   "scope"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "synced"
    t.string   "status"
    t.text     "description"
  end

  add_index "authorisations", ["granter_id"], name: "index_authorisations_on_granter_id"
  add_index "authorisations", ["requester_id", "granter_id"], name: "index_authorisations_on_requester_id_and_granter_id"
  add_index "authorisations", ["requester_id"], name: "index_authorisations_on_requester_id"
  add_index "authorisations", ["status"], name: "index_authorisations_on_status"
  add_index "authorisations", ["synced"], name: "index_authorisations_on_synced"

  create_table "email_headers", force: true do |t|
    t.integer  "email_message_id"
    t.string   "name"
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "email_headers", ["email_message_id"], name: "index_email_headers_on_email_message_id"
  add_index "email_headers", ["name"], name: "index_email_headers_on_name"

  create_table "email_messages", force: true do |t|
    t.integer  "email_thread_id"
    t.string   "message_id"
    t.text     "snippet"
    t.string   "history_id"
    t.string   "internal_date"
    t.text     "body_text"
    t.text     "body_html"
    t.string   "size_estimate"
    t.string   "mime_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "subject"
  end

  add_index "email_messages", ["email_thread_id"], name: "index_email_messages_on_email_thread_id"

  create_table "email_threads", force: true do |t|
    t.integer  "authorisation_id"
    t.string   "thread_id"
    t.text     "snippet"
    t.integer  "history_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "synced"
  end

  add_index "email_threads", ["synced"], name: "index_email_threads_on_synced"
  add_index "email_threads", ["thread_id"], name: "index_email_threads_on_thread_id"

  create_table "message_attachments", force: true do |t|
    t.integer  "email_message_id"
    t.string   "mime_type"
    t.text     "filename"
    t.text     "attachment_id",    limit: 255
    t.integer  "size"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "inline"
    t.string   "file"
    t.string   "content_id"
  end

  add_index "message_attachments", ["email_message_id"], name: "index_message_attachments_on_email_message_id"
  add_index "message_attachments", ["inline"], name: "index_message_attachments_on_inline"

  create_table "message_participants", force: true do |t|
    t.integer  "email_message_id"
    t.integer  "participant_id"
    t.string   "delivery"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "message_participants", ["delivery"], name: "index_message_participants_on_delivery"
  add_index "message_participants", ["email_message_id"], name: "index_message_participants_on_email_message_id"
  add_index "message_participants", ["participant_id"], name: "index_message_participants_on_participant_id"

  create_table "participants", force: true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "domain"
    t.string   "company"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "participants", ["company"], name: "index_participants_on_company"
  add_index "participants", ["domain"], name: "index_participants_on_domain"
  add_index "participants", ["email"], name: "index_participants_on_email"

  create_table "tokens", force: true do |t|
    t.integer  "user_id"
    t.string   "access_token"
    t.string   "refresh_token"
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tokens", ["user_id"], name: "index_tokens_on_user_id"

  create_table "users", force: true do |t|
    t.string   "email",                  default: "",   null: false
    t.string   "encrypted_password",     default: "",   null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,    null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "provider"
    t.string   "uid"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "image"
    t.string   "gender"
    t.boolean  "guest",                  default: true
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["guest"], name: "index_users_on_guest"
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

end
