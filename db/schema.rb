# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_06_06_083751) do
  create_table "material_quantities", force: :cascade do |t|
    t.float "count"
    t.integer "unit_id", null: false
    t.integer "material_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["material_id"], name: "index_material_quantities_on_material_id"
    t.index ["unit_id"], name: "index_material_quantities_on_unit_id"
  end

  create_table "materials", force: :cascade do |t|
    t.string "name"
    t.float "price"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_materials_on_user_id"
  end

  create_table "product_ingredients", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "material_id", null: false
    t.integer "unit_id", null: false
    t.float "count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["material_id"], name: "index_product_ingredients_on_material_id"
    t.index ["product_id"], name: "index_product_ingredients_on_product_id"
    t.index ["unit_id"], name: "index_product_ingredients_on_unit_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.float "count"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_products_on_user_id"
  end

  create_table "units", force: :cascade do |t|
    t.string "name"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_units_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "material_quantities", "materials"
  add_foreign_key "material_quantities", "units"
  add_foreign_key "materials", "users"
  add_foreign_key "product_ingredients", "materials"
  add_foreign_key "product_ingredients", "products"
  add_foreign_key "product_ingredients", "units"
  add_foreign_key "products", "users"
  add_foreign_key "units", "users"
end
