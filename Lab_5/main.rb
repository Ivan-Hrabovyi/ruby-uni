#!/usr/bin/env ruby
# Запуск: ruby main.rb [шлях_до_файла.json]

require_relative 'lib/expense_tracker'

$stdout.sync = true
# Незалежно від локалі системи: введення і вивід у UTF-8 (кирилиця)
$stdin.set_encoding(Encoding::UTF_8)
$stdout.set_encoding(Encoding::UTF_8)
path = ARGV.first || File.expand_path('expenses.json', __dir__)

begin
  storage = ExpenseTracker::JsonStorage.new(path)
  expenses = storage.load
rescue ExpenseTracker::Error => e
  puts "Запуск неможливий: проблема з файлом #{path}."
  e.lines.each { |line| puts "  - #{line}" }
  puts 'Файл не змінено. Виправте його або видаліть і запустіть програму знову.'
  exit 1
end

begin
  ExpenseTracker::CLI.new(ExpenseTracker::Ledger.new(storage, expenses)).run
rescue Interrupt
  puts "\nРоботу перервано. Записи, які вже збережено, не змінено."
end
