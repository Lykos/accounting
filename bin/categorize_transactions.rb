#!/usr/bin/ruby

$LOAD_PATH.push(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'transaction_parser'
require 'categorizer'

parser = TransactionParser.new
ARGV.each { |f| parser.read(f) }
puts "Loaded #{parser.transactions.length} transactions."

recent_time = Time.now - 365 * 24 * 60 * 60
transactions = parser.transactions.select { |t| t.time > recent_time && t.amount < 0 }
puts "#{transactions.length} eligible transactions are after #{recent_time.strftime('%F')}."
puts

categorizer = Categorizer.new(transactions)
begin
  categorizer.categorize_all!
rescue Interrupt
  puts 'Interrupted'
end
total_amount = categorizer.categories.map(&:total_amount).sum + 0.0
categorizer.categories.each do |c|
  puts c.name
  puts c.transactions
  percentage = c.total_amount / total_amount * 100
  puts "Total #{c.total_amount} CHF (#{percentage.round(2)} %)"
  puts
end
