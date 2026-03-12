# Shared helper module for validating pricing parameters and generating lookup keys.
#
# Responsibilities:
# - Define the allowed values for pricing parameters
# - Validate parameters received from the API
# - Generate a unique lookup hash for rate combinations
# - Provide the full parameter space for rate fetching
#
# This module is included in services or jobs that need to
# validate pricing parameters or construct lookup keys.
module PriceRateParameters
  extend ActiveSupport::Concern

  # all supported parameter options
  VALID_PERIODS = %w[Summer Autumn Winter Spring].freeze
  VALID_HOTELS = %w[FloatingPointResort GitawayHotel RecursionRetreat].freeze
  VALID_ROOMS = %w[SingletonRoom BooleanTwin RestfulKing].freeze

  included do

    # Validates that the requested period exists
    def valid_period?(period)
      VALID_PERIODS.include?(period)
    end

    # Validates that the requested hotel exists
    def valid_hotel?(hotel)
      VALID_HOTELS.include?(hotel)
    end

    # Validates that the requested room exists
    def valid_room?(room)
      VALID_ROOMS.include?(room)
    end

    # Generates a deterministic lookup key for a rate combination.
    #
    # The lookup hash uniquely identifies a rate for a
    # specific period / hotel / room combination.
    #
    # Example:
    #   "Summer_FloatingPointResort_SingletonRoom".hash
    #
    # The hash is used as a compact index in the database.
    def hash_params(period, hotel, room)
      Zlib.crc32("#{period}_#{hotel}_#{room}")
    end

    # Generates the complete parameter space for all possible rate combinations.
    #
    # This is used by the background job to request all available
    # rates from the external pricing API in a single request.
    #
    # Returns an array of all parameter sets:
    #
    # [
    #   { period: "Summer", hotel: "FloatingPointResort", room: "SingletonRoom" },
    #   ...
    # ]
    def all_rate_params
      VALID_PERIODS.product(VALID_HOTELS, VALID_ROOMS).map do |period, hotel, room|
        {
          period: period,
          hotel: hotel,
          room: room
        }
      end
    end

  end
end