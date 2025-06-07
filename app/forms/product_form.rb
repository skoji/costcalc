class ProductForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_reader :product

  attribute :product_name, :string
  attribute :product_count, :decimal
  attribute :id, :integer

  def product_ingredients
    @product_ingredients ||= []
  end

  def product_ingredients_attributes=(attributes)
    attrs = attributes.respond_to?(:to_h) ? attributes.to_h : attributes
    @product_ingredients = attrs.map do |_i, attribute|
      ProductIngredientForm.new(attribute)
    end
  end

  def add_product_ingredient(ingredient)
    @product_ingredients << ingredient
  end

  def persisted?
    @product&.persisted?
  end

  def initialize(attr = {})
    if attr[:id].present?
      @product = Product.find(attr[:id])
      if attr[:product_ingredients_attributes]
        ingredients_attrs = attr[:product_ingredients_attributes]
        ingredients_attrs = ingredients_attrs.to_h if ingredients_attrs.respond_to?(:to_h)
        @product_ingredients = ingredients_attrs.map do |_i, p|
          ProductIngredientForm.new(p)
        end
      else
        @product_ingredients = @product.product_ingredients.map { |q| ProductIngredientForm.new(q) }
      end
    else
      @product = Product.new
      if attr[:product_ingredients_attributes]
        ingredients_attrs = attr[:product_ingredients_attributes]
        ingredients_attrs = ingredients_attrs.to_h if ingredients_attrs.respond_to?(:to_h)
        @product_ingredients = ingredients_attrs.map do |_i, p|
          ProductIngredientForm.new(p)
        end
      else
        @product_ingredients = []
      end
    end

    super(attr)

    self.product_name ||= @product.name
    self.product_count ||= @product.count
  end

  def persist!(current_user)
    @product.user = current_user
    @product.name = product_name
    @product.count = product_count

    # 既存の ingredients を削除
    @product.product_ingredients.destroy_all if @product.persisted?

    # 新しい ingredients を追加
    @product_ingredients.each do |p|
      p.persist!(@product)
    end

    @product.save!
  end

  def to_key
    [ @product&.id ]
  end

  def to_param
    @product&.id&.to_s
  end
end