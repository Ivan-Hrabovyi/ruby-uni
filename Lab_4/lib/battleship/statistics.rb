require 'json'

module Battleship
  # Статистика перемог і поразок. Зберігається в JSON-файл між запусками.
  class Statistics
    attr_reader :wins, :losses

    def initialize(file_path = nil)
      @file_path = file_path
      @wins = 0
      @losses = 0
      load_from_file
    end

    def record_win
      @wins += 1
      save_to_file
    end

    def record_loss
      @losses += 1
      save_to_file
    end

    def games_played
      wins + losses
    end

    def win_rate
      return 0.0 if games_played.zero?

      (wins * 100.0 / games_played).round(1)
    end

    def summary
      "Ігор зіграно: #{games_played}\nПеремог: #{wins}\nПоразок: #{losses}\nВідсоток перемог: #{win_rate}%"
    end

    private

    def load_from_file
      return unless @file_path && File.exist?(@file_path)

      data = JSON.parse(File.read(@file_path))
      @wins = data['wins'].to_i
      @losses = data['losses'].to_i
    rescue StandardError
      # Пошкоджений файл не повинен зупиняти гру
      @wins = 0
      @losses = 0
    end

    def save_to_file
      return unless @file_path

      File.write(@file_path, JSON.pretty_generate('wins' => wins, 'losses' => losses))
    rescue SystemCallError
      # Не вдалося записати — статистика залишається в пам'яті
      nil
    end
  end
end
