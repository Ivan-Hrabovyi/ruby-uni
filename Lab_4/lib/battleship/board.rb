require_relative 'coordinate'
require_relative 'ship'
require_relative 'errors'

module Battleship
  # Результат пострілу: :miss, :hit або :sunk, та корабель (якщо він був)
  ShotResult = Struct.new(:outcome, :ship)

  # Ігрове поле 10x10 із кораблями та історією пострілів
  class Board
    # Флот: розмір корабля => кількість
    FLEET = { 4 => 1, 3 => 2, 2 => 3, 1 => 4 }.freeze
    MAX_ATTEMPTS = 500

    attr_reader :ships

    # Створює поле з випадково розставленим флотом
    def self.random(rng = Random.new)
      loop do
        board = new
        begin
          board.place_fleet_randomly(rng)
          return board
        rescue PlacementError
          # Невдала розстановка — генеруємо поле заново
          next
        end
      end
    end

    def initialize
      @ships = []
      @occupied = {}  # Coordinate => Ship
      @shots = {}     # Coordinate => :hit / :miss
    end

    def place_fleet_randomly(rng = Random.new)
      FLEET.each do |size, count|
        count.times { place_ship_randomly(size, rng) }
      end
    end

    def receive_shot(coordinate)
      raise RepeatedShotError.new(coordinate) if @shots.key?(coordinate)

      ship = @occupied[coordinate]
      if ship
        ship.register_hit(coordinate)
        @shots[coordinate] = :hit
        ShotResult.new(ship.sunk? ? :sunk : :hit, ship)
      else
        @shots[coordinate] = :miss
        ShotResult.new(:miss, nil)
      end
    end

    def all_sunk?
      ships.all?(&:sunk?)
    end

    # Повертає рядки для виводу. reveal_ships — показати кораблі (для власного поля)
    def render(reveal_ships: false)
      lines = ['   ' + Coordinate::LETTERS.join(' ')]
      Coordinate::SIZE.times do |row|
        cells = Coordinate::SIZE.times.map do |col|
          symbol_at(Coordinate.new(row, col), reveal_ships)
        end
        lines << format('%2d %s', row + 1, cells.join(' '))
      end
      lines
    end

    private

    def place_ship_randomly(size, rng)
      MAX_ATTEMPTS.times do
        cells = random_cells(size, rng)
        next unless cells && cells.none? { |c| blocked?(c) }

        add_ship(size, cells)
        return
      end
      raise PlacementError, "Не вдалося розмістити корабель розміром #{size}"
    end

    def random_cells(size, rng)
      horizontal = rng.rand(2).zero?
      row = rng.rand(Coordinate::SIZE)
      col = rng.rand(Coordinate::SIZE)
      points = Array.new(size) { |i| horizontal ? [row, col + i] : [row + i, col] }
      return nil unless points.all? { |r, c| Coordinate.in_bounds?(r, c) }

      points.map { |r, c| Coordinate.new(r, c) }
    end

    # Клітинка зайнята або стикається з кораблем (включно з діагоналями)
    def blocked?(coordinate)
      coordinate.surrounding.any? { |c| @occupied.key?(c) }
    end

    def add_ship(size, cells)
      ship = Ship.new(size)
      ship.place(cells)
      cells.each { |c| @occupied[c] = ship }
      @ships << ship
    end

    def symbol_at(coordinate, reveal_ships)
      case @shots[coordinate]
      when :hit then 'X'
      when :miss then '.'
      else
        reveal_ships && @occupied.key?(coordinate) ? '#' : '~'
      end
    end
  end
end
