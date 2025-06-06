class User < ApplicationRecord
  has_many :materials, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :units, dependent: :destroy
  
  validates :email, presence: true, uniqueness: true
end
