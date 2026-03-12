# Background job responsible for cleaning up old price rates.
class CleanupPriceRatesJob < ApplicationJob
  queue_as :sidekiq

  def perform
    PriceRateUpdateInfo.where(executed_at: ..5.minutes.ago).destroy_all
  end
end
