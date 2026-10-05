def word_stats(text)
  words = text.split
  word_count = words.count
  unique_count = words.uniq.count
  longest = words.max_by(&:length)

  puts "#{word_count} слів, найдовше: #{longest}, унікальних: #{unique_count}"
end

puts "enter text"
text = gets.chomp

word_stats(text)