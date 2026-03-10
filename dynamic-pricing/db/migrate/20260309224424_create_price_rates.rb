class CreatePriceRates < ActiveRecord::Migration[7.1]
  def change
    create_table :price_rates do |t|
      t.integer :lookup_hash, null: false
      t.integer :rate, null: false
      t.references :price_rate_update_infos, null: false, foreign_key: true

      t.timestamps
    end
    add_index :price_rates, :lookup_hash
  end
end
