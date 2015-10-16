class Product < ActiveRecord::Base
  has_many :category_products
  has_many :categories ,  :through => :category_products

  has_many :product_tags
  has_many :tags, :through => :product_tags

  has_many :product_images

  validates :name, :presence => true
  validates :description, :presence => true

  validates :weight, :numericality => true
  validates :price, :numericality => true
  validates :cost_price, :numericality => true, :allow_blank => true


  # All active products
  scope :active, -> { where(:active => true) }

  # All featured products
  scope :featured, -> {where(:featured => true)}

  # default ordered
  scope :ordered, -> (key=:name, direction=:asc) { order(key=>direction) unless key.blank?}

  # filter by name
  scope :name_filtered, -> (key=nil) { where( "products.name like ?", "%#{key}%") unless key.blank?}

  # default filtered
  scope :tag_filtered, -> (tags=nil) { joins(:tags).where(:tags => { :id => tags }).uniq unless tags.blank?}

  # get product tags
  #
  # @return String
  def tags_name
    tags.pluck(:name).join(", ")
  end
end
