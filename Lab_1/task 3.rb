BEATS = {
  "камінь" => "ножиці",
  "ножиці" => "папір",
  "папір"  => "камінь"
}

stats = { player: 0, computer: 0, draw: 0, rounds: 0 }

loop do
  print "Камінь, ножиці, папір (або вихід): "
  player = gets.to_s.strip.downcase

  break if player == "вихід"

  unless BEATS.key?(player)
    puts "Некоректний вибір.\n\n"
    next
  end

  computer = BEATS.keys.sample
  puts "Вибір комп'ютера: #{computer.capitalize}"

  if player == computer
    result = :draw
    puts "Нічия!"
  elsif BEATS[player] == computer
    result = :player
    puts "Ви перемогли!"
  else
    result = :computer
    puts "Комп'ютер переміг!"
  end

  stats[result] += 1
  stats[:rounds] += 1

  puts "Ви: #{stats[:player]} | Комп'ютер: #{stats[:computer]} | Нічиї: #{stats[:draw]} | Раундів: #{stats[:rounds]}\n\n"
end