# Client responsible for communicating with the external Rate API.
#
# Responsibilities:
# - Send pricing requests to the external service
# - Provide convenience methods for single and batch rate requests
#
# Uses HTTParty for HTTP communication and JSON handling.
class RateApiClient
  include HTTParty

  # Base URL of the external Rate API
  base_uri ENV.fetch('RATE_API_URL', 'http://localhost:8080')

  # Default headers required by the API
  headers "Content-Type" => "application/json"
  headers 'token' => ENV.fetch('RATE_API_TOKEN', '04aa6f42aa03f220c2ae9a276cd68c62')

  # Fetch a single rate for a specific period, hotel and room combination.
  #
  # Example request payload:
  # {
  #   attributes: [
  #     { period: "Summer", hotel: "FloatingPointResort", room: "SingletonRoom" }
  #   ]
  # }
  def self.get_rate(period:, hotel:, room:)
    self.get_rates([{ period: period, hotel: hotel, room: room }])
  end

  # Fetch multiple rates in a single request.
  #
  # Accepts an array of parameter hashes:
  #
  # [
  #   { period: "Summer", hotel: "FloatingPointResort", room: "SingletonRoom" },
  #   ...
  # ]
  #
  # This is used by the background job to retrieve all rate combinations
  # in one API call.
  def self.get_rates(rates)
    self.post("/pricing", body: {
      attributes: rates
    }.to_json)
  end
end
