class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories, :force => true do |t|
      t.string   "name", :index=> true
      t.string   "permalink"
      t.text     "description", :index=> true
      t.integer  "parent_id"
      t.timestamps null: false
    end
  end
end
