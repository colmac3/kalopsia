# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110331102938) do

  create_table "canned_messages", :force => true do |t|
    t.string   "subject"
    t.string   "email"
    t.text     "body"
    t.integer  "messaging_setup_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "accept_input",       :default => false
  end

  create_table "configuration_options", :force => true do |t|
    t.string "key"
    t.text   "options"
  end

  create_table "configurations", :force => true do |t|
    t.string   "name"
    t.text     "options"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "stakeholder_id"
    t.integer  "rtml_application_id"
  end

  create_table "coupon_attachments", :force => true do |t|
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "coupon_id"
    t.integer  "configuration_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "coupon_steps", :force => true do |t|
    t.text     "arguments"
    t.integer  "order"
    t.string   "type"
    t.integer  "coupon_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "coupons", :force => true do |t|
    t.string   "name"
    t.integer  "width",          :default => 384
    t.integer  "height",         :default => 128
    t.integer  "stakeholder_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "messages", :force => true do |t|
    t.string   "subject"
    t.string   "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "stakeholder_id"
    t.date     "start_date"
    t.date     "end_date"
  end

  create_table "messaging_setups", :force => true do |t|
    t.integer  "stakeholder_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "passwords", :force => true do |t|
    t.string   "secret"
    t.string   "salt"
    t.string   "persistence_token"
    t.string   "single_access_token"
    t.string   "perishable_token"
    t.integer  "authenticatable_id"
    t.string   "authenticatable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rtml_applications", :force => true do |t|
    t.string   "path"
    t.string   "name"
    t.integer  "stakeholder_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rtml_documents", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.boolean  "cache_on_terminal"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "options"
  end

  create_table "rtml_instructions", :force => true do |t|
    t.string   "name"
    t.text     "arguments"
    t.integer  "source_id"
    t.string   "source_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id"
    t.integer  "x",           :default => 0
    t.integer  "y",           :default => 0
  end

  create_table "rtml_states", :force => true do |t|
    t.string   "itid"
    t.string   "model"
    t.string   "serial_number"
    t.string   "os"
    t.string   "part_number"
    t.datetime "datetime"
    t.datetime "datetime_start"
    t.text     "other_data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "configuration_id"
  end

  create_table "sage_transaction_information", :force => true do |t|
    t.string   "reference"
    t.integer  "transaction_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "invoice_number", :default => "new"
  end

  create_table "stakeholders", :force => true do |t|
    t.string   "name"
    t.text     "options"
    t.integer  "stakeholder_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "deletable"
  end

  create_table "terminal_messages", :force => true do |t|
    t.integer  "terminal_id"
    t.integer  "message_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "read_state",  :default => "new"
  end

  create_table "transaction_logs", :force => true do |t|
    t.string   "processor"
    t.string   "merchant_id"
    t.string   "merchant_key"
    t.text     "transaction"
    t.text     "result"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "action"
  end

  create_table "transactions", :force => true do |t|
    t.integer  "amount",         :limit => 2, :precision => 2, :scale => 0
    t.string   "reference_code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "terminal_id"
    t.integer  "state_id"
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.integer  "stakeholder_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
