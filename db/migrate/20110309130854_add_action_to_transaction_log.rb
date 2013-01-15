class AddActionToTransactionLog < ActiveRecord::Migration
  def self.up
    add_column :transaction_logs, :action, :string
  end

  def self.down
    remove_column :transaction_logs, :action
  end
end
