class CreateTransactionLogs < ActiveRecord::Migration
  def self.up
    create_table :transaction_logs do |t|
      t.string :processor
      t.string :merchant_id
      t.string :merchant_key
      t.text :transaction
      t.text :result

      t.timestamps
    end
  end

  def self.down
    drop_table :transaction_logs
  end
end
