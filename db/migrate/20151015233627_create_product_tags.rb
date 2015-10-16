class CreateProductTags < ActiveRecord::Migration
  def change
    create_table :product_tags, :id=>false do |t|
      t.belongs_to :product
      t.belongs_to :tag
    end
  end
end
