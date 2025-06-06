class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :materials, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :units, dependent: :destroy

  validates :profit_ratio, presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: 1 }

  # 利益率を含む販売価格を計算
  def selling_price_for(cost_per_unit)
    return 0 if profit_ratio.nil? || profit_ratio <= 0
    cost_per_unit / profit_ratio
  end
end
