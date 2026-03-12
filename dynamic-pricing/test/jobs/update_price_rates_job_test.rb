require "test_helper"
require "ostruct"
require "securerandom"

# Tests for UpdatePriceRatesJob.
#
# These tests verify that the job correctly:
#
# - Requests rate data from the external API
# - Validates API responses
# - Handles malformed or invalid responses
# - Validates domain data (period, hotel, room, rate)
# - Stores successful updates
# - Stores error information when processing fails
#
# The external API client is stubbed to ensure tests
# remain deterministic and do not depend on network calls.
class UpdatePriceRatesJobTest < ActiveJob::TestCase
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

    PriceRateUpdateInfo.first
  end

  test "update rates" do
    first_entry_hash = hash_params('Summer', 'FloatingPointResort', 'SingletonRoom')
    last_entry_hash = hash_params('Winter', 'FloatingPointResort', 'SingletonRoom')
    update_info = run_job({
      'rates' => [
        { 'period' => 'Summer', 'hotel' => 'FloatingPointResort', 'room' => 'SingletonRoom', 'rate' => 15000 },
        { 'period' => 'Winter', 'hotel' => 'FloatingPointResort', 'room' => 'SingletonRoom', 'rate' => '1000' }
      ]
    }.to_json);

    assert_nil update_info.error_message
    assert update_info.successful

    best_rate_query = PriceRate.where(update_info: update_info)
    
    assert_equal 2, best_rate_query.size
    
    best_rate_query.each do |rate|
      assert_includes [first_entry_hash, last_entry_hash], rate.lookup_hash
      if first_entry_hash == rate.lookup_hash 
        assert_equal 15000, rate.rate
      end
      if last_entry_hash == rate.lookup_hash
        assert_equal 1000, rate.rate
      end
    end
  end

  test "receives nil body" do
    update_info = run_job(nil)

    assert_equal "Server not available.", update_info.error_message
    assert_not update_info.successful
  end
      
  test "receives empty string" do
    update_info = run_job("");

    assert_equal "Server not available.", update_info.error_message
    assert_not update_info.successful
  end

  test "receives json null object" do
    update_info = run_job("null")

    assert_equal "Invalid json format in response.", update_info.error_message
    assert_not update_info.successful
  end
    
  test "receives json empty string" do
    update_info = run_job("''")

    assert_equal "Invalid json format in response.", update_info.error_message
    assert_not update_info.successful
  end

  test "receives random bytes" do
    update_info = run_job(SecureRandom.random_bytes(50))

    assert_equal "Invalid json format in response.", update_info.error_message
    assert_not update_info.successful
  end

  test "receives unknown json property" do
    update_info = run_job({
      'unknown' => []
    }.to_json)

    assert_equal "Missing rates on response.", update_info.error_message
    assert_not update_info.successful
  end
  
  test "receives empty rates array" do
    update_info = run_job({
      'rates' => []
    }.to_json)

    assert_equal "Missing rates on response.", update_info.error_message
    assert_not update_info.successful
  end

  test "receives empty rates string" do
    update_info = run_job({
      'rates' => ""
    }.to_json);

    assert_equal "Missing rates on response.", update_info.error_message
    assert_not update_info.successful
  end

  test "receives rate object" do
    update_info = run_job({
      'rates' => { 'period' => 'Summer', 'hotel' => 'FloatingPointResort', 'room' => 'SingletonRoom', 'rate' => 15000 },
    }.to_json)

    assert_equal "Missing rates on response.", update_info.error_message
    assert_not update_info.successful
  end

  test "receives error" do
    update_info = run_job({
      'error' => "Error"
    }.to_json);

    assert_equal "Error", update_info.error_message
    assert_not update_info.successful
  end

  test "receives error message" do
    update_info = run_job({
      'message' => "Error Message"
    }.to_json);

    assert_equal "Error Message", update_info.error_message
    assert_not update_info.successful
  end

  test "receives rates with unknown period" do
    update_info = run_job({
      'rates' => [
        { 'period' => 'Unknown', 'hotel' => 'FloatingPointResort', 'room' => 'SingletonRoom', 'rate' => 15000 },
      ]
    }.to_json);

    assert_equal "Invalid format of `rates`.", update_info.error_message
    assert_not update_info.successful
  end

  test "receives rates with unknown hotel" do
    update_info = run_job({
      'rates' => [
        { 'period' => 'Summer', 'hotel' => 'Unknown', 'room' => 'SingletonRoom', 'rate' => 15000 },
      ]
    }.to_json)

    assert_equal "Invalid format of `rates`.", update_info.error_message
    assert_not update_info.successful
  end

    test "receives rates with unknown room" do
    update_info = run_job({
      'rates' => [
        { 'period' => 'Summer', 'hotel' => 'FloatingPointResort', 'room' => 'Unknown', 'rate' => 15000 },
      ]
    }.to_json)

    assert_equal "Invalid format of `rates`.", update_info.error_message
    assert_not update_info.successful
  end

  test "receives rates with invalid rate" do
    update_info = run_job({
      'rates' => [
        { 'period' => 'Summer', 'hotel' => 'FloatingPointResort', 'room' => 'SingletonRoom', 'rate' => "100€" },
      ]
    }.to_json)

    assert_equal "Invalid format of `rates`.", update_info.error_message
    assert_not update_info.successful
  end

end
