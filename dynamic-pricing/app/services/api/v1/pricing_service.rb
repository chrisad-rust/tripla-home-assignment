module Api::V1
  # PricingService
  #
  # This service is responsible for retrieving the best price rate for a given
  # hotel, room, and period combination. It first attempts to fetch the latest
  # valid cached rate from the database. If no rate is found, it inspects recent
  # update jobs to determine the reason for missing data.
  #
  # Responsibilities:
  # - Query the PriceRate model for the best available rate.
  # - Validate that the requested period, hotel, and room are supported.
  # - Collect and expose meaningful errors if rates are unavailable.
  # - Distinguish between no update job, failed update jobs, or missing rates.
  #
  # Note: This service relies on PriceRateParameters for valid period/hotel/room constants.
  class PricingService < BaseService
    include PriceRateParameters

    # Initializes the pricing service with the requested parameters.
    def initialize(period:, hotel:, room:)
      @period = period
      @hotel = hotel
      @room = room
    end

    # Executes the pricing lookup logic.
    def run
      # Retrieve the best available rate for the given parameters.
      best_rate = PriceRate.best_rate(hash_params(@period, @hotel, @room)).first

      if best_rate.present?
        # Rate found
        @result = best_rate.rate
        return
      end

      # No rate found — investigate update job status
      job_infos = PriceRateUpdateInfo.recent
    
      if job_infos.empty?
        # No update jobs executed recently
        errors << "Update job stopped."
        return
      end

      job_infos.each do |job_info|
        if job_info.successful 
          # A successful update ran, but the rate does not exist
          @errors = ["Rate not available."]
          return
        else 
          # Collect errors from failed update jobs
          errors << job_info.error_message
        end
      end

      # If all recent jobs failed, assume upstream rating service failure
      errors << "Rating service is probably down."
    end
  end
end
