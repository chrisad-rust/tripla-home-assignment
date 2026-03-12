# Background job responsible for cleaning up old price rates.
class CleanupPriceRatesJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info("[PriceRateCleanup] Perform price rate cleanup.")
    PriceRateUpdateInfo.where(executed_at: ..5.minutes.ago).destroy_all
  end
end
