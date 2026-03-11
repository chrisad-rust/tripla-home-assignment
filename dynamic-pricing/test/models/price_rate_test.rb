require "test_helper"

# Unit tests for the PriceRate model
# Validates uniqueness, required fields, and database constraints
class PriceRateTest < ActiveSupport::TestCase
  # Create a successful batch to associate rates with for all tests
  setup do
    @update_info = PriceRateUpdateInfo.create!(successful: true, executed_at: 0.minutes.ago)
  end

  # Test that a valid PriceRate with unique combination is allowed
  test "allows unique combination" do
    @price_rate = PriceRate.create(lookup_hash: 1, rate: 50, update_info: @update_info)
    assert @price_rate.valid?
    assert @price_rate.persisted?
  end

  # Test that required fields are enforced at model and database level
  test "ensures required fields" do
    # ensure on middleware level
    assert_raises(ActiveRecord::RecordInvalid) do
      PriceRate.create!({ lookup_hash: 1, rate: 50 })
    end
    assert_raises(ActiveRecord::RecordInvalid) do
      PriceRate.create!({ lookup_hash: 1, price_rate_update_infos_id: @update_info.id })
    end
    assert_raises(ActiveRecord::RecordInvalid) do
      PriceRate.create!({ rate: 50, price_rate_update_infos_id: @update_info.id })
    end

    # ensure on database level
    assert_raises(ActiveRecord::NotNullViolation) do
      PriceRate.insert!({ lookup_hash: 1, rate: 50 })
    end
    assert_raises(ActiveRecord::NotNullViolation) do
      PriceRate.insert!({ lookup_hash: 1, price_rate_update_infos_id: @update_info.id })
    end
    assert_raises(ActiveRecord::NotNullViolation) do
      PriceRate.insert!({ rate: 50, price_rate_update_infos_id: @update_info.id })
    end
  end

  # Test that duplicate combinations are not allowed by validations
  test "prevents duplicate combination" do
    PriceRate.create!(lookup_hash: 1, rate: 50, update_info: @update_info)
    
    @duplicate = PriceRate.new(lookup_hash: 1, rate: 50, update_info: @update_info)
    assert_not @duplicate.valid?
    assert_includes @duplicate.errors[:lookup_hash], "has already been taken"

    # ensure on middleware level
    assert_raises(ActiveRecord::RecordInvalid) do
      PriceRate.create!(lookup_hash: 1, rate: 50, update_info: @update_info)
    end

    # ensure on database level
    assert_raises(ActiveRecord::RecordNotUnique) do
      PriceRate.insert!({ lookup_hash: 1, rate: 50, price_rate_update_infos_id: @update_info.id })
    end
  end

end
