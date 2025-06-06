require "test_helper"

class UnitTest < ActiveSupport::TestCase
  test "should belong to user" do
    unit = units(:gram)
    assert_equal users(:one), unit.user
  end

  test "should have many material quantities" do
    unit = units(:gram)
    assert_includes unit.material_quantities, material_quantities(:flour_quantity)
  end

  test "should require name" do
    unit = Unit.new(user: users(:one))
    assert_not unit.valid?
    assert_includes unit.errors[:name], "can't be blank"
  end
end
