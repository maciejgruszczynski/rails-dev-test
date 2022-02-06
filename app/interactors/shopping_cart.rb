# frozen_string_literal: true

class ShoppingCart
  include Dry::Monads[:result]

  attr_reader :cart, :cart_identifier

  def initialize(cart_identifier = nil)
    @cart_identifier = cart_identifier
    @cart = build_cart
  end

  def add_item(product_id:, quantity:)
    if new_product?(product_id: product_id)
      ShoppingCart::Services::AddItem.new.call(
        cart: cart,
        product_id: product_id,
        quantity: quantity
      )
    else
      ShoppingCart::Services::UpdateItem.new.call(
        cart: cart,
        product_id: product_id,
        quantity: quantity
      )
    end
  end

  def remove_item(product_id:)
    ShoppingCart::Services::RemoveItem.new.call(
      cart: cart,
      product_id: product_id
    )
  end

  def items
    cart.cart_items
  end

  def items_count
    cart.cart_items.sum(:quantity)
  end

  def value
    Money.new(cart.cart_items.sum(:price_cents))
  end

  private

  def build_cart
    existing_cart = find_cart

    existing_cart.presence || create_cart
  end

  def find_cart
    Cart.where(identifier: cart_identifier).first
  end

  def new_product?(product_id:)
    cart.cart_items.where(product_id: product_id).empty?
  end

  def create_cart
    identifier = (0...10).map { ('a'..'z').to_a[rand(26)] }.join
    Cart.create!(identifier: cart_identifier)
  end
end
