require 'json'
require_relative 'errors'
require_relative 'expense'

module ExpenseTracker
  # Читання та запис JSON-файла з витратами
  class JsonStorage
    attr_reader :path

    def self.read_text(path)
      File.read(path, encoding: 'UTF-8')
    rescue Errno::ENOENT
      raise StorageError, "файл «#{path}» не знайдено"
    rescue SystemCallError, IOError => e
      raise StorageError, "не вдалося прочитати «#{path}» (#{e.message})"
    end

    # Розбирає текст JSON у список витрат. Порожній, пошкоджений або
    # некоректний вміст дає ValidationError з описом проблем.
    def self.parse(text)
      if text.strip.empty?
        raise ValidationError.new(['файл порожній (для порожнього списку збережіть [])'])
      end

      data = begin
        JSON.parse(text)
      rescue JSON::ParserError, EncodingError
        raise ValidationError.new(['файл пошкоджений: це не коректний JSON'])
      end
      raise ValidationError.new(['очікується JSON-масив записів, наприклад []']) unless data.is_a?(Array)

      expenses = []
      problems = []
      data.each_with_index do |attributes, index|
        expenses << Expense.build(attributes)
      rescue ValidationError => e
        e.lines.each { |line| problems << "запис №#{index + 1}: #{line}" }
      end

      duplicates = expenses.map(&:id).group_by(&:itself).select { |_id, list| list.size > 1 }.keys
      problems << "повторювані id: #{duplicates.join(', ')}" unless duplicates.empty?
      raise ValidationError.new(problems) unless problems.empty?

      expenses
    end

    def initialize(path)
      @path = path
    end

    # Для запуску: відсутній файл означає порожній список
    def load
      return [] unless File.exist?(path)

      self.class.parse(self.class.read_text(path))
    end

    # Записує через тимчасовий файл, щоб збій не зіпсував наявні дані
    def save(expenses)
      temp_path = "#{path}.tmp"
      File.write(temp_path, JSON.pretty_generate(expenses.map(&:to_h)) + "\n")
      File.rename(temp_path, path)
    rescue SystemCallError, IOError => e
      raise StorageError, "не вдалося записати «#{path}» (#{e.message})"
    end
  end
end
