# Migration to create the table for the record `PriceRate`
# This table stores individual price rates fetched from the external API
# Each rate belongs to a batch represented by PriceRateUpdateInfo
class CreatePriceRates < ActiveRecord::Migration[7.1]
  def change
    create_table :price_rates do |t|
      # Hash key representing a unique hotel/room/period combination
      t.integer :lookup_hash, null: false
       # Actual price rate
      t.integer :rate, null: false
       # Foreign key linking this rate to its batch
      t.references :price_rate_update_infos, null: false, foreign_key: true
    end
    # Index for fast lookup by hash key
    add_index :price_rates, :lookup_hash
    # Composite unique index ensures that within a batch,
    # each lookup_hash occurs only once
    add_index :price_rates,
              [:lookup_hash, :price_rate_update_infos_id],
              unique: true,
              name: "index_price_rates_on_lookup_and_update_info"
  end
end
