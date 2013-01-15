class TransactionLog < ActiveRecord::Base
  serialize :transaction
  serialize :result
end
