#умови
# Розрізання пирога з родзинками на прямокутні шматки.
# Кожен шматок — прямокутник з рівно однією родзинкою, усі шматки мають однакову площу.

RAISIN = "o"

# Демонстраційні приклади з умови (o — родзинка, . — порожня клітинка)
EXAMPLES = {
  "Приклад 1: два шматки" => [
    "........",
    "..o.....",
    "...o....",
    "........"
  ],
  "Приклад 2: горизонтальне різання (з трьох рішень обираємо перше)" => [
    ".o......",
    "......o.",
    "....o...",
    "..o....."
  ],
  "Приклад 3: шматки різної форми" => [
    ".o.o....",
    "........",
    "....o...",
    "........",
    ".....o..",
    "........"
  ],
  "Приклад 4: рішення немає (площа 4 не ділиться на 3 родзинки)" => [
    "o.",
    "oo"
  ]
}.freeze

# Головна функція. Повертає масив шматків (кожен шматок — масив рядків)
# або nil, якщо розрізати неможливо.
def cut_cake(rows)
  height = rows.size
  width = rows.first.size
  raise ArgumentError, "Усі рядки пирога мають бути однакової довжини" unless rows.all? { |r| r.size == width }

  raisins = rows.sum { |row| row.count(RAISIN) }
  raise ArgumentError, "Кількість родзинок має бути від 2 до 9, зараз: #{raisins}" unless (2..9).cover?(raisins)

  total_area = height * width
  return nil unless (total_area % raisins).zero?  # рівні шматки неможливі

  target_area = total_area / raisins
  used = Array.new(height) { Array.new(width, false) }

  placement = search(rows, used, target_area)
  return nil unless placement

  placement.map do |r, c, h, w|
    (r...r + h).map { |row| rows[row][c, w] }
  end
end

# Рекурсивний пошук з відкатом. Повертає список [рядок, стовпець, висота, ширина]
# або nil, якщо рішення немає.
def search(rows, used, target_area)
  free = first_free_cell(used)
  return [] unless free  # усі клітинки розрізані

  r0, c0 = free
  height, width = used.size, used.first.size

  # Перебираємо ширину від найбільшої до найменшої.
  # Перший шматок завжди починається з (0, 0), тому перше знайдене рішення
  # має найбільшу ширину першого елемента.
  width.downto(1) do |w|
    next unless (target_area % w).zero?

    h = target_area / w
    next if r0 + h > height || c0 + w > width
    next unless piece_valid?(rows, used, r0, c0, h, w)

    mark(used, r0, c0, h, w, true)
    rest = search(rows, used, target_area)
    return [[r0, c0, h, w]] + rest if rest

    mark(used, r0, c0, h, w, false)  # відкат
  end

  nil
end

# Перша вільна клітинка у порядку «рядок → стовпець»
def first_free_cell(used)
  used.each_with_index do |row, r|
    c = row.index(false)
    return [r, c] if c
  end
  nil
end

# Шматок валідний, якщо всі його клітинки вільні і в ньому рівно одна родзинка
def piece_valid?(rows, used, r0, c0, h, w)
  raisins = 0
  (r0...r0 + h).each do |r|
    (c0...c0 + w).each do |c|
      return false if used[r][c]
      raisins += 1 if rows[r][c] == RAISIN
    end
  end
  raisins == 1
end

def mark(used, r0, c0, h, w, value)
  (r0...r0 + h).each do |r|
    (c0...c0 + w).each { |c| used[r][c] = value }
  end
end

# Виводимо результат у форматі з умови
def print_result(pieces)
  puts "["
  pieces.each_with_index do |piece, i|
    piece.each { |line| puts "  #{line}" }
    puts "," if i < pieces.size - 1
  end
  puts "]"
end

def solve_and_print(rows)
  pieces = cut_cake(rows)
  if pieces.nil?
    puts "Неможливо розрізати пиріг на рівні прямокутні шматки з однією родзинкою."
  else
    print_result(pieces)
  end
rescue ArgumentError => e
  warn "Помилка: #{e.message}"
end

def run_demo
  EXAMPLES.each do |title, rows|
    puts "=== #{title} ==="
    solve_and_print(rows)
    puts
  end
end

# Режим введення з консолі: ruby cake.rb --input
def run_interactive
  puts "Введіть рядки пирога (. — порожня клітинка, o — родзинка), порожній рядок — кінець:"
  rows = []
  while (line = STDIN.gets) && !line.strip.empty?
    rows << line.strip
  end
  solve_and_print(rows)
end

if __FILE__ == $PROGRAM_NAME
  ARGV.include?("--input") ? run_interactive : run_demo
end