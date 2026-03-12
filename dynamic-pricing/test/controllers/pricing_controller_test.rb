require "test_helper"
require "ostruct"

# Api::V1::PricingControllerTest
#
# Integration tests for the Pricing API endpoint.
# 
# Responsibilities:
# - Validate correct JSON response when a rate is available.
# - Ensure proper error handling for:
#   - Missing or invalid parameters
#   - Background update jobs that fail or are missing
#   - Rate API returning errors or malformed responses
# - Mock the RateApiClient to simulate various external API responses.
#
# Usage:
#   Tests run automatically with Rails' `rails test` command.
#   Each test cleans up the PriceRate and PriceRateUpdateInfo tables to
#   ensure isolation and repeatability.
#
# Note:
#   - Uses OpenStruct to mock API responses.
#   - Includes PriceRateParameters to compute lookup_hash values.
class Api::V1::PricingControllerTest < ActionDispatch::IntegrationTest
  include PriceRateParameters

  # Cleanup database
  setup do
    PriceRate.delete_all
    PriceRateUpdateInfo.delete_all
  end

  # Perform the background job with a mocked API client response
  def run_job(body)
    mock_response = OpenStruct.new(success?: true, body: body)

    RateApiClient.stub(:get_rates, mock_response) do
      perform_enqueued_jobs do
        UpdatePriceRatesJob.perform_later
      end
      
      assert_performed_jobs 1
    end
  end

  test "should get pricing with all parameters" do
    run_job({
      'rates' => [
        { 'period' => 'Summer', 'hotel' => 'FloatingPointResort', 'room' => 'SingletonRoom', 'rate' => '15000' }
      ]
    }.to_json)

    get api_v1_pricing_url, params: {
      period: "Summer",
      hotel: "FloatingPointResort",
      room: "SingletonRoom"
    }

    assert_response :success
    assert_equal "application/json", @response.media_type

    json_response = JSON.parse(@response.body)
    assert_equal 15000, json_response["rate"]
  end

  test "should return error when update job is down" do
    get api_v1_pricing_url, params: {
      period: "Summer",
      hotel: "FloatingPointResort",
      room: "SingletonRoom"
    }

    assert_response :bad_request
    assert_equal "application/json", @response.media_type

    json_response = JSON.parse(@response.body)
    assert_includes json_response["error"], "Update job stopped."
  end

  test "should return error when rate is not available" do
    run_job({
      'rates' => [
        { 'period' => 'Summer', 'hotel' => 'FloatingPointResort', 'room' => 'SingletonRoom', 'rate' => '15000' }
      ]
    }.to_json)

    get api_v1_pricing_url, params: {
      period: "Winter",
      hotel: "FloatingPointResort",
      room: "SingletonRoom"
    }

    assert_response :bad_request
    assert_equal "application/json", @response.media_type

    json_response = JSON.parse(@response.body)
    assert_includes json_response["error"], "Rate not available."
  end

  test "should return error when rate API fails" do
    run_job({ 'error' => 'Rate not found' }.to_json)
    
    get api_v1_pricing_url, params: {
      period: "Summer",
      hotel: "FloatingPointResort",
      room: "SingletonRoom"
    }

    assert_response :bad_request
    assert_equal "application/json", @response.media_type

    json_response = JSON.parse(@response.body)
    assert_includes json_response["error"], "Rate not found, Rating service is probably down."
  end

  test "should return error without any parameters" do
    get api_v1_pricing_url

    assert_response :bad_request
    assert_equal "application/json", @response.media_type

    json_response = JSON.parse(@response.body)
    assert_includes json_response["error"], "Missing required parameters"
  end

  test "should handle empty parameters" do
    get api_v1_pricing_url, params: {
      period: "",
      hotel: "",
      room: ""
    }

    assert_response :bad_request
    assert_equal "application/json", @response.media_type

    json_response = JSON.parse(@response.body)
    assert_includes json_response["error"], "Missing required parameters"
  end

  test "should reject invalid period" do
    get api_v1_pricing_url, params: {
      period: "summer-2024",
      hotel: "FloatingPointResort",
      room: "SingletonRoom"
    }

    assert_response :bad_request
    assert_equal "application/json", @response.media_type

    json_response = JSON.parse(@response.body)
    assert_includes json_response["error"], "Invalid period"
  end

  test "should reject invalid hotel" do
    get api_v1_pricing_url, params: {
      period: "Summer",
      hotel: "InvalidHotel",
      room: "SingletonRoom"
    }

    assert_response :bad_request
    assert_equal "application/json", @response.media_type

    json_response = JSON.parse(@response.body)
    assert_includes json_response["error"], "Invalid hotel"
  end

  test "should reject invalid room" do
    get api_v1_pricing_url, params: {
      period: "Summer",
      hotel: "FloatingPointResort",
      room: "InvalidRoom"
    }

    assert_response :bad_request
    assert_equal "application/json", @response.media_type

    json_response = JSON.parse(@response.body)
    assert_includes json_response["error"], "Invalid room"
  end
end
