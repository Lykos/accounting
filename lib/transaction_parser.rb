require 'csv'
require 'transaction'

class TransactionParser
  class HeaderParser
    def parse(row)
      date_index = row.index { |c| c.downcase.include?('date') }
      credit_index = row.index { |c| c.downcase.include?('credit') }
      debit_index = row.index { |c| c.downcase.include?('debit') }
      description_index = row.index { |c| c.downcase.include?('text') || c.downcase.include?('description') }
      if [date_index, credit_index, debit_index, description_index].uniq.compact.length == 4
        return RowParser.new(date_index: date_index, credit_index: credit_index, debit_index: debit_index, description_index: description_index)
      end
    end
  end

  class RowParser
    DATE_FORMAT = '%d.%m.%Y'

    def initialize(date_index:, credit_index:, debit_index:, description_index:)
      @date_index = date_index
      @credit_index = credit_index
      @debit_index = debit_index
      @description_index = description_index
      @max_index = [date_index, credit_index, debit_index, description_index].max
    end
    
    def parse_optional_float(cell)
      Float(cell) if cell && !cell.empty? && cell != '-'
    end

    def parse(row)
      return if row.length <= @max_index
      date = begin
               Date.strptime(row[@date_index], DATE_FORMAT)
             rescue Date::Error
               return
             end
      description = row[@description_index]
      credit = parse_optional_float(row[@credit_index])
      debit = parse_optional_float(row[@debit_index])
      raise "#{row} has both credit and debit" if credit && debit
      raise "#{row} has no credit or debit" unless credit || debit
      amount = credit || -debit
      Transaction.new(amount: amount, description: description, time: date.to_time)
    end
  end

  def initialize
    @transactions = []
  end

  attr_reader :transactions

  def read(file)
    header_parser = HeaderParser.new
    row_parser = nil
    CSV.foreach(file) do |row|
      if row_parser
        transaction = row_parser.parse(row)
        @transactions.push(transaction) if transaction
      else
        row_parser = header_parser.parse(row)
      end
    end
  end
end
