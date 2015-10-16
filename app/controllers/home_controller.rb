class HomeController < ApplicationController
  before_action :init_products, :except => [:filter_product, :search_product]
  before_action :init_tags

  def index

  end

  def filter_product
    init_for_filter
    respond_to do |format|
      format.js
    end
  end

  def search_product
    init_for_filter
    respond_to do |format|
      format.js
    end
  end

  private
  def init_products
    @products = Product.active
    @filter = FilterProduct.new
  end

  def init_tags
    @tags = Tag.all
  end

  def init_for_filter
    get_product_filtered
    @filter = FilterProduct.new(get_product_filtered)
    @products = @filter.filtered_products
  end

  def get_product_filtered
    params.require(:filter_product)
  end

end
