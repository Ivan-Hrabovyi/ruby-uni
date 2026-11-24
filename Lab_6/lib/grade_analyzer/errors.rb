module GradeAnalyzer
  # Базовий клас помилок застосунку
  class Error < StandardError
    # Рядки для показу користувачу
    def lines
      [message]
    end
  end

  # Некоректні дані: оцінка, ім'я, структура CSV
  class ValidationError < Error
    attr_reader :problems

    def initialize(problems)
      @problems = Array(problems)
      super(@problems.join('; '))
    end

    def lines
      problems
    end
  end

  # Некоректне введення користувача в меню
  class InputError < Error; end

  # Не вдалося прочитати або записати файл
  class StorageError < Error; end

  # Введення завершилось (Ctrl+D або кінець потоку)
  class EndOfInput < StandardError; end
end
