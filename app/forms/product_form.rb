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
    return if attributes.blank?

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
    # First set the attributes using ActiveModel::Model
    super(attr)

    if attr[:id].present?
      @product = Product.find(attr[:id])
    else
      @product = Product.new
    end

    # Set the basic attributes
    self.product_name ||= @product.name
    self.product_count ||= @product.count

    # Handle product ingredients
    if attr[:product_ingredients_attributes].present?
      # Use the setter method which properly handles the attributes
      self.product_ingredients_attributes = attr[:product_ingredients_attributes]
    elsif @product.persisted?
      # Load existing ingredients for editing
      @product_ingredients = @product.product_ingredients.includes(:material, :unit).map { |pi| ProductIngredientForm.new(pi) }
    else
      # New product with no ingredients
      @product_ingredients = []
    end
  end

  def persist!(current_user)
    @product.user = current_user
    @product.name = product_name
    @product.count = product_count

    ActiveRecord::Base.transaction do
      @product.save!

      # Handle product ingredients - update, create, or delete as needed
      if @product_ingredients.present?
        # Delete ingredients that are marked for deletion or not in the form
        @product.product_ingredients.each do |existing_ingredient|
          ingredient_form = @product_ingredients.find { |pi| pi.id.to_s == existing_ingredient.id.to_s }
          if ingredient_form.nil? || ingredient_form.delete == "1"
            existing_ingredient.destroy
          end
        end

        # Update or create ingredients
        @product_ingredients.each do |ingredient_form|
          next if ingredient_form.delete == "1"
          next if ingredient_form.material_id.blank? || ingredient_form.ingredient_count.blank?

          if ingredient_form.id.present?
            # Update existing ingredient
            existing = @product.product_ingredients.find_by(id: ingredient_form.id)
            if existing
              existing.update!(
                material_id: ingredient_form.material_id,
                count: ingredient_form.ingredient_count,
                unit_id: ingredient_form.unit_id
              )
            end
          else
            # Create new ingredient
            @product.product_ingredients.create!(
              material_id: ingredient_form.material_id,
              count: ingredient_form.ingredient_count,
              unit_id: ingredient_form.unit_id
            )
          end
        end
      else
        # If no ingredients provided, don't delete existing ones
        # This preserves existing ingredients when form data is missing
      end
    end
  end

  def to_key
    [ @product&.id ]
  end

  def to_param
    @product&.id&.to_s
  end
end
