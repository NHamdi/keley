class CreateCategoryProducts < ActiveRecord::Migration
  def change
    create_table :category_products, :id => false do |t|
      t.belongs_to :category
      t.belongs_to :product
    end
  end
end
