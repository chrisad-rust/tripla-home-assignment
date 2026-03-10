class PriceRate < ApplicationRecord
  validates :lookup_hash, presence: true
  validates :rate, presence: true
  belongs_to :update_info, class_name: "PriceRateUpdateInfo", foreign_key: "price_rate_update_infos_id"
end
