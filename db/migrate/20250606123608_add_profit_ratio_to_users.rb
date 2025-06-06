class AddProfitRatioToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :profit_ratio, :decimal, precision: 5, scale: 3, default: 0.3
  end
end
