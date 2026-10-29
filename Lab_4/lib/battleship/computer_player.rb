require_relative 'coordinate'
require_relative 'errors'

module Battleship
  # Комп'ютерний суперник: стріляє у випадкові клітинки без повторів.
  # Після влучання перевіряє сусідні клітинки (режим "добивання").
  class ComputerPlayer
    def initialize(rng = Random.new)
      @pool = Coordinate.all.shuffle(random: rng)
      @fired = {}
      @targets = []
    end

    def next_shot
      coordinate = next_target || next_random
      @fired[coordinate] = true
      coordinate
    end

    # Отримує результат власного пострілу, щоб вибрати наступні цілі
    def report(coordinate, outcome)
      return unless outcome == :hit

      coordinate.orthogonal_neighbors.each do |neighbor|
        @targets << neighbor unless @fired.key?(neighbor)
      end
    end

    private

    def next_target
      @targets.shift while @targets.any? && @fired.key?(@targets.first)
      @targets.shift
    end

    def next_random
      loop do
        coordinate = @pool.shift
        raise Error, "Комп'ютер більше не має ходів" if coordinate.nil?
        return coordinate unless @fired.key?(coordinate)
      end
    end
  end
end
