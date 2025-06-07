class ProductIngredientForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_reader :product_ingredient

  attribute :ingredient_count, :decimal
  attribute :unit_id, :integer
  attribute :material_id, :integer
  attribute :id, :integer
  attribute :delete, :string

  def initialize(attr = {})
    if attr.is_a?(ProductIngredient)
      # ProductIngredient オブジェクトから初期化
      @product_ingredient = attr
      super(
        id: attr.id,
        ingredient_count: attr.count,
        unit_id: attr.unit&.id,
        material_id: attr.material&.id
      )
    elsif attr[:id].present?
      # IDから既存レコードを取得
      @product_ingredient = ProductIngredient.find(attr[:id])
      super(attr)
      self.ingredient_count ||= @product_ingredient.count
      self.unit_id ||= @product_ingredient.unit&.id
      self.material_id ||= @product_ingredient.material&.id
    else
      # 新規作成
      @product_ingredient = ProductIngredient.new
      super(attr)
    end
  end

  def persist!(product)
    # 削除フラグが立っている場合は何もしない
    # (削除処理はProductFormで行われる)
    if delete == "1"
      return
    end

    # material_id が無効な場合はスキップ
    return if material_id.blank? || material_id.to_i <= 0

    material = Material.find_by(id: material_id)
    return unless material

    unit = Unit.find_by(id: unit_id)
    return unless unit

    if @product_ingredient.new_record?
      @product_ingredient = ProductIngredient.new(
        material: material,
        unit: unit,
        count: ingredient_count,
        product: product
      )
    else
      @product_ingredient.material = material
      @product_ingredient.unit = unit
      @product_ingredient.count = ingredient_count
      @product_ingredient.product = product
    end
    @product_ingredient.save!
  end

  def material_name
    @product_ingredient&.material&.name
  end

  def unit_name
    @product_ingredient&.unit&.name
  end
end
