def play_game
  secret = rand(1..100)
  attempts = 0

  puts "Загадано число від 1 до 100. Спробуй вгадати!"

  loop do
    print "Твоє припущення: "
    input = gets.to_s.strip

    unless input.match?(/\A\d+\z/)
      puts "Введи ціле число."
      next
    end

    guess = input.to_i
    attempts += 1

    if guess < secret
      puts "Більше"
    elsif guess > secret
      puts "Менше"
    else
      puts "Вгадано! Спроб: #{attempts}"
      break
    end
  end
end

play_game