require_relative 'money'

module ExpenseTracker
  # Таблиця витрат для консолі
  module Table
    HEADERS = ['ID', 'Дата', 'Категорія', 'Сума, грн', 'Опис'].freeze
    AMOUNT_COLUMN = 3

    module_function

    def render(expenses)
      rows = expenses.map do |e|
        [e.id.to_s, e.date.to_s, e.category, Money.display(e.amount_in_kopecks), e.description]
      end
      widths = HEADERS.each_index.map do |i|
        ([HEADERS[i]] + rows.map { |row| row[i] }).map(&:length).max
      end
      separator = widths.map { |w| '-' * w }.join('  ')

      [format_row(HEADERS, widths), separator, *rows.map { |row| format_row(row, widths) }]
    end

    def format_row(cells, widths)
      cells.each_with_index.map do |cell, i|
        i == AMOUNT_COLUMN ? cell.rjust(widths[i]) : cell.ljust(widths[i])
      end.join('  ').rstrip
    end
  end
end
