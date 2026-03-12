# API endpoint responsible for retrieving the best available price rate
# for a given period, hotel and room combination.
#
# Responsibilities:
# - Validate incoming request parameters
# - Delegate rate lookup logic to the PricingService
# - Return the resulting rate or an error message
#
# The controller remains thin by delegating business logic
# to a dedicated service object.
class Api::V1::PricingController < ApplicationController
  include PriceRateParameters

  before_action :validate_params

   # GET /api/v1/pricing
  #
  # Expected parameters:
  # - period
  # - hotel
  # - room
  #
  # Returns:
  # { rate: Integer } on success
  # { error: String } on failure
  def index
    period = params[:period]
    hotel  = params[:hotel]
    room   = params[:room]

    service = Api::V1::PricingService.new(period:, hotel:, room:)
    service.run
    if service.valid?
      render json: { rate: service.result }
    else
      render json: { error: service.errors.join(', ') }, status: :bad_request
    end
  end

  # Validates required parameters and ensures their values are within the supported domain.
  private def validate_params
    # Validate required parameters
    unless params[:period].present? && params[:hotel].present? && params[:room].present?
      return render json: { error: "Missing required parameters: period, hotel, room" }, status: :bad_request
    end

    # Validate parameter values
    unless valid_period?(params[:period])
      return render json: { error: "Invalid period. Must be one of: #{VALID_PERIODS.join(', ')}" }, status: :bad_request
    end

    unless valid_hotel?(params[:hotel])
      return render json: { error: "Invalid hotel. Must be one of: #{VALID_HOTELS.join(', ')}" }, status: :bad_request
    end

    unless valid_room?(params[:room])
      return render json: { error: "Invalid room. Must be one of: #{VALID_ROOMS.join(', ')}" }, status: :bad_request
    end
  end
end
