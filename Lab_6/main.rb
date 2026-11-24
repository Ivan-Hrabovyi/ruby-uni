#!/usr/bin/env ruby
# Запуск: ruby main.rb [шлях_до_файла.csv]

require_relative 'lib/grade_analyzer'

$stdout.sync = true
$stdin.set_encoding(Encoding::UTF_8)
$stdout.set_encoding(Encoding::UTF_8)

csv_path = ARGV.first || File.expand_path('grades.csv', __dir__)
report_path = File.expand_path('report.txt', __dir__)

begin
  storage = GradeAnalyzer::CsvStorage.new(csv_path)
  loaded = storage.load
rescue GradeAnalyzer::Error => e
  puts "Запуск неможливий: проблема з файлом #{csv_path}."
  e.lines.each { |line| puts "  - #{line}" }
  puts 'Файл не змінено. Виправте його і запустіть програму знову.'
  exit 1
end

puts loaded.notice if loaded.notice

begin
  gradebook = GradeAnalyzer::Gradebook.new(storage, loaded.grades)
  GradeAnalyzer::CLI.new(gradebook, report_path: report_path).run
rescue Interrupt
  puts "\nРоботу перервано."
end
