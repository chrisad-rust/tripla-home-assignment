# Background job responsible for fetching price rates
# from the external Rate API and storing them in the database.
#
# Workflow:
# 1. Generate all possible rate parameter combinations
# 2. Request rates from the external API
# 3. Validate and parse the response
# 4. Validate each returned rate entry
# 5. Persist the results as a batch
#
# In case of any error during processing, an error entry
# is recorded in PriceRateUpdateInfo instead of storing rates.
class UpdatePriceRatesJob < ApplicationJob
  queue_as :default
  include PriceRateParameters

  def perform
    Rails.logger.info("[PriceRateUpdate] Perform price rate update.")
    # request all rates
    rates = all_rate_params
    response = RateApiClient.get_rates(rates)

    if response.body.nil? || response.body.empty?
      store_error('Server not available.')
      return
    end

    # parse body
    response_data = response.parsed_response

    if response_data.nil? || response_data.empty?
      response_data = JSON.parse(response.body) rescue nil
    end

    if response_data.nil? || response_data.empty? 
      store_error('Invalid json format in response.')
      return
    end

    # validate and process json data
    response_rates = response_data['rates']

    if response_rates.nil? || response_rates.empty? || !response_rates.is_a?(Array)
      error = response_data['error']
      unless error.nil? || error.empty? 
        store_error(error)
        return
      end
      
      message = response_data['message']
      unless message.nil? || message.empty? 
        store_error(message)
        return
      end

      store_error('Missing rates on response.')
      return
    end

    # validate and process rate data
    includes_invalid_rates = false
    price_rates = response_rates.map do |rate|
      period = rate['period']
      hotel = rate['hotel']
      room = rate['room']
      rate = Integer(rate['rate']) rescue nil

      if valid_period?(period) && valid_hotel?(hotel) && valid_room?(room) && rate.present?
        { lookup_hash: hash_params(period, hotel, room), rate: rate }
      else 
        includes_invalid_rates = true
        nil
      end
    end

    if includes_invalid_rates 
      store_error('Invalid format of `rates`.')
      return
    end

    store_data(price_rates)
  end

  # Records failed rate update attempt
  private def store_error(message)
    PriceRateUpdateInfo.create!(successful: false, executed_at: Time.current, error_message: message)
  end

  # Stores successfully fetched rates
  private def store_data(rates_data)
    PriceRateUpdateInfo.transaction do 
      update_info = PriceRateUpdateInfo.create!(successful: true, executed_at: Time.current)
      price_rates = rates_data.map do |rate| 
        { lookup_hash: rate[:lookup_hash], rate: rate[:rate], update_info: update_info }
      end

      if price_rates.any?
        PriceRate.create!(price_rates)
      end
    end
  end
end
