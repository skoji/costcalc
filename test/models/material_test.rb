require "test_helper"

class MaterialTest < ActiveSupport::TestCase
  test "should belong to user" do
    material = materials(:flour)
    assert_equal users(:one), material.user
  end

  test "should have many material quantities" do
    material = materials(:flour)
    assert_includes material.material_quantities, material_quantities(:flour_quantity)
  end

  test "should require name" do
    material = Material.new(price: 100.0, user: users(:one))
    assert_not material.valid?
    assert_includes material.errors[:name], "can't be blank"
  end

  test "should require price" do
    material = Material.new(name: "Test Material", user: users(:one))
    assert_not material.valid?
    assert_includes material.errors[:price], "can't be blank"
  end

  test "should require non-negative price" do
    material = Material.new(name: "Test Material", price: -10.0, user: users(:one))
    assert_not material.valid?
    assert_includes material.errors[:price], "must be greater than or equal to 0"
  end

  test "should calculate unit price correctly" do
    material = materials(:flour)
    unit = units(:gram)
    
    # 小麦粉: 300円/1000g = 0.3円/g
    expected_unit_price = 300.0 / 1000.0
    assert_equal expected_unit_price, material.unit_price(unit)
  end

  test "should return 0 for unit price when no quantity exists" do
    material = materials(:flour)
    unit = units(:liter)  # 小麦粉にはリットル単位の数量がない
    assert_equal 0, material.unit_price(unit)
  end
end
