class CreatePriceRateUpdateInfos < ActiveRecord::Migration[7.1]
  def change
    create_table :price_rate_update_infos do |t|
      t.boolean :successful, null: false
      t.string :error_message, limit: 30

      t.timestamps
    end
    add_index :price_rate_update_infos, :successful
    add_index :price_rate_update_infos, :created_at
  end
end
