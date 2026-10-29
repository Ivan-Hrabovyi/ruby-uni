module Battleship
  # Корабель: займає кілька клітинок і знищується, коли влучили у всі
  class Ship
    attr_reader :size, :cells

    def initialize(size)
      @size = size
      @cells = []
      @hits = []
    end

    def place(cells)
      @cells = cells
    end

    def register_hit(coordinate)
      @hits << coordinate unless @hits.include?(coordinate)
    end

    def sunk?
      @hits.size == size
    end

    def name
      "#{size}-палубний корабель"
    end
  end
end
