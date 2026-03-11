# Migration to create the table for the record `PriceRateUpdateInfo`
# This table stores metadata for each batch of price rates fetched from the external API
class CreatePriceRateUpdateInfos < ActiveRecord::Migration[7.1]
  def change
    create_table :price_rate_update_infos do |t|
      # Indicates whether the batch was successfully fetched
      t.boolean :successful, default: false
       # Stores error message if the batch failed
      t.string :error_message, limit: 255
      # Timestamp when the update job was executed
      # Used to enforce cache freshness
      t.datetime :executed_at, null: false
    end
    # Index to speed up queries for successful or failed batches
    add_index :price_rate_update_infos, :successful
    # Index to quickly retrieve recent batches for caching
    add_index :price_rate_update_infos, :executed_at
  end
end
