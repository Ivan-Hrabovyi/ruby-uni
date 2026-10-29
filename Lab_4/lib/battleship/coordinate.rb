require_relative 'errors'

module Battleship
  # Клітинка поля. Стовпці — літери A-J, рядки — числа 1-10.
  class Coordinate
    SIZE = 10
    LETTERS = ('A'..'J').to_a.freeze
    PATTERN = /\A([A-J])(10|[1-9])\z/i

    attr_reader :row, :col

    def self.in_bounds?(row, col)
      (0...SIZE).cover?(row) && (0...SIZE).cover?(col)
    end

    # Розбирає рядок на кшталт "B7" або "a10"
    def self.parse(input)
      text = input.to_s.strip
      match = PATTERN.match(text)
      raise InvalidCoordinateError.new(text) unless match

      new(Integer(match[2]) - 1, LETTERS.index(match[1].upcase))
    end

    def self.all
      Array.new(SIZE) { |r| Array.new(SIZE) { |c| new(r, c) } }.flat_map { |row| row }
    end

    def initialize(row, col)
      raise InvalidCoordinateError unless self.class.in_bounds?(row, col)

      @row = row
      @col = col
    end

    def to_s
      "#{LETTERS[col]}#{row + 1}"
    end

    def ==(other)
      other.is_a?(Coordinate) && row == other.row && col == other.col
    end
    alias eql? ==

    def hash
      [row, col].hash
    end

    # Сама клітинка та всі сусідні, включно з діагоналями
    def surrounding
      (-1..1).flat_map do |dr|
        (-1..1).filter_map do |dc|
          self.class.new(row + dr, col + dc) if self.class.in_bounds?(row + dr, col + dc)
        end
      end
    end

    # Сусіди лише по горизонталі та вертикалі
    def orthogonal_neighbors
      [[-1, 0], [1, 0], [0, -1], [0, 1]].filter_map do |dr, dc|
        self.class.new(row + dr, col + dc) if self.class.in_bounds?(row + dr, col + dc)
      end
    end
  end
end
