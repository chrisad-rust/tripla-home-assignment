require "test_helper"

# Integration tests for the PriceRate.best_rate scope
# Validates that only the latest successful and recent rates are returned
class QueryBestPriceRateTest < ActiveSupport::TestCase

  # Test that the best rate is correctly selected within the 5-minute window
  test "ensure best rate in time window" do
    update_info_0 = PriceRateUpdateInfo.create!(successful: false, error_message: "", executed_at: 1.minutes.ago)
    update_info_1 = PriceRateUpdateInfo.create!(successful: true, error_message: "", executed_at: 2.minutes.ago)
    update_info_2 = PriceRateUpdateInfo.create!(successful: false, error_message: "", executed_at: 3.minutes.ago)
    update_info_3 = PriceRateUpdateInfo.create!(successful: true, error_message: "", executed_at: 6.minutes.ago)
    update_info_4 = PriceRateUpdateInfo.create!(successful: false, error_message: "", executed_at: 7.minutes.ago)

    PriceRate.create!([
      { lookup_hash: 0, rate: 50, update_info: update_info_0 },
      { lookup_hash: 1, rate: 50, update_info: update_info_0 },
      { lookup_hash: 2, rate: 50, update_info: update_info_0 },
      { lookup_hash: 0, rate: 100, update_info: update_info_1 },
      { lookup_hash: 1, rate: 100, update_info: update_info_1 },
      { lookup_hash: 2, rate: 100, update_info: update_info_1 },
      { lookup_hash: 0, rate: 150, update_info: update_info_2 },
      { lookup_hash: 1, rate: 150, update_info: update_info_2 },
      { lookup_hash: 2, rate: 150, update_info: update_info_2 },
      { lookup_hash: 0, rate: 200, update_info: update_info_3 },
      { lookup_hash: 1, rate: 200, update_info: update_info_3 },
      { lookup_hash: 2, rate: 200, update_info: update_info_3 },
      { lookup_hash: 0, rate: 250, update_info: update_info_4 },
      { lookup_hash: 1, rate: 250, update_info: update_info_4 },
      { lookup_hash: 2, rate: 250, update_info: update_info_4 },
    ]);

    price_rate_query = PriceRate.best_rate(1)

    assert_equal 1, price_rate_query.size()

    best_rate = price_rate_query.first();

    assert_equal 1, best_rate.lookup_hash
    assert_equal 100, best_rate.rate
    assert_equal update_info_1, best_rate.update_info
  end

  # Test that rates outside the 5-minute window are ignored
  test "ensure no rate outsite the time window" do
    update_info_0 = PriceRateUpdateInfo.create!(successful: false, error_message: "", executed_at: 1.minutes.ago)
    update_info_1 = PriceRateUpdateInfo.create!(successful: false, error_message: "", executed_at: 2.minutes.ago)
    update_info_2 = PriceRateUpdateInfo.create!(successful: false, error_message: "", executed_at: 3.minutes.ago)
    update_info_3 = PriceRateUpdateInfo.create!(successful: true, error_message: "", executed_at: 5.minutes.ago)
    update_info_4 = PriceRateUpdateInfo.create!(successful: false, error_message: "", executed_at: 6.minutes.ago)

    PriceRate.create!([
      { lookup_hash: 0, rate: 50, update_info: update_info_0 },
      { lookup_hash: 1, rate: 50, update_info: update_info_0 },
      { lookup_hash: 2, rate: 50, update_info: update_info_0 },
      { lookup_hash: 0, rate: 100, update_info: update_info_1 },
      { lookup_hash: 1, rate: 100, update_info: update_info_1 },
      { lookup_hash: 2, rate: 100, update_info: update_info_1 },
      { lookup_hash: 0, rate: 150, update_info: update_info_2 },
      { lookup_hash: 1, rate: 150, update_info: update_info_2 },
      { lookup_hash: 2, rate: 150, update_info: update_info_2 },
      { lookup_hash: 0, rate: 200, update_info: update_info_3 },
      { lookup_hash: 1, rate: 200, update_info: update_info_3 },
      { lookup_hash: 2, rate: 200, update_info: update_info_3 },
      { lookup_hash: 0, rate: 250, update_info: update_info_4 },
      { lookup_hash: 1, rate: 250, update_info: update_info_4 },
      { lookup_hash: 2, rate: 250, update_info: update_info_4 },
    ]);

    price_rate_query = PriceRate.best_rate(1)

    assert_equal 0, price_rate_query.size()
  end

  # Test that unsuccessful batches are ignored
  test "ensure no unsuccessful rates" do
    update_info_0 = PriceRateUpdateInfo.create!(successful: false, error_message: "", executed_at: 1.minutes.ago)
    update_info_1 = PriceRateUpdateInfo.create!(successful: false, error_message: "", executed_at: 3.minutes.ago)
    update_info_2 = PriceRateUpdateInfo.create!(successful: false, error_message: "", executed_at: 6.minutes.ago)

    PriceRate.create!([
      { lookup_hash: 0, rate: 50, update_info: update_info_0 },
      { lookup_hash: 1, rate: 50, update_info: update_info_0 },
      { lookup_hash: 2, rate: 50, update_info: update_info_0 },
      { lookup_hash: 0, rate: 100, update_info: update_info_1 },
      { lookup_hash: 1, rate: 100, update_info: update_info_1 },
      { lookup_hash: 2, rate: 100, update_info: update_info_1 },
      { lookup_hash: 0, rate: 150, update_info: update_info_2 },
      { lookup_hash: 1, rate: 150, update_info: update_info_2 },
      { lookup_hash: 2, rate: 150, update_info: update_info_2 },
    ]);

    price_rate_query = PriceRate.best_rate(1)

    assert_equal 0, price_rate_query.size()
  end

  # Test that batches from the future are ignored
  test "ensure that batches from the future are ignored" do
    update_info_0 = PriceRateUpdateInfo.create!(successful: true, error_message: "", executed_at: 1.minutes.from_now)
    update_info_1 = PriceRateUpdateInfo.create!(successful: false, error_message: "", executed_at: 3.minutes.ago)
    update_info_2 = PriceRateUpdateInfo.create!(successful: false, error_message: "", executed_at: 6.minutes.ago)

    PriceRate.create!([
      { lookup_hash: 0, rate: 50, update_info: update_info_0 },
      { lookup_hash: 1, rate: 50, update_info: update_info_0 },
      { lookup_hash: 2, rate: 50, update_info: update_info_0 },
      { lookup_hash: 0, rate: 100, update_info: update_info_1 },
      { lookup_hash: 1, rate: 100, update_info: update_info_1 },
      { lookup_hash: 2, rate: 100, update_info: update_info_1 },
      { lookup_hash: 0, rate: 150, update_info: update_info_2 },
      { lookup_hash: 1, rate: 150, update_info: update_info_2 },
      { lookup_hash: 2, rate: 150, update_info: update_info_2 },
    ]);

    price_rate_query = PriceRate.best_rate(1)

    assert_equal 0, price_rate_query.size()
  end

end
