require_relative 'errors'
require_relative 'statistics'
require_relative 'game'

module Battleship
  # Головне меню: нова гра, правила, статистика, вихід
  class Menu
    RULES = <<~TEXT.freeze
      ПРАВИЛА ГРИ «МОРСЬКИЙ БІЙ»

      • Поле 10×10: стовпці — літери A–J, рядки — числа 1–10.
      • Флот: один 4-палубний, два 3-палубних, три 2-палубних і чотири 1-палубних корабля.
      • Кораблі не можуть перетинатися або торкатися одне одного, навіть по діагоналі.
      • Ви і комп'ютер по черзі стріляєте, вказуючи координату, наприклад B7.
      • Позначки: ~ — невідома клітинка, . — промах, X — влучання, # — ваш корабель.
      • Після кожного пострілу гра повідомляє про промах, влучання або знищення корабля.
      • Перемагає той, хто першим знищить усі кораблі суперника.
      • Стріляти в одну клітинку двічі не можна — програма попередить про це.
      • Введіть q під час гри, щоб вийти в меню (результат не зараховується).
    TEXT

    def initialize(statistics:, input: $stdin, output: $stdout, rng: Random.new)
      @statistics = statistics
      @input = input
      @output = output
      @rng = rng
    end

    def run
      loop do
        show_main_menu
        choice = ask('Ваш вибір: ')
        break if choice.nil?

        begin
          break if handle(choice.strip) == :exit
        rescue Error => e
          say "Помилка: #{e.message}"
        rescue StandardError => e
          # Страхувальна сітка: жодна помилка не має зупиняти програму
          say "Несподівана помилка: #{e.message}"
        end
      end
      say 'До зустрічі!'
    end

    private

    def handle(choice)
      case choice
      when '1' then play_game
      when '2' then show_rules
      when '3' then show_statistics
      when '4', 'q', 'Q' then return :exit
      else raise InvalidMenuChoiceError.new(choice)
      end
      nil
    end

    def play_game
      result = Game.new(statistics: @statistics, input: @input, output: @output, rng: @rng).play
      if result == Game::ABORTED
        say 'Гру перервано. Результат не зараховано.'
      else
        say "\n#{@statistics.summary}"
      end
      ask('Натисніть Enter, щоб повернутися до меню...')
    end

    def show_rules
      say RULES
      ask('Натисніть Enter, щоб повернутися до меню...')
    end

    def show_statistics
      say "\n#{@statistics.summary}"
      ask('Натисніть Enter, щоб повернутися до меню...')
    end

    def show_main_menu
      say "\n=== МОРСЬКИЙ БІЙ ==="
      say '1. Нова гра'
      say '2. Правила'
      say '3. Статистика'
      say '4. Вихід'
    end

    def say(text)
      @output.puts(text)
    end

    def ask(prompt)
      @output.print(prompt)
      @output.flush
      @input.gets
    end
  end
end
