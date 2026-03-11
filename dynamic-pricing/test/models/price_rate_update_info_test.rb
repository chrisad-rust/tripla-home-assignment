require "test_helper"

# Unit tests for the PriceRateUpdateInfo model
# Validates creation, required fields, and database constraints
class PriceRateUpdateInfoTest < ActiveSupport::TestCase

   # Test that a minimal and maximal update_info can be created and persisted
  test "create persisted" do
    @minimal_update_info = PriceRateUpdateInfo.create!(executed_at: 0.minutes.ago)

    assert @minimal_update_info.valid?
    assert @minimal_update_info.persisted?

    @maximal_update_info = PriceRateUpdateInfo.create!(successful: true, error_message: "", executed_at: 0.minutes.ago)

    assert @maximal_update_info.valid?
    assert @maximal_update_info.persisted?
  end

  # Test that required fields are enforced at model and database level
  test "ensures required fields" do
    # ensure on middleware level
    assert_raises(ActiveRecord::RecordInvalid) do
      PriceRateUpdateInfo.create!(successful: true)
    end

    # ensure on database level
    assert_raises(ActiveRecord::NotNullViolation) do
      PriceRateUpdateInfo.insert!({ successful: true })
    end
  end

end
