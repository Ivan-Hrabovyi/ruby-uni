require_relative 'errors'
require_relative 'expense'
require_relative 'money'
require_relative 'report'
require_relative 'table'

module ExpenseTracker
  # Консольне меню. Будь-яка помилка показується, і користувач повертається до меню.
  class CLI
    MENU = <<~TEXT.freeze
      ===== ExpenseTracker =====
      1. Додати витрату
      2. Переглянути всі витрати
      3. Фільтрувати витрати (категорія / період)
      4. Видалити витрату
      5. Статистика
      6. Імпортувати витрати з JSON
      0. Завершити роботу
    TEXT

    CONFIRMATIONS = %w[так т yes y].freeze

    def initialize(ledger, input: $stdin, output: $stdout)
      @ledger = ledger
      @input = input
      @output = output
    end

    def run
      loop do
        say "\n#{MENU}"
        command = ask('Оберіть дію: ')
        break if command == '0'

        begin
          dispatch(command)
        rescue Error => e
          show_error(e)
        rescue EndOfInput
          raise
        rescue StandardError => e
          say "Несподівана помилка: #{e.message}"
        end
      end
      say 'Роботу завершено. До побачення!'
    rescue EndOfInput
      say "\nВведення завершено. Роботу завершено."
    end

    private

    def dispatch(command)
      case command
      when '1' then add_expense
      when '2' then list_expenses
      when '3' then filter_expenses
      when '4' then delete_expense
      when '5' then show_statistics
      when '6' then import_expenses
      else raise InputError, "Невідома команда «#{command}». Оберіть номер від 0 до 6."
      end
    end

    def add_expense
      attributes = {
        'date' => ask('Дата (YYYY-MM-DD): '),
        'amount_in_kopecks' => Money.parse_kopecks(ask('Сума в копійках (12550 = 125.50 грн): ')),
        'category' => ask_category,
        'description' => ask('Опис: ')
      }
      expense = @ledger.add(attributes)
      say "Витрату додано (id #{expense.id}): #{Money.display(expense.amount_in_kopecks)} грн."
    end

    def ask_category
      say "Категорії: #{Expense::CATEGORIES.join(', ')}"
      ask('Категорія: ').downcase
    end

    def list_expenses
      show_expenses(@ledger.expenses, empty_message: 'Витрат ще немає.')
    end

    def filter_expenses
      category = ask_optional('Категорія (Enter — усі): ')&.downcase
      if category && !Expense::CATEGORIES.include?(category)
        raise InputError, "Невідома категорія «#{category}». Допустимі: #{Expense::CATEGORIES.join(', ')}."
      end

      from, to = ask_period(optional: true)
      matches = Report.filter(@ledger.expenses, category: category, from: from, to: to)
      show_expenses(matches, empty_message: 'За заданими умовами витрат не знайдено. Сума: 0.00 грн.')
    end

    def delete_expense
      id = parse_id(ask('ID витрати, яку видалити: '))
      expense = @ledger.find(id)
      raise InputError, "Витрату з id #{id} не знайдено." if expense.nil?

      say "Знайдено: #{expense.date}, #{expense.category}, #{Money.display(expense.amount_in_kopecks)} грн, «#{expense.description}»"
      answer = ask('Видалити цю витрату? (так/ні): ').downcase
      if CONFIRMATIONS.include?(answer)
        @ledger.delete(id)
        say 'Витрату видалено.'
      else
        say 'Видалення скасовано.'
      end
    end

    def show_statistics
      expenses = @ledger.expenses
      if expenses.empty?
        say 'Витрат ще немає. Загальна сума: 0.00 грн.'
      else
        show_general_statistics(expenses)
      end

      from, to = ask_period(optional: false)
      period = Report.filter(expenses, from: from, to: to)
      say "\nЗа період #{from} – #{to}:"
      if period.empty?
        say 'Витрат за цей період немає. Сума: 0.00 грн.'
      else
        say "Сума: #{Money.display(Report.total(period))} грн (записів: #{period.size})"
      end
    end

    def show_general_statistics(expenses)
      say "Загальна сума: #{Money.display(Report.total(expenses))} грн (записів: #{expenses.size})"

      say 'Суми за категоріями:'
      Report.by_category(expenses).each do |category, kopecks|
        say "  #{category.ljust(14)} #{Money.display(kopecks).rjust(10)} грн"
      end

      largest = Report.largest(expenses)
      if largest.size == 1
        say 'Найбільша витрата:'
      else
        say "Найбільші витрати (однакова сума #{Money.display(largest.first.amount_in_kopecks)} грн):"
      end
      say Table.render(Report.sorted(largest))
    end

    def import_expenses
      path = ask('Шлях до JSON-файла з витратами: ')
      raise InputError, 'Шлях до файла не може бути порожнім.' if path.empty?

      report = @ledger.import(path)
      if report.count.zero?
        say 'Файл не містить записів. Нічого не імпортовано.'
        return
      end

      say "Імпортовано записів: #{report.count}."
      say "Для #{report.renamed} записів id змінено, бо такі вже існували." if report.renamed.positive?
    end

    def show_expenses(expenses, empty_message:)
      if expenses.empty?
        say empty_message
        return
      end

      say Table.render(Report.sorted(expenses))
      say "Разом: #{Money.display(Report.total(expenses))} грн (записів: #{expenses.size})"
    end

    # Початкова дата не пізніша за кінцеву; для optional порожній ввід означає "без обмеження"
    def ask_period(optional:)
      from = ask_date('Початкова дата (YYYY-MM-DD)', optional: optional)
      to = ask_date('Кінцева дата (YYYY-MM-DD)', optional: optional)
      raise InputError, 'Початкова дата не може бути пізнішою за кінцеву.' if from && to && from > to

      [from, to]
    end

    def ask_date(label, optional:)
      hint = optional ? ' (Enter — без обмеження)' : ''
      text = ask("#{label}#{hint}: ")
      return nil if optional && text.empty?

      Expense.parse_date(text) ||
        raise(InputError, "«#{text}» не є коректною датою у форматі YYYY-MM-DD.")
    end

    def parse_id(text)
      unless text.match?(/\A\d+\z/) && text.to_i.positive?
        raise InputError, 'ID має бути додатним цілим числом.'
      end

      text.to_i
    end

    def ask_optional(prompt)
      text = ask(prompt)
      text.empty? ? nil : text
    end

    def show_error(error)
      error.lines.each_with_index do |line, index|
        say index.zero? ? "Помилка: #{line}" : "  - #{line}"
      end
    end

    def ask(prompt)
      @output.print(prompt)
      @output.flush
      line = @input.gets
      raise EndOfInput if line.nil?

      text = line.dup.force_encoding(Encoding::UTF_8)
      raise InputError, 'Введення має бути у кодуванні UTF-8.' unless text.valid_encoding?

      text.strip
    end

    def say(text)
      @output.puts(text)
    end
  end
end
