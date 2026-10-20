def cut_cake(cake)
  # Перетворюємо рядок у двовимірний масив для зручності
  grid = cake.strip.split("\n").map(&:chars)
  h = grid.size
  w = grid[0].size

  # Рахуємо кількість родзинок
  raisins = cake.count('o')

  # Якщо родзинок немає, або площа не ділиться націло на кількість родзинок
  return [] if raisins == 0 || (h * w) % raisins != 0

  target_area = (h * w) / raisins
  used = Array.new(h) { Array.new(w, false) }

  # Запускаємо рекурсивний пошук
  solution = solve(grid, used, target_area, h, w)

  # Якщо рішення не знайдено
  return [] unless solution

  # Формуємо масив рядків (кожен рядок - це шматок торта, рядки з'єднані через \n)
  solution.map do |(r, c, ph, pw)|
    grid[r...(r + ph)].map { |row| row[c...(c + pw)].join }.join("\n")
  end
end

def solve(grid, used, target_area, h, w)
  # Знаходимо першу не зайняту клітинку
  start_r, start_c = -1, -1
  (0...h).each do |r|
    (0...w).each do |c|
      if !used[r][c]
        start_r, start_c = r, c
        break
      end
    end
    break if start_r != -1
  end

  # Якщо всі клітинки зайняті, ми успішно розрізали весь торт
  return [] if start_r == -1

  # Перебираємо всі можливі ширини шматка від найбільшої до найменшої 
  # (щоб задовольнити умову про найбільшу ширину першого елемента)
  w.downto(1) do |pw|
    # Ширина має бути дільником цільової площі
    next if target_area % pw != 0
    ph = target_area / pw

    # Перевіряємо, чи не виходить шматок за межі торта
    next if start_r + ph > h || start_c + pw > w

    valid = true
    raisins_in_piece = 0

    # Перевіряємо, чи всі клітинки у цьому шматку вільні і рахуємо родзинки
    (start_r...(start_r + ph)).each do |r|
      (start_c...(start_c + pw)).each do |c|
        if used[r][c]
          valid = false
          break
        end
        raisins_in_piece += 1 if grid[r][c] == 'o'
      end
      break unless valid
    end

    # Шматок підходить, якщо всі клітинки були вільні і всередині РІВНО 1 родзинка
    if valid && raisins_in_piece == 1
      # Позначаємо клітинки як зайняті
      (start_r...(start_r + ph)).each do |r|
        (start_c...(start_c + pw)).each do |c|
          used[r][c] = true
        end
      end

      # Рекурсивно намагаємося розрізати залишок торта
      rest_of_cake = solve(grid, used, target_area, h, w)

      # Якщо залишок вдалося розрізати, повертаємо успішний результат
      if rest_of_cake
        return [[start_r, start_c, ph, pw]] + rest_of_cake
      end

      # Якщо ні - скасовуємо зміни (бектрекінг) і пробуємо інші розміри
      (start_r...(start_r + ph)).each do |r|
        (start_c...(start_c + pw)).each do |c|
          used[r][c] = false
        end
      end
    end
  end

  # Якщо жоден розмір шматка не підійшов — рішення хибне, повертаємо nil
  nil
end

if __FILE__ == $PROGRAM_NAME
  begin
    print "Введіть висоту пирога: "
    height = Integer(STDIN.gets.to_s.strip)

    print "Введіть ширину пирога: "
    width = Integer(STDIN.gets.to_s.strip)

    puts "Введіть #{height} рядків пирога (крапка — порожня клітинка, o — родзинка):"
    rows = height.times.map do |index|
      row = STDIN.gets.to_s.chomp
      raise ArgumentError, "Рядок #{index + 1} має мати ширину #{width}" unless row.length == width

      row
    end

    pieces = cut_cake(rows.join("\n"))

    if pieces.empty?
      puts "Неможливо розрізати пиріг на прямокутні шматочки."
    else
      puts "\nРезультат:"
      pieces.each_with_index do |piece, index|
        puts "\nШматок #{index + 1}:"
        puts piece
      end
    end
  rescue ArgumentError => error
    warn "Помилка: #{error.message}"
  end
end
