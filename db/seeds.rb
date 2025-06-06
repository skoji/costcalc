# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Creating sample data for CostCalc..."

# サンプルユーザーを作成
sample_user = User.find_or_create_by!(email: 'demo@example.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.profit_ratio = 0.3  # 30%のデフォルト利益率
end

puts "Created user: #{sample_user.email}"

# 基本的な単位を作成
units_data = [
  { name: 'g', user: sample_user },
  { name: 'ml', user: sample_user },
  { name: '個', user: sample_user },
  { name: 'パック', user: sample_user },
  { name: 'kg', user: sample_user },
  { name: 'L', user: sample_user },
  { name: '袋', user: sample_user },
  { name: '缶', user: sample_user }
]

units = {}
units_data.each do |unit_data|
  unit = Unit.find_or_create_by!(name: unit_data[:name], user: unit_data[:user])
  units[unit_data[:name]] = unit
end

puts "Created #{units.count} units"

# サンプル材料を作成
materials_data = [
  # 基本材料
  { name: '小麦粉', price: 300.0 },
  { name: '砂糖', price: 200.0 },
  { name: '塩', price: 100.0 },
  { name: 'バター', price: 500.0 },
  { name: '卵', price: 250.0 },
  { name: '牛乳', price: 200.0 },
  { name: 'ベーキングパウダー', price: 180.0 },
  { name: 'バニラエッセンス', price: 150.0 },
  
  # 野菜・フルーツ
  { name: 'りんご', price: 400.0 },
  { name: 'レモン', price: 100.0 },
  { name: '人参', price: 150.0 },
  { name: '玉ねぎ', price: 200.0 },
  { name: 'じゃがいも', price: 300.0 },
  { name: 'トマト', price: 350.0 },
  
  # 肉・魚
  { name: '鶏胸肉', price: 800.0 },
  { name: '豚バラ肉', price: 900.0 },
  { name: '牛ひき肉', price: 1200.0 },
  { name: 'サーモン', price: 1500.0 },
  
  # 調味料・香辛料
  { name: '醤油', price: 250.0 },
  { name: 'みそ', price: 400.0 },
  { name: 'みりん', price: 300.0 },
  { name: '料理酒', price: 200.0 },
  { name: '胡椒', price: 180.0 },
  { name: 'ガーリックパウダー', price: 220.0 },
  
  # その他
  { name: 'オリーブオイル', price: 600.0 },
  { name: 'チーズ', price: 800.0 },
  { name: 'パン粉', price: 150.0 },
  { name: 'コンソメ', price: 300.0 },
  { name: 'パスタ', price: 400.0 },
  { name: 'ココアパウダー', price: 350.0 }
]

materials = {}
materials_data.each do |mat_data|
  material = Material.find_or_create_by!(name: mat_data[:name], user: sample_user) do |m|
    m.price = mat_data[:price]
  end
  materials[mat_data[:name]] = material
end

puts "Created #{materials.count} materials"

# 全ての材料に材料数量を作成
materials_data.each do |mat_data|
  material = materials[mat_data[:name]]
  
  # 基本材料（粉類、調味料）
  case mat_data[:name]
  when '小麦粉', '砂糖', '塩', 'ベーキングパウダー', 'パン粉', 'ココアパウダー'
    # 1000gを基準単位とする
    MaterialQuantity.find_or_create_by!(material: material, unit: units['g']) do |mq|
      mq.count = 1000.0
    end
  when 'バター', 'チーズ'
    # 200gパックを基準とする
    MaterialQuantity.find_or_create_by!(material: material, unit: units['g']) do |mq|
      mq.count = 200.0
    end
  when '卵'
    # 10個パックを基準とする
    MaterialQuantity.find_or_create_by!(material: material, unit: units['個']) do |mq|
      mq.count = 10.0
    end
  when '牛乳'
    # 1Lパックを基準とする
    MaterialQuantity.find_or_create_by!(material: material, unit: units['L']) do |mq|
      mq.count = 1.0
    end
  when 'バニラエッセンス'
    # 30ml瓶を基準とする
    MaterialQuantity.find_or_create_by!(material: material, unit: units['ml']) do |mq|
      mq.count = 30.0
    end
  when 'りんご', 'レモン', '人参', '玉ねぎ', 'じゃがいも', 'トマト'
    # 個数で販売
    MaterialQuantity.find_or_create_by!(material: material, unit: units['個']) do |mq|
      mq.count = 1.0
    end
  when '鶏胸肉', '豚バラ肉', '牛ひき肉', 'サーモン'
    # 100gあたりの価格に設定
    MaterialQuantity.find_or_create_by!(material: material, unit: units['g']) do |mq|
      mq.count = 100.0
    end
  when '醤油', 'みそ', 'みりん', '料理酒', 'オリーブオイル'
    # 500ml容器を基準とする
    MaterialQuantity.find_or_create_by!(material: material, unit: units['ml']) do |mq|
      mq.count = 500.0
    end
  when '胡椒', 'ガーリックパウダー'
    # 50g容器を基準とする
    MaterialQuantity.find_or_create_by!(material: material, unit: units['g']) do |mq|
      mq.count = 50.0
    end
  when 'コンソメ'
    # 1箱（10個入り）を基準とする
    MaterialQuantity.find_or_create_by!(material: material, unit: units['個']) do |mq|
      mq.count = 10.0
    end
  when 'パスタ'
    # 500gパックを基準とする
    MaterialQuantity.find_or_create_by!(material: material, unit: units['g']) do |mq|
      mq.count = 500.0
    end
  end
end

puts "Created material quantities"

# サンプル製品を作成
products_data = [
  { name: 'チョコレートケーキ', count: 8.0 },
  { name: 'アップルパイ', count: 6.0 },
  { name: 'クッキー（1ダース）', count: 12.0 },
  { name: 'チキンカレー', count: 4.0 },
  { name: 'ハンバーグ', count: 4.0 },
  { name: 'パスタ・ボロネーゼ', count: 2.0 },
  { name: 'サーモンのムニエル', count: 2.0 },
  { name: 'ポテトサラダ', count: 6.0 },
  { name: 'コンソメスープ', count: 4.0 },
  { name: 'フレンチトースト', count: 2.0 }
]

products = {}
products_data.each do |prod_data|
  product = Product.find_or_create_by!(name: prod_data[:name], user: sample_user) do |p|
    p.count = prod_data[:count]
  end
  products[prod_data[:name]] = product
end

puts "Created #{products.count} products"

# 製品原料を作成（いくつかの製品に対して）
product_ingredients_data = [
  # チョコレートケーキの材料
  { product: 'チョコレートケーキ', material: '小麦粉', unit: 'g', count: 200.0 },
  { product: 'チョコレートケーキ', material: '砂糖', unit: 'g', count: 150.0 },
  { product: 'チョコレートケーキ', material: 'ココアパウダー', unit: 'g', count: 50.0 },
  { product: 'チョコレートケーキ', material: 'バター', unit: 'g', count: 100.0 },
  { product: 'チョコレートケーキ', material: '卵', unit: '個', count: 3.0 },
  
  # アップルパイの材料
  { product: 'アップルパイ', material: '小麦粉', unit: 'g', count: 300.0 },
  { product: 'アップルパイ', material: 'バター', unit: 'g', count: 150.0 },
  { product: 'アップルパイ', material: 'りんご', unit: '個', count: 4.0 },
  { product: 'アップルパイ', material: '砂糖', unit: 'g', count: 100.0 },
  
  # チキンカレーの材料
  { product: 'チキンカレー', material: '鶏胸肉', unit: 'g', count: 400.0 },
  { product: 'チキンカレー', material: '玉ねぎ', unit: '個', count: 2.0 },
  { product: 'チキンカレー', material: '人参', unit: '個', count: 1.0 },
  { product: 'チキンカレー', material: 'じゃがいも', unit: '個', count: 2.0 },
  
  # ハンバーグの材料
  { product: 'ハンバーグ', material: '牛ひき肉', unit: 'g', count: 400.0 },
  { product: 'ハンバーグ', material: '玉ねぎ', unit: '個', count: 1.0 },
  { product: 'ハンバーグ', material: '卵', unit: '個', count: 1.0 },
  { product: 'ハンバーグ', material: 'パン粉', unit: 'g', count: 50.0 }
]

product_ingredients_data.each do |pi_data|
  product = products[pi_data[:product]]
  material = materials[pi_data[:material]]
  unit = units[pi_data[:unit]]
  
  ProductIngredient.find_or_create_by!(
    product: product,
    material: material,
    unit: unit
  ) do |pi|
    pi.count = pi_data[:count]
  end
end

puts "Created product ingredients"

puts "\n✅ Sample data creation completed!"
puts "📧 Login with: demo@example.com"
puts "🔑 Password: password123"
puts "📊 Created: #{User.count} users, #{Material.count} materials, #{Product.count} products"
