#!/usr/bin/env ruby
# Точка входу: запуск гри «Морський бій»

require_relative 'lib/battleship'

stats_file = File.expand_path('battleship_stats.json', __dir__)
$stdout.sync = true

begin
  statistics = Battleship::Statistics.new(stats_file)
  Battleship::Menu.new(statistics: statistics).run
rescue Interrupt
  puts "\nГру перервано. До зустрічі!"
end
