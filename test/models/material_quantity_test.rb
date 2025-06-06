require "test_helper"

class MaterialQuantityTest < ActiveSupport::TestCase
  test "should belong to material and unit" do
    mq = material_quantities(:flour_quantity)
    assert_equal materials(:flour), mq.material
    assert_equal units(:gram), mq.unit
  end

  test "should require count" do
    mq = MaterialQuantity.new(unit: units(:gram), material: materials(:flour))
    assert_not mq.valid?
    assert_includes mq.errors[:count], "can't be blank"
  end

  test "should require positive count" do
    mq = MaterialQuantity.new(count: 0.0, unit: units(:gram), material: materials(:flour))
    assert_not mq.valid?
    assert_includes mq.errors[:count], "must be greater than 0"
  end
end
