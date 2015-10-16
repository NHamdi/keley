User.create!([
  {email: "hamdi@gmail.com", encrypted_password: "$2a$10$jNtJCMTXgkJx6sCrPrIRF.ycTeHeyTzIhfQFToUYjebN3fxva7dBy", reset_password_token: nil, reset_password_sent_at: nil, remember_created_at: nil, sign_in_count: 7, current_sign_in_at: "2015-10-16 04:31:25", last_sign_in_at: "2015-10-16 04:21:47", current_sign_in_ip: "::1", last_sign_in_ip: "::1"}
])
Category.create!([
  {name: "Category 1", permalink: nil, description: "description 1", parent_id: nil},
  {name: "Category 2", permalink: nil, description: "description 2", parent_id: nil},
  {name: "category 5", permalink: nil, description: "description 3", parent_id: nil},
  {name: "category 5", permalink: nil, description: "description 4", parent_id: nil}
])
CategoryProduct.create!([
  {category_id: 1, product_id: 1},
  {category_id: 1, product_id: 2},
  {category_id: 1, product_id: 3},
  {category_id: 2, product_id: 1},
  {category_id: 2, product_id: 2},
  {category_id: 2, product_id: 3}
])
Product.create!([
  {name: "produit 1", permalink: nil, description: "description 1", short_description: nil, active: true, weight: "1.0", price: "12.0", cost_price: "11.0", tax_rate: "0.0", featured: false},
  {name: "produit 2", permalink: nil, description: "description 2", short_description: nil, active: true, weight: "1.0", price: "12.0", cost_price: "11.0", tax_rate: "0.0", featured: false},
  {name: "produit 3", permalink: nil, description: "description 3", short_description: nil, active: true, weight: "1.0", price: "12.0", cost_price: "11.0", tax_rate: "0.0", featured: false},
  {name: "Produit 4", permalink: nil, description: "description 4", short_description: nil, active: true, weight: "0.0", price: "0.0", cost_price: "0.0", tax_rate: "0.0", featured: false}
])
ProductImage.create!([
  {link: "produit.jpg", snippet: true, product_id: 1},
  {link: "produit.jpg", snippet: true, product_id: 1},
  {link: "produit.jpg", snippet: true, product_id: 2},
  {link: "produit.jpg", snippet: true, product_id: 2},
  {link: "produit.jpg", snippet: true, product_id: 3},
  {link: "produit.jpg", snippet: true, product_id: 3},
  {link: "produit.jpg", snippet: true, product_id: 4},
  {link: "produit.jpg", snippet: true, product_id: 4},
  {link: "produit.jpg", snippet: true, product_id: 5},
  {link: "produit.jpg", snippet: true, product_id: 5}
])
ProductTag.create!([
  {product_id: 1, tag_id: 1},
  {product_id: 1, tag_id: 2},
  {product_id: 3, tag_id: 2},
  {product_id: 3, tag_id: 3},
  {product_id: 2, tag_id: 1},
  {product_id: 2, tag_id: 3}
])
Tag.create!([
  {name: "Tag1"},
  {name: "Tag2"},
  {name: "Tag3"}
])
