require_relative 'errors'

module ExpenseTracker
  # Робота із сумами: зберігаємо копійки, показуємо гривні
  module Money
    module_function

    # 12550 => "125.50"
    def display(kopecks)
      '%d.%02d' % [kopecks / 100, kopecks % 100]
    end

    # Перевіряє, що введено додатне ціле число копійок
    def parse_kopecks(text)
      stripped = text.to_s.strip
      unless stripped.match?(/\A\d+\z/) && stripped.to_i.positive?
        raise InputError, 'Сума має бути додатним цілим числом копійок (наприклад, 12550 = 125.50 грн).'
      end

      stripped.to_i
    end
  end
end
