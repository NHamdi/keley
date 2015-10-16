class Category < ActiveRecord::Base
  has_many :category_products
  has_many :products ,  :through => :category_products

  validates :name, :presence => true
  validates :description, :presence => true

  # default ordered
  scope :ordered, -> { order(:name) }
end
