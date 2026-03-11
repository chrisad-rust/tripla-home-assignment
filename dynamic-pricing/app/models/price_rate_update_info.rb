# Represents a batch of price rates fetched from the external API
#
# Attributes:
# - executed_at: Time the update job ran
# - successful: Whether the update succeeded
#
# Associations: 
#  see class PriceRate
class PriceRateUpdateInfo < ApplicationRecord
    validates :executed_at, presence: true
    has_many :price_rates

    # Scope: lookup success entries
    scope :successful, -> {
        where(successful: true)
    }

    # Scope: lookup failed entries 
    scope :failed, -> {
        where(successful: false)
    }

    # Scope: updates executed in the last 5 minutes
    # Ordered from newest to oldest.
    # Useful for serving the most recent batch to clients.
    scope :recent, -> {
        where(executed_at: 5.minutes.ago..)
        .order(PriceRateUpdateInfo.arel_table[:executed_at].desc)
    }
end