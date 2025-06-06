class MaterialForm
  include ActiveModel::Model

  attr_accessor :material_name, :material_price, :id, :material_quantities_attributes
  attr_reader :material, :material_quantities

  validates :material_name, presence: true
  validates :material_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def initialize(attributes = {})
    super
    @material_quantities = []

    if id.present?
      @material = Material.find(id)
      self.material_name ||= @material.name
      self.material_price ||= @material.price

      if material_quantities_attributes.blank?
        @material.material_quantities.each_with_index do |mq, index|
          @material_quantities << MaterialQuantityForm.new(
            id: mq.id,
            material_count: mq.count,
            unit_id: mq.unit_id,
            index: index
          )
        end
      end
    else
      @material = Material.new
      # 新規作成時はデフォルトで一つの数量フォームを追加
      if @material_quantities.empty?
        @material_quantities << MaterialQuantityForm.new(index: 0)
      end
    end

    # material_quantities_attributesが渡された場合の処理
    if material_quantities_attributes.present?
      @material_quantities = []
      material_quantities_attributes.each do |index, attrs|
        @material_quantities << MaterialQuantityForm.new(attrs.merge(index: index))
      end
    end
  end

  def material_quantities_attributes=(attributes)
    @material_quantities_attributes = attributes
  end

  def persisted?
    @material&.persisted?
  end

  def save(user)
    return false unless valid?

    ActiveRecord::Base.transaction do
      @material.user = user
      @material.name = material_name
      @material.price = material_price

      if @material.save
        # 既存の material_quantities を削除
        @material.material_quantities.destroy_all if @material.persisted?

        # 新しい material_quantities を作成
        @material_quantities.each do |mq_form|
          if mq_form.valid_for_persistence?
            @material.material_quantities.create!(
              count: mq_form.material_count,
              unit_id: mq_form.unit_id
            )
          end
        end

        true
      else
        errors.add(:base, @material.errors.full_messages.join(", "))
        false
      end
    end
  rescue => e
    errors.add(:base, e.message)
    false
  end

  def to_model
    self
  end

  def to_key
    @material&.persisted? ? [ @material.id ] : nil
  end

  def to_param
    @material&.persisted? ? @material.id.to_s : nil
  end
end
