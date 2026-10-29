require_relative 'board'
require_relative 'computer_player'
require_relative 'coordinate'
require_relative 'errors'

module Battleship
  # Одна партія: гравець проти комп'ютера
  class Game
    ABORTED = :aborted

    def initialize(statistics:, input: $stdin, output: $stdout, rng: Random.new)
      @statistics = statistics
      @input = input
      @output = output
      @rng = rng
    end

    # Повертає :win, :loss або :aborted (гравець вийшов у меню)
    def play
      setup
      say 'Гра розпочалась! Ви стріляєте першим.'
      say "Координати: літера A-J (стовпець) і число 1-10 (рядок), наприклад B7. Введіть 'q', щоб вийти в меню."

      loop do
        show_boards
        return ABORTED if player_turn == ABORTED
        return finish(:win) if @computer_board.all_sunk?

        computer_turn
        return finish(:loss) if @player_board.all_sunk?
      end
    end

    private

    def setup
      @player_board = Board.random(@rng)
      @computer_board = Board.random(@rng)
      @ai = ComputerPlayer.new(@rng)
    end

    # Повертає :shot або ABORTED. Некоректне введення не перериває гру.
    def player_turn
      loop do
        raw = ask('Ваш постріл: ')
        return ABORTED if raw.nil? || raw.strip.casecmp?('q')

        begin
          coordinate = Coordinate.parse(raw)
          result = @computer_board.receive_shot(coordinate)
          say "#{coordinate}: #{describe(result)}"
          return :shot
        rescue InvalidCoordinateError, RepeatedShotError => e
          say "Помилка: #{e.message}"
        end
      end
    end

    def computer_turn
      coordinate = @ai.next_shot
      result = @player_board.receive_shot(coordinate)
      @ai.report(coordinate, result.outcome)
      say "Комп'ютер стріляє в #{coordinate}: #{describe(result)}"
    end

    def describe(result)
      case result.outcome
      when :miss then 'Промах.'
      when :hit then 'Влучання!'
      when :sunk then "Корабель знищено (#{result.ship.name})!"
      end
    end

    def finish(outcome)
      say "\nПоле суперника:"
      @output.puts @computer_board.render(reveal_ships: true)

      if outcome == :win
        @statistics.record_win
        say 'Перемога! Ви знищили весь флот суперника.'
      else
        @statistics.record_loss
        say "Поразка. Комп'ютер знищив ваш флот."
      end
      outcome
    end

    def show_boards
      say "\nПоле суперника (ваші постріли):"
      @output.puts @computer_board.render
      say "\nВаше поле:"
      @output.puts @player_board.render(reveal_ships: true)
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
