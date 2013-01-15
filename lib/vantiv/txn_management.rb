

require_relative 'ipcommerce'


ipc_instance=Ipcommerce.new();

list_of_txns=ipc_instance.query_transactions_families()
puts "","",""
ipc_instance.query_batch()
puts "","",""

ipc_instance.query_transactions_summary()
puts "","",""

txn_id=list_of_txns.first["TransactionIds"].first
ipc_instance.query_transactions_detail([txn_id])

puts "Done"
