class PriceRateUpdateInfo < ApplicationRecord
    validates :successful, presence: true
    validates :created_at, presence: true
    has_many :price_rates
end