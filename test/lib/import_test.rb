require "test_helper"

class ImportTest < ActiveSupport::TestCase
  setup do
    @sample_db_path = Rails.root.join('tmp', 'test_legacy.sqlite3')
    create_test_legacy_database
  end

  teardown do
    File.delete(@sample_db_path) if File.exist?(@sample_db_path)
  end

  test "import:from_legacy task imports all data correctly" do
    # 既存データを削除
    clear_all_data

    # インポート実行
    ENV['LEGACY_DB_PATH'] = @sample_db_path.to_s
    ENV['FORCE'] = 'true'
    
    assert_difference 'User.count', 1 do
      assert_difference 'Unit.count', 2 do
        assert_difference 'Material.count', 2 do
          Rake::Task['import:from_legacy'].execute
        end
      end
    end

    # データの内容確認
    user = User.first
    assert_equal 'test@example.com', user.email
    assert_equal '$2a$12$test_password', user.encrypted_password

    # 関連データの確認
    assert_equal 2, user.units.count
    assert_equal 2, user.materials.count
    assert_equal 1, user.products.count

    # ビジネスロジックの確認
    product = user.products.first
    assert product.total_cost > 0
    assert product.cost_per_unit > 0

  ensure
    ENV.delete('LEGACY_DB_PATH')
    ENV.delete('FORCE')
    Rake::Task['import:from_legacy'].reenable
  end

  test "import:validate task detects integrity issues" do
    # 不正なデータを作成
    User.create!(id: 1, email: 'test@example.com', password: 'password123', password_confirmation: 'password123')
    Unit.create!(id: 1, name: 'kg', user_id: 999) # 存在しないuser_id

    output = capture_output do
      assert_raises(SystemExit) do
        Rake::Task['import:validate'].execute
      end
    end

    assert_includes output, "Found 1 units with invalid user_id"
  ensure
    Rake::Task['import:validate'].reenable
  end

  test "import:create_sample_legacy task creates valid database" do
    sample_path = Rails.root.join('tmp', 'sample_test.sqlite3')
    
    begin
      ENV['RAILS_ENV'] = 'test'
      
      # 既存ファイルを削除
      File.delete(sample_path) if File.exist?(sample_path)
      
      # タスク実行前にファイルが存在しないことを確認
      assert_not File.exist?(sample_path)
      
      # stub the sample path in the task
      original_path = Rails.root.join('tmp', 'sample_legacy.sqlite3')
      allow_any_instance_of(Object).to receive(:sample_db_path).and_return(sample_path)
      
      # タスクを実行
      Rake::Task['import:create_sample_legacy'].execute
      
      # ファイルが作成されたことを確認
      assert File.exist?(original_path)
      
      # データベースの内容を確認
      db = SQLite3::Database.new(original_path.to_s)
      db.results_as_hash = true
      
      users = db.execute("SELECT COUNT(*) as count FROM users")
      assert_equal 2, users.first['count']
      
      materials = db.execute("SELECT COUNT(*) as count FROM materials")
      assert_equal 4, materials.first['count']
      
      db.close
      
    ensure
      File.delete(sample_path) if File.exist?(sample_path)
      Rake::Task['import:create_sample_legacy'].reenable
    end
  end

  private

  def create_test_legacy_database
    File.delete(@sample_db_path) if File.exist?(@sample_db_path)
    
    db = SQLite3::Database.new(@sample_db_path.to_s)
    
    # テーブル作成
    db.execute(<<~SQL)
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email VARCHAR DEFAULT '' NOT NULL,
        encrypted_password VARCHAR DEFAULT '' NOT NULL,
        reset_password_token VARCHAR,
        reset_password_sent_at DATETIME,
        remember_created_at DATETIME,
        created_at DATETIME(6) NOT NULL,
        updated_at DATETIME(6) NOT NULL
      );
    SQL
    
    db.execute(<<~SQL)
      CREATE TABLE units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR,
        user_id INTEGER NOT NULL,
        created_at DATETIME(6) NOT NULL,
        updated_at DATETIME(6) NOT NULL
      );
    SQL
    
    db.execute(<<~SQL)
      CREATE TABLE materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR,
        price FLOAT,
        user_id INTEGER NOT NULL,
        created_at DATETIME(6) NOT NULL,
        updated_at DATETIME(6) NOT NULL
      );
    SQL
    
    db.execute(<<~SQL)
      CREATE TABLE material_quantities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        count FLOAT,
        unit_id INTEGER NOT NULL,
        material_id INTEGER NOT NULL,
        created_at DATETIME(6) NOT NULL,
        updated_at DATETIME(6) NOT NULL
      );
    SQL
    
    db.execute(<<~SQL)
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR,
        count FLOAT,
        user_id INTEGER NOT NULL,
        created_at DATETIME(6) NOT NULL,
        updated_at DATETIME(6) NOT NULL
      );
    SQL
    
    db.execute(<<~SQL)
      CREATE TABLE product_ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        material_id INTEGER NOT NULL,
        unit_id INTEGER NOT NULL,
        count FLOAT,
        created_at DATETIME(6) NOT NULL,
        updated_at DATETIME(6) NOT NULL
      );
    SQL
    
    # テストデータ
    now = Time.current.strftime('%Y-%m-%d %H:%M:%S.%6N')
    
    db.execute(<<~SQL)
      INSERT INTO users (id, email, encrypted_password, created_at, updated_at)
      VALUES (1, 'test@example.com', '$2a$12$test_password', '#{now}', '#{now}');
    SQL
    
    db.execute(<<~SQL)
      INSERT INTO units (id, name, user_id, created_at, updated_at)
      VALUES 
        (1, 'g', 1, '#{now}', '#{now}'),
        (2, 'ml', 1, '#{now}', '#{now}');
    SQL
    
    db.execute(<<~SQL)
      INSERT INTO materials (id, name, price, user_id, created_at, updated_at)
      VALUES 
        (1, '小麦粉', 200.0, 1, '#{now}', '#{now}'),
        (2, '牛乳', 150.0, 1, '#{now}', '#{now}');
    SQL
    
    db.execute(<<~SQL)
      INSERT INTO material_quantities (id, count, unit_id, material_id, created_at, updated_at)
      VALUES 
        (1, 1000.0, 1, 1, '#{now}', '#{now}'),
        (2, 1000.0, 2, 2, '#{now}', '#{now}');
    SQL
    
    db.execute(<<~SQL)
      INSERT INTO products (id, name, count, user_id, created_at, updated_at)
      VALUES (1, 'パンケーキ', 10.0, 1, '#{now}', '#{now}');
    SQL
    
    db.execute(<<~SQL)
      INSERT INTO product_ingredients (id, product_id, material_id, unit_id, count, created_at, updated_at)
      VALUES 
        (1, 1, 1, 1, 200.0, '#{now}', '#{now}'),
        (2, 1, 2, 2, 300.0, '#{now}', '#{now}');
    SQL
    
    db.close
  end

  def clear_all_data
    ProductIngredient.delete_all
    MaterialQuantity.delete_all
    Product.delete_all
    Material.delete_all
    Unit.delete_all
    User.delete_all
  end

  def capture_output
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end