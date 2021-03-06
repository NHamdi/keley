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

ActiveRecord::Schema.define(version: 20151016045304) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string   "name"
    t.string   "permalink"
    t.text     "description"
    t.integer  "parent_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "categories", ["description"], name: "index_categories_on_description", using: :btree
  add_index "categories", ["name"], name: "index_categories_on_name", using: :btree

  create_table "categories_products", id: false, force: :cascade do |t|
    t.integer "product_id"
    t.integer "category_id"
  end

  create_table "category_products", id: false, force: :cascade do |t|
    t.integer "category_id"
    t.integer "product_id"
  end

  create_table "product_images", force: :cascade do |t|
    t.string   "link"
    t.boolean  "snippet"
    t.integer  "product_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "product_tags", id: false, force: :cascade do |t|
    t.integer "product_id"
    t.integer "tag_id"
  end

  create_table "products", force: :cascade do |t|
    t.string   "name"
    t.string   "permalink"
    t.text     "description"
    t.text     "short_description"
    t.boolean  "active",                                    default: true
    t.decimal  "weight",            precision: 8, scale: 3, default: 0.0
    t.decimal  "price",             precision: 8, scale: 2, default: 0.0
    t.decimal  "cost_price",        precision: 8, scale: 2, default: 0.0
    t.decimal  "tax_rate",          precision: 8, scale: 3, default: 0.0
    t.boolean  "featured",                                  default: false
    t.datetime "created_at",                                                null: false
    t.datetime "updated_at",                                                null: false
  end

  create_table "tags", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
