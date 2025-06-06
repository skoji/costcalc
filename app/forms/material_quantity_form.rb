class MaterialQuantityForm
  include ActiveModel::Model

  attr_accessor :id, :material_count, :unit_id, :index, :_destroy

  validates :material_count, numericality: { greater_than: 0 }, allow_blank: true
  validates :unit_id, presence: true, if: -> { material_count.present? }

  def initialize(attributes = {})
    super
    @index = attributes[:index] || 0
  end

  def valid_for_persistence?
    material_count.present? && material_count.to_f > 0 && unit_id.present? && !_destroy
  end

  def persisted?
    id.present?
  end
end
