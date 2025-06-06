class CreateMaterialQuantities < ActiveRecord::Migration[8.0]
  def change
    create_table :material_quantities do |t|
      t.float :count
      t.references :unit, null: false, foreign_key: true
      t.references :material, null: false, foreign_key: true

      t.timestamps
    end
  end
end
