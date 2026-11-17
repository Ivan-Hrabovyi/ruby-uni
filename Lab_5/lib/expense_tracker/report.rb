require_relative 'expense'

module ExpenseTracker
  # Сортування, фільтрація та статистика (без побічних ефектів)
  module Report
    module_function

    # Сортування за датою, а для однакових дат — за id
    def sorted(expenses)
      expenses.sort_by { |e| [e.date, e.id] }
    end

    # Фільтр за категорією та періодом; обидві дати включаються
    def filter(expenses, category: nil, from: nil, to: nil)
      expenses.select do |e|
        (category.nil? || e.category == category) &&
          (from.nil? || e.date >= from) &&
          (to.nil? || e.date <= to)
      end
    end

    def total(expenses)
      expenses.sum(&:amount_in_kopecks)
    end

    def by_category(expenses)
      Expense::CATEGORIES.to_h do |category|
        [category, total(expenses.select { |e| e.category == category })]
      end
    end

    # Усі витрати з максимальною сумою (може бути кілька)
    def largest(expenses)
      return [] if expenses.empty?

      max_amount = expenses.map(&:amount_in_kopecks).max
      expenses.select { |e| e.amount_in_kopecks == max_amount }
    end
  end
end
