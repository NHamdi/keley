class FilterProduct
  include ActiveModel::Model
  attr_accessor :tags, :order, :key_search

  extended Product

  def initialize(attributes={})
    super
    @tags = (@tags ? @tags.reject(&:blank?).map(&:to_i) : [])
    @order ||= nil
    @key_search ||= nil
  end

  def filtered_products
    Product.ordered(@order).tag_filtered(@tags).name_filtered(key_search).active
  end

end