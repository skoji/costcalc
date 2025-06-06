class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name
      t.float :count
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
