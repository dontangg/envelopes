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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20111116040514) do

  create_table "envelopes", :force => true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.boolean  "income"
    t.boolean  "unassigned"
    t.integer  "parent_envelope_id"
    t.string   "expense"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transactions", :force => true do |t|
    t.date     "posted_at"
    t.string   "payee"
    t.string   "original_payee"
    t.decimal  "amount"
    t.integer  "from_envelope_id"
    t.integer  "to_envelope_id"
    t.string   "unique_id"
    t.boolean  "pending"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "transactions", ["from_envelope_id"], :name => "index_transactions_on_from_envelope_id"
  add_index "transactions", ["posted_at"], :name => "index_transactions_on_posted_at"
  add_index "transactions", ["to_envelope_id"], :name => "index_transactions_on_to_envelope_id"

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "password_digest"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
