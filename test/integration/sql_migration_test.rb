require "test_helper"

class SqlMigrationTest < ActionDispatch::IntegrationTest
  test "can execute legacy-style SQL insertions" do
    # 既存データベースから取得したようなSQLでの挿入テスト

    # users テーブルへの挿入（Deviseスタイル）
    ActiveRecord::Base.connection.execute(<<~SQL)
      INSERT INTO users (id, email, encrypted_password, reset_password_token, reset_password_sent_at, remember_created_at, created_at, updated_at)
      VALUES (1, 'migrated@example.com', '$2a$12$test_encrypted_password', NULL, NULL, NULL, '2019-09-25 06:35:42.123456', '2019-09-25 06:35:42.123456');
    SQL

    # units テーブルへの挿入
    ActiveRecord::Base.connection.execute(<<~SQL)
      INSERT INTO units (id, name, user_id, created_at, updated_at)
      VALUES (1, 'kg', 1, '2019-09-25 06:35:42.123456', '2019-09-25 06:35:42.123456');
    SQL

    # materials テーブルへの挿入
    ActiveRecord::Base.connection.execute(<<~SQL)
      INSERT INTO materials (id, name, price, user_id, created_at, updated_at)
      VALUES (1, 'レガシー材料', 250.5, 1, '2019-09-25 06:35:42.123456', '2019-09-25 06:35:42.123456');
    SQL

    # material_quantities テーブルへの挿入
    ActiveRecord::Base.connection.execute(<<~SQL)
      INSERT INTO material_quantities (id, count, unit_id, material_id, created_at, updated_at)
      VALUES (1, 1000.0, 1, 1, '2019-09-25 06:35:42.123456', '2019-09-25 06:35:42.123456');
    SQL

    # products テーブルへの挿入
    ActiveRecord::Base.connection.execute(<<~SQL)
      INSERT INTO products (id, name, count, user_id, created_at, updated_at)
      VALUES (1, 'レガシー製品', 20.0, 1, '2019-09-25 06:35:42.123456', '2019-09-25 06:35:42.123456');
    SQL

    # product_ingredients テーブルへの挿入
    ActiveRecord::Base.connection.execute(<<~SQL)
      INSERT INTO product_ingredients (id, product_id, material_id, unit_id, count, created_at, updated_at)
      VALUES (1, 1, 1, 1, 500.0, '2019-09-25 06:35:42.123456', '2019-09-25 06:35:42.123456');
    SQL

    # Rails 8のActiveRecordで正しく読み取れることを確認
    user = User.find(1)
    assert_equal "migrated@example.com", user.email
    assert_equal "$2a$12$test_encrypted_password", user.encrypted_password

    unit = Unit.find(1)
    assert_equal "kg", unit.name
    assert_equal user, unit.user

    material = Material.find(1)
    assert_equal "レガシー材料", material.name
    assert_equal 250.5, material.price
    assert_equal user, material.user

    material_quantity = MaterialQuantity.find(1)
    assert_equal 1000.0, material_quantity.count
    assert_equal unit, material_quantity.unit
    assert_equal material, material_quantity.material

    product = Product.find(1)
    assert_equal "レガシー製品", product.name
    assert_equal 20.0, product.count
    assert_equal user, product.user

    product_ingredient = ProductIngredient.find(1)
    assert_equal product, product_ingredient.product
    assert_equal material, product_ingredient.material
    assert_equal unit, product_ingredient.unit
    assert_equal 500.0, product_ingredient.count

    # ビジネスロジックの動作確認
    # 材料単価: 250.5円/1000g = 0.2505円/g
    # 使用量: 500g
    # 材料コスト: 0.2505 * 500 = 125.25円
    # 1個あたり: 125.25円 / 20個 = 6.2625円/個
    expected_unit_price = 250.5 / 1000.0
    expected_total_cost = expected_unit_price * 500.0
    expected_cost_per_unit = expected_total_cost / 20.0

    assert_in_delta expected_unit_price, material.unit_price(unit), 0.0001
    assert_in_delta expected_total_cost, product.total_cost, 0.01
    assert_in_delta expected_cost_per_unit, product.cost_per_unit, 0.0001

    # 関連の確認
    assert_equal [ material ], user.materials.to_a
    assert_equal [ product ], user.products.to_a
    assert_equal [ unit ], user.units.to_a
    assert_equal [ material_quantity ], material.material_quantities.to_a
    assert_equal [ product_ingredient ], product.product_ingredients.to_a
  end

  test "preserves legacy timestamp precision" do
    # Rails 6.0のprecision: 6に対応したタイムスタンプのテスト

    timestamp_with_microseconds = "2019-09-25 06:35:42.123456"

    ActiveRecord::Base.connection.execute(<<~SQL)
      INSERT INTO users (id, email, encrypted_password, created_at, updated_at)
      VALUES (2, 'timestamp@example.com', 'password', '#{timestamp_with_microseconds}', '#{timestamp_with_microseconds}');
    SQL

    user = User.find(2)

    # マイクロ秒精度が保持されていることを確認
    expected_time = Time.parse(timestamp_with_microseconds + " UTC")
    assert_equal expected_time.to_s, user.created_at.to_s
    assert_equal expected_time.to_s, user.updated_at.to_s
  end

  test "handles legacy foreign key relationships" do
    # 外部キー制約が正しく動作することを確認

    # ユーザー作成
    ActiveRecord::Base.connection.execute(<<~SQL)
      INSERT INTO users (id, email, encrypted_password, created_at, updated_at)
      VALUES (3, 'fk_test@example.com', 'password', '2019-09-25 06:35:42.123456', '2019-09-25 06:35:42.123456');
    SQL

    # 存在しないユーザーIDでの材料作成は失敗することを確認
    assert_raises(ActiveRecord::InvalidForeignKey) do
      ActiveRecord::Base.connection.execute(<<~SQL)
        INSERT INTO materials (id, name, price, user_id, created_at, updated_at)
        VALUES (999, 'Invalid Material', 100.0, 999, '2019-09-25 06:35:42.123456', '2019-09-25 06:35:42.123456');
      SQL
    end

    # 正しいユーザーIDでの材料作成は成功することを確認
    assert_nothing_raised do
      ActiveRecord::Base.connection.execute(<<~SQL)
        INSERT INTO materials (id, name, price, user_id, created_at, updated_at)
        VALUES (3, 'Valid Material', 100.0, 3, '2019-09-25 06:35:42.123456', '2019-09-25 06:35:42.123456');
      SQL
    end

    # 参照整合性が保たれることを確認
    material = Material.find(3)
    user = User.find(3)
    assert_equal user, material.user
  end
end
