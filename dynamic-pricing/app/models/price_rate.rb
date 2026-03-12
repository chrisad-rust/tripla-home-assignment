# Represents a price rate fetched from the external API
#
# Attributes:
# - lookup_hash: Hash key for a hotel/room/period combination.
# - rate: The actual price value as integer
# - price_rate_update_infos_id: Foreign key to the batch this rate belongs to
#
# Associations:
# - belongs_to :update_info (PriceRateUpdateInfo), providing batch metadata like executed_at and success
class PriceRate < ApplicationRecord
  validates :lookup_hash, presence: true
  validates :rate, presence: true
  validates :price_rate_update_infos_id, presence: true
  # Ensure that for each batch, there are no duplicate rates for the same lookup_hash & update_info reference.
  validates :lookup_hash,
            uniqueness: { scope: :price_rate_update_infos_id }
  # Provides access to batch metadata such as executed_at and success status
  belongs_to :update_info, class_name: "PriceRateUpdateInfo", foreign_key: "price_rate_update_infos_id"

  # Scope: fetch the best (latest successful and recent) rate for a given lookup_hash
  # This is used by the API to respond quickly with a valid cached rate
  scope :best_rate, ->(lookup_hash) {
      eager_load(:update_info)
      .where(lookup_hash: lookup_hash)
      .merge(PriceRateUpdateInfo.successful)
      .merge(PriceRateUpdateInfo.recent)
      .limit(1)
  }
end
