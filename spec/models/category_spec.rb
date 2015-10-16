require 'spec_helper'


describe Category do
    subject(:Category) { FactoryGirl.build(:Category, name: nil)}
    it {expect(restaurant.valid?).to be_false}
end