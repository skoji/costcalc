namespace :import do
  desc "Import data from legacy costcalc application"
  task from_legacy: :environment do
    legacy_db_path = ENV["LEGACY_DB_PATH"]

    if legacy_db_path.blank?
      puts "Error: LEGACY_DB_PATH environment variable is required"
      puts "Usage: LEGACY_DB_PATH=/path/to/legacy/db/development.sqlite3 bin/rails import:from_legacy"
      exit 1
    end

    unless File.exist?(legacy_db_path)
      puts "Error: Legacy database file not found: #{legacy_db_path}"
      exit 1
    end

    puts "Starting import from legacy database: #{legacy_db_path}"

    # 既存データを削除（確認プロンプト）
    unless Rails.env.test? || ENV["FORCE"] == "true"
      print "This will delete all existing data. Continue? (y/N): "
      response = STDIN.gets
      unless response&.chomp&.downcase == "y"
        puts "Import cancelled."
        exit 0
      end
    end

    # 現在のデータを削除
    puts "Clearing existing data..."
    ProductIngredient.delete_all
    MaterialQuantity.delete_all
    Product.delete_all
    Material.delete_all
    Unit.delete_all
    User.delete_all

    # レガシーDBに接続
    legacy_db = SQLite3::Database.new(legacy_db_path)
    legacy_db.results_as_hash = true

    ActiveRecord::Base.transaction do
      # ユーザーのインポート
      puts "Importing users..."
      users_sql = "SELECT * FROM users ORDER BY id"
      legacy_db.execute(users_sql) do |row|
        user = User.new(
          id: row["id"],
          email: row["email"],
          reset_password_token: row["reset_password_token"],
          reset_password_sent_at: row["reset_password_sent_at"] ? Time.parse(row["reset_password_sent_at"]) : nil,
          remember_created_at: row["remember_created_at"] ? Time.parse(row["remember_created_at"]) : nil,
          created_at: Time.parse(row["created_at"]),
          updated_at: Time.parse(row["updated_at"])
        )
        # encrypted_passwordを直接設定
        user.encrypted_password = row["encrypted_password"]
        user.save!(validate: false)
      end
      puts "Imported #{User.count} users"

      # 単位のインポート
      puts "Importing units..."
      units_sql = "SELECT * FROM units ORDER BY id"
      legacy_db.execute(units_sql) do |row|
        Unit.create!(
          id: row["id"],
          name: row["name"],
          user_id: row["user_id"],
          created_at: Time.parse(row["created_at"]),
          updated_at: Time.parse(row["updated_at"])
        )
      end
      puts "Imported #{Unit.count} units"

      # 材料のインポート
      puts "Importing materials..."
      materials_sql = "SELECT * FROM materials ORDER BY id"
      legacy_db.execute(materials_sql) do |row|
        Material.create!(
          id: row["id"],
          name: row["name"],
          price: row["price"],
          user_id: row["user_id"],
          created_at: Time.parse(row["created_at"]),
          updated_at: Time.parse(row["updated_at"])
        )
      end
      puts "Imported #{Material.count} materials"

      # 材料数量のインポート
      puts "Importing material quantities..."
      material_quantities_sql = "SELECT * FROM material_quantities ORDER BY id"
      fixed_mq = 0
      legacy_db.execute(material_quantities_sql) do |row|
        # countがNULLまたは0以下の場合は1.0で置き換え
        count_value = row["count"]
        if count_value.nil? || count_value.to_f <= 0
          puts "  Fixing material_quantity ID #{row['id']}: invalid count (#{count_value}) -> 1.0"
          count_value = 1.0
          fixed_mq += 1
        end

        MaterialQuantity.create!(
          id: row["id"],
          count: count_value,
          unit_id: row["unit_id"],
          material_id: row["material_id"],
          created_at: Time.parse(row["created_at"]),
          updated_at: Time.parse(row["updated_at"])
        )
      end
      puts "Imported #{MaterialQuantity.count} material quantities (fixed #{fixed_mq} invalid records)"

      # 製品のインポート
      puts "Importing products..."
      products_sql = "SELECT * FROM products ORDER BY id"
      fixed_products = 0
      legacy_db.execute(products_sql) do |row|
        # nameがNULLまたは空の場合は「無名製品」で置き換え
        name_value = row["name"]
        if name_value.nil? || name_value.to_s.strip.empty?
          puts "  Fixing product ID #{row['id']}: invalid name (#{name_value}) -> '無名製品'"
          name_value = "無名製品"
          fixed_products += 1
        end

        # countがNULLまたは0以下の場合は1.0で置き換え
        count_value = row["count"]
        if count_value.nil? || count_value.to_f <= 0
          puts "  Fixing product ID #{row['id']}: invalid count (#{count_value}) -> 1.0"
          count_value = 1.0
          fixed_products += 1
        end

        Product.create!(
          id: row["id"],
          name: name_value,
          count: count_value,
          user_id: row["user_id"],
          created_at: Time.parse(row["created_at"]),
          updated_at: Time.parse(row["updated_at"])
        )
      end
      puts "Imported #{Product.count} products (fixed #{fixed_products} invalid records)"

      # 製品原材料のインポート
      puts "Importing product ingredients..."
      product_ingredients_sql = "SELECT * FROM product_ingredients ORDER BY id"
      fixed_pi = 0
      legacy_db.execute(product_ingredients_sql) do |row|
        # countがNULLまたは0以下の場合は1.0で置き換え
        count_value = row["count"]
        if count_value.nil? || count_value.to_f <= 0
          puts "  Fixing product_ingredient ID #{row['id']}: invalid count (#{count_value}) -> 1.0"
          count_value = 1.0
          fixed_pi += 1
        end

        ProductIngredient.create!(
          id: row["id"],
          product_id: row["product_id"],
          material_id: row["material_id"],
          unit_id: row["unit_id"],
          count: count_value,
          created_at: Time.parse(row["created_at"]),
          updated_at: Time.parse(row["updated_at"])
        )
      end
      puts "Imported #{ProductIngredient.count} product ingredients (fixed #{fixed_pi} invalid records)"

      # シーケンスの更新（PostgreSQLの場合のみ必要だが、SQLiteでは不要）
      # SQLiteはAUTOINCREMENTが自動的に最大値+1を使用する

      puts "\nImport completed successfully!"
      puts "Summary:"
      puts "  Users: #{User.count}"
      puts "  Units: #{Unit.count}"
      puts "  Materials: #{Material.count}"
      puts "  Material Quantities: #{MaterialQuantity.count}"
      puts "  Products: #{Product.count}"
      puts "  Product Ingredients: #{ProductIngredient.count}"
    end

    legacy_db.close
  end

  desc "Import from legacy database with SQL dump method"
  task from_sql_dump: :environment do
    sql_dump_path = ENV["SQL_DUMP_PATH"]

    if sql_dump_path.blank?
      puts "Error: SQL_DUMP_PATH environment variable is required"
      puts "Usage: SQL_DUMP_PATH=/path/to/dump.sql bin/rails import:from_sql_dump"
      exit 1
    end

    unless File.exist?(sql_dump_path)
      puts "Error: SQL dump file not found: #{sql_dump_path}"
      exit 1
    end

    puts "Starting import from SQL dump: #{sql_dump_path}"

    # 既存データを削除（確認プロンプト）
    unless Rails.env.test? || ENV["FORCE"] == "true"
      print "This will delete all existing data. Continue? (y/N): "
      response = STDIN.gets
      unless response&.chomp&.downcase == "y"
        puts "Import cancelled."
        exit 0
      end
    end

    # 現在のデータを削除
    puts "Clearing existing data..."
    ProductIngredient.delete_all
    MaterialQuantity.delete_all
    Product.delete_all
    Material.delete_all
    Unit.delete_all
    User.delete_all

    # SQLダンプを実行
    puts "Executing SQL dump..."
    sql_content = File.read(sql_dump_path)

    # SQLiteの制約を一時的に無効化
    ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = OFF")

    begin
      ActiveRecord::Base.transaction do
        # INSERT文のみを実行（CREATE TABLEなどは除外）
        sql_statements = sql_content.split(";").map(&:strip).select do |statement|
          statement.upcase.start_with?("INSERT INTO")
        end

        sql_statements.each do |statement|
          next if statement.blank?
          ActiveRecord::Base.connection.execute(statement + ";")
        end

        puts "Import completed successfully!"
        puts "Summary:"
        puts "  Users: #{User.count}"
        puts "  Units: #{Unit.count}"
        puts "  Materials: #{Material.count}"
        puts "  Material Quantities: #{MaterialQuantity.count}"
        puts "  Products: #{Product.count}"
        puts "  Product Ingredients: #{ProductIngredient.count}"
      end
    ensure
      # 制約を再度有効化
      ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON")
    end
  end

  desc "Validate imported data integrity"
  task validate: :environment do
    puts "Validating imported data integrity..."

    errors = []

    # 基本的なカウント
    puts "Record counts:"
    puts "  Users: #{User.count}"
    puts "  Units: #{Unit.count}"
    puts "  Materials: #{Material.count}"
    puts "  Material Quantities: #{MaterialQuantity.count}"
    puts "  Products: #{Product.count}"
    puts "  Product Ingredients: #{ProductIngredient.count}"

    # 関連の整合性チェック
    puts "\nValidating relationships..."

    # 孤児レコードのチェック
    orphaned_units = Unit.where.not(user_id: User.pluck(:id))
    if orphaned_units.any?
      errors << "Found #{orphaned_units.count} units with invalid user_id"
    end

    orphaned_materials = Material.where.not(user_id: User.pluck(:id))
    if orphaned_materials.any?
      errors << "Found #{orphaned_materials.count} materials with invalid user_id"
    end

    orphaned_products = Product.where.not(user_id: User.pluck(:id))
    if orphaned_products.any?
      errors << "Found #{orphaned_products.count} products with invalid user_id"
    end

    orphaned_mq = MaterialQuantity.where.not(material_id: Material.pluck(:id))
    if orphaned_mq.any?
      errors << "Found #{orphaned_mq.count} material quantities with invalid material_id"
    end

    orphaned_mq_units = MaterialQuantity.where.not(unit_id: Unit.pluck(:id))
    if orphaned_mq_units.any?
      errors << "Found #{orphaned_mq_units.count} material quantities with invalid unit_id"
    end

    orphaned_pi = ProductIngredient.where.not(product_id: Product.pluck(:id))
    if orphaned_pi.any?
      errors << "Found #{orphaned_pi.count} product ingredients with invalid product_id"
    end

    orphaned_pi_materials = ProductIngredient.where.not(material_id: Material.pluck(:id))
    if orphaned_pi_materials.any?
      errors << "Found #{orphaned_pi_materials.count} product ingredients with invalid material_id"
    end

    orphaned_pi_units = ProductIngredient.where.not(unit_id: Unit.pluck(:id))
    if orphaned_pi_units.any?
      errors << "Found #{orphaned_pi_units.count} product ingredients with invalid unit_id"
    end

    # バリデーションエラーのチェック
    puts "Validating model constraints..."

    [ User, Unit, Material, MaterialQuantity, Product, ProductIngredient ].each do |model|
      invalid_records = model.all.reject(&:valid?)
      if invalid_records.any?
        errors << "Found #{invalid_records.count} invalid #{model.name.pluralize}"
        invalid_records.each do |record|
          errors << "  #{model.name} ID #{record.id}: #{record.errors.full_messages.join(', ')}"
        end
      end
    end

    # 結果出力
    if errors.empty?
      puts "\n✅ All data is valid!"
    else
      puts "\n❌ Validation errors found:"
      errors.each { |error| puts "  - #{error}" }
      exit 1
    end
  end

  desc "Create sample legacy database for testing"
  task create_sample_legacy: :environment do
    sample_db_path = Rails.root.join("tmp", "sample_legacy.sqlite3")

    puts "Creating sample legacy database at: #{sample_db_path}"

    # サンプルDBを作成
    File.delete(sample_db_path) if File.exist?(sample_db_path)

    sample_db = SQLite3::Database.new(sample_db_path.to_s)

    # テーブル作成（レガシー形式）
    sample_db.execute(<<~SQL)
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

    sample_db.execute("CREATE UNIQUE INDEX index_users_on_email ON users(email);")
    sample_db.execute("CREATE UNIQUE INDEX index_users_on_reset_password_token ON users(reset_password_token);")

    sample_db.execute(<<~SQL)
      CREATE TABLE units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR,
        user_id INTEGER NOT NULL,
        created_at DATETIME(6) NOT NULL,
        updated_at DATETIME(6) NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
    SQL

    sample_db.execute("CREATE INDEX index_units_on_user_id ON units(user_id);")

    sample_db.execute(<<~SQL)
      CREATE TABLE materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR,
        price FLOAT,
        user_id INTEGER NOT NULL,
        created_at DATETIME(6) NOT NULL,
        updated_at DATETIME(6) NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
    SQL

    sample_db.execute("CREATE INDEX index_materials_on_user_id ON materials(user_id);")

    sample_db.execute(<<~SQL)
      CREATE TABLE material_quantities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        count FLOAT,
        unit_id INTEGER NOT NULL,
        material_id INTEGER NOT NULL,
        created_at DATETIME(6) NOT NULL,
        updated_at DATETIME(6) NOT NULL,
        FOREIGN KEY (unit_id) REFERENCES units(id),
        FOREIGN KEY (material_id) REFERENCES materials(id)
      );
    SQL

    sample_db.execute("CREATE INDEX index_material_quantities_on_unit_id ON material_quantities(unit_id);")
    sample_db.execute("CREATE INDEX index_material_quantities_on_material_id ON material_quantities(material_id);")

    sample_db.execute(<<~SQL)
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR,
        count FLOAT,
        user_id INTEGER NOT NULL,
        created_at DATETIME(6) NOT NULL,
        updated_at DATETIME(6) NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
    SQL

    sample_db.execute("CREATE INDEX index_products_on_user_id ON products(user_id);")

    sample_db.execute(<<~SQL)
      CREATE TABLE product_ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        material_id INTEGER NOT NULL,
        unit_id INTEGER NOT NULL,
        count FLOAT,
        created_at DATETIME(6) NOT NULL,
        updated_at DATETIME(6) NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products(id),
        FOREIGN KEY (material_id) REFERENCES materials(id),
        FOREIGN KEY (unit_id) REFERENCES units(id)
      );
    SQL

    sample_db.execute("CREATE INDEX index_product_ingredients_on_product_id ON product_ingredients(product_id);")
    sample_db.execute("CREATE INDEX index_product_ingredients_on_material_id ON product_ingredients(material_id);")
    sample_db.execute("CREATE INDEX index_product_ingredients_on_unit_id ON product_ingredients(unit_id);")

    # サンプルデータの挿入
    now = Time.current.strftime("%Y-%m-%d %H:%M:%S.%6N")

    # ユーザー
    sample_db.execute(<<~SQL)
      INSERT INTO users (id, email, encrypted_password, created_at, updated_at)
      VALUES#{' '}
        (1, 'baker@example.com', '$2a$12$encrypted_password_hash_1', '#{now}', '#{now}'),
        (2, 'chef@example.com', '$2a$12$encrypted_password_hash_2', '#{now}', '#{now}');
    SQL

    # 単位
    sample_db.execute(<<~SQL)
      INSERT INTO units (id, name, user_id, created_at, updated_at)
      VALUES#{' '}
        (1, 'g', 1, '#{now}', '#{now}'),
        (2, 'ml', 1, '#{now}', '#{now}'),
        (3, 'kg', 2, '#{now}', '#{now}'),
        (4, 'L', 2, '#{now}', '#{now}');
    SQL

    # 材料
    sample_db.execute(<<~SQL)
      INSERT INTO materials (id, name, price, user_id, created_at, updated_at)
      VALUES#{' '}
        (1, '小麦粉', 300.0, 1, '#{now}', '#{now}'),
        (2, '牛乳', 180.0, 1, '#{now}', '#{now}'),
        (3, '砂糖', 200.0, 2, '#{now}', '#{now}'),
        (4, 'バター', 500.0, 2, '#{now}', '#{now}');
    SQL

    # 材料数量
    sample_db.execute(<<~SQL)
      INSERT INTO material_quantities (id, count, unit_id, material_id, created_at, updated_at)
      VALUES#{' '}
        (1, 1000.0, 1, 1, '#{now}', '#{now}'),
        (2, 1000.0, 2, 2, '#{now}', '#{now}'),
        (3, 1.0, 3, 3, '#{now}', '#{now}'),
        (4, 200.0, 1, 4, '#{now}', '#{now}');
    SQL

    # 製品
    sample_db.execute(<<~SQL)
      INSERT INTO products (id, name, count, user_id, created_at, updated_at)
      VALUES#{' '}
        (1, 'パンケーキ', 10.0, 1, '#{now}', '#{now}'),
        (2, 'カスタードプリン', 8.0, 2, '#{now}', '#{now}');
    SQL

    # 製品原材料
    sample_db.execute(<<~SQL)
      INSERT INTO product_ingredients (id, product_id, material_id, unit_id, count, created_at, updated_at)
      VALUES#{' '}
        (1, 1, 1, 1, 200.0, '#{now}', '#{now}'),
        (2, 1, 2, 2, 300.0, '#{now}', '#{now}'),
        (3, 2, 3, 1, 100.0, '#{now}', '#{now}'),
        (4, 2, 4, 1, 50.0, '#{now}', '#{now}');
    SQL

    sample_db.close

    puts "Sample legacy database created successfully!"
    puts "Test import with: LEGACY_DB_PATH=#{sample_db_path} bin/rails import:from_legacy"
  end
end
