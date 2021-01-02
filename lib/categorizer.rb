class Categorizer
  class Category
    def initialize(name)
      @name = name
      @transactions = []
    end

    attr_reader :name, :transactions

    def total_amount
      @transactions.map(&:amount).sum
    end
  end

  def initialize(transactions)
    @transactions = transactions
    @all_categories = [Category.new('ignore')]
  end

  attr_reader :all_categories, :transactions

  def categories
    @all_categories[1..]
  end

  def categorize_all!
    until (transactions = uncategorized_transactions).empty?
      puts "#{transactions.length} transactions remaining"
      description = transactions.first.description
      transactions_group = transactions.select { |t| t.description == description }
      categorize_group!(transactions_group)
    end
  end

  def categorize_group!(transactions_group, regexp_allowed: true)
    choices = @all_categories.map { |c| CategoryChoice.new(c) } + (regexp_allowed ? [RegexpChoice.new(self)] : []) + [NewCategoryChoice.new(@all_categories)]
    puts "Please categorize the following transaction group:"
    puts transactions_group
    puts
    puts "Choices: "
    choices.each_with_index { |c, i| puts "#{i}: #{c}" }
    puts "Choice?"
    choice_index = choices.length
    until choice_index < choices.length
      choice_index = STDIN.gets.to_i
    end
    choices[choice_index].execute(transactions_group)
  end

  def uncategorized_transactions
    @transactions - @all_categories.collect_concat { |c| c.transactions }
  end
  
  private

  class CategoryChoice
    def initialize(category)
      @category = category
    end

    def to_s
      @category.name
    end

    def execute(transactions_group)
      transactions_group.each do |t|
        @category.transactions.push(t)
      end
    end
  end

  class NewCategoryChoice
    def initialize(categories)
      @categories = categories
    end

    def to_s
      'new category'
    end

    def execute(transactions_group)
      puts "New category name?"
      category = Category.new(STDIN.gets.chomp)
      @categories.push(category)
      CategoryChoice.new(category).execute(transactions_group)
    end
  end

  class RegexpChoice
    def initialize(categorizer)
      @categorizer = categorizer
    end

    def categories_with_regexp_matches(regexp)
      @categorizer.all_categories.select { |c| c.transactions.any? { |t| t.description.match?(regexp) } }
    end

    def good_regexp?(regexp_string, transactions_group)
      description = transactions_group.first.description
      regexp = begin
                 Regexp.new(regexp_string)
               rescue RegexpError
                 puts 'Invalid Regexp'
                 return false
               end
      unless description.match?(regexp)
        puts 'Regexp doesn\'t match description'
        return false
      end
      categories = categories_with_regexp_matches(regexp)
      if categories.length > 1
        puts "Multiple existing categories already have transactions that match this regexp: #{categories.map(&:name)}"
        return false
      end
      puts "Transactions that match this regexp:"
      puts @categorizer.transactions.select { |t| t.description.match?(regexp) }
      puts "Because category #{categories.first.name} already has transactions that match this regexp, these transactions have to be categorized to that category." unless categories.empty?
      puts
      puts "Accept this regexp? (y/n)"
      choice = nil
      until choice == 'y' || choice == 'n'
        choice = STDIN.gets.chomp
      end
      return choice == 'y'
    end

    def to_s
      'define regexp'
    end

    def execute(transactions_group)
      puts "Regexp?"
      regexp_string = nil
      until regexp_string && good_regexp?(regexp_string, transactions_group)
        regexp_string = STDIN.gets.chomp
      end
      regexp = Regexp.new(regexp_string)
      transactions_group = @categorizer.uncategorized_transactions.select { |t| t.description.match?(regexp) }
      categories = categories_with_regexp_matches(regexp)
      if !categories.empty?
        return CategoryChoice.new(categories.first).execute(transactions_group)
      else
        @categorizer.categorize_group!(transactions_group)
      end
    end
  end
end
