class CreateProductIngredients < ActiveRecord::Migration[8.0]
  def change
    create_table :product_ingredients do |t|
      t.references :product, null: false, foreign_key: true
      t.references :material, null: false, foreign_key: true
      t.references :unit, null: false, foreign_key: true
      t.float :count

      t.timestamps
    end
  end
end
