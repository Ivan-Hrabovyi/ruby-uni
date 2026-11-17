require_relative 'errors'
require_relative 'expense'
require_relative 'json_storage'

module ExpenseTracker
  # Результат імпорту: скільки записів додано і скільки з них отримали новий id
  ImportReport = Struct.new(:count, :renamed)

  # Колекція витрат у пам'яті. Кожна зміна спершу записується у файл.
  # Якщо запис не вдався, стан у пам'яті не змінюється.
  class Ledger
    attr_reader :expenses

    def initialize(storage, expenses = [])
      @storage = storage
      @expenses = expenses.dup
    end

    def add(attributes)
      expense = Expense.build(attributes.merge('id' => next_id))
      commit(@expenses + [expense])
      expense
    end

    def find(id)
      @expenses.find { |e| e.id == id }
    end

    def delete(id)
      expense = find(id)
      raise InputError, "Витрату з id #{id} не знайдено." if expense.nil?

      commit(@expenses.reject { |e| e.id == id })
      expense
    end

    # Імпорт є атомарним: якщо файл некоректний, нічого не додається
    def import(path)
      incoming = JsonStorage.parse(JsonStorage.read_text(path))
      return ImportReport.new(0, 0) if incoming.empty?

      existing_ids = @expenses.map(&:id)
      next_free_id = (existing_ids + incoming.map(&:id)).max
      renamed = 0

      records = incoming.map do |expense|
        next expense unless existing_ids.include?(expense.id)

        next_free_id += 1
        renamed += 1
        Expense.build(expense.to_h.merge('id' => next_free_id))
      end

      commit(@expenses + records)
      ImportReport.new(records.size, renamed)
    end

    private

    def next_id
      (@expenses.map(&:id).max || 0) + 1
    end

    def commit(new_expenses)
      @storage.save(new_expenses)
      @expenses = new_expenses
    rescue StorageError => e
      raise StorageError, "#{e.message}. Зміну не збережено, записи залишилися без змін"
    end
  end
end
