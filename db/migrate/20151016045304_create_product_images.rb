class CreateProductImages < ActiveRecord::Migration
  def change
    create_table :product_images do |t|
      t.string :link
      t.boolean :snippet
      t.belongs_to :product
      t.timestamps null: false
    end
  end
end
