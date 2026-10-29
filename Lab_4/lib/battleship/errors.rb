module Battleship
  # Базовий клас помилок гри (власний клас помилки)
  class Error < StandardError; end

  # Некоректна координата: неправильний формат або поза полем
  class InvalidCoordinateError < Error
    HINT = 'Введіть літеру від A до J та число від 1 до 10, наприклад B7'

    def initialize(input = nil)
      message = input.nil? ? 'Координата поза полем.' : "Некоректна координата «#{input}»."
      super("#{message} #{HINT}.")
    end
  end

  # Повторний постріл в ту саму клітинку
  class RepeatedShotError < Error
    def initialize(coordinate)
      super("Ви вже стріляли в клітинку #{coordinate}. Оберіть іншу.")
    end
  end

  # Не вдалося розмістити корабель на полі
  class PlacementError < Error; end

  # Невідомий пункт меню
  class InvalidMenuChoiceError < Error
    def initialize(choice)
      super("Невідомий пункт меню: «#{choice}». Оберіть цифру від 1 до 4.")
    end
  end
end
