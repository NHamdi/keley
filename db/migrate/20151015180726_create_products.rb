class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string   "name", :index=> true
      t.string   "permalink"
      t.text     "description", :index=> true
      t.text     "short_description"
      t.boolean  "active",                                    default: true
      t.decimal  "weight",            precision: 8, scale: 3, default: 0.0
      t.decimal  "price",             precision: 8, scale: 2, default: 0.0
      t.decimal  "cost_price",        precision: 8, scale: 2, default: 0.0
      t.decimal  "tax_rate",           precision: 8, scale: 3, default: 0.0
      t.boolean  "featured",                                  default: false
      t.timestamps null: false
    end
  end
end
