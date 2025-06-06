require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should have many materials" do
    user = users(:one)
    assert_includes user.materials, materials(:flour)
  end

  test "should have many products" do
    user = users(:one)
    assert_includes user.products, products(:pancake)
  end

  test "should have many units" do
    user = users(:one)
    assert_includes user.units, units(:gram)
  end

  test "should require email" do
    user = User.new(encrypted_password: "password")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "should require unique email" do
    user = User.new(email: users(:one).email, encrypted_password: "password")
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end
end
