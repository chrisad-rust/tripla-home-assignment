require "test_helper"

# Tests for CleanupPriceRatesJob.
class CleanupPriceRatesJobTest < ActiveJob::TestCase

  # Cleanup database
  setup do
    PriceRate.delete_all
    PriceRateUpdateInfo.delete_all
  end

  test "ensure keep recent price rates" do
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
    
    perform_enqueued_jobs do
      CleanupPriceRatesJob.perform_later
    end
      
    assert_performed_jobs 1

    assert_equal 3, PriceRateUpdateInfo.all.size
    assert_equal 9, PriceRate.all.size
  end

end
