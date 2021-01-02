class Transaction
  def initialize(time:, amount:, description:)
    @time = time
    @description = description
    @amount = amount
  end

  attr_reader :time, :amount, :description

  def eql?(other)
    identity == other.identity
  end

  alias :== eql?

  def hash
    identity.hash
  end

  def to_s
    "#{time.strftime('%F')}; #{amount} CHF; #{description}"
  end

  protected

  def identity
    [@time, @description, @amount]
  end
end
